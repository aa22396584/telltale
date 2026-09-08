#!/usr/bin/env python3
"""#47: check_arb.py fails closed on missing keys, empty values, and placeholders."""
from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT))

import check_arb  # noqa: E402


def _write(directory: Path, name: str, payload: dict) -> Path:
    path = directory / name
    path.write_text(json.dumps(payload, ensure_ascii=False), encoding="utf-8")
    return path


class CheckArbTest(unittest.TestCase):
    def test_matching_locales_pass(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            en = _write(
                tmp,
                "app_en.arb",
                {
                    "@@locale": "en",
                    "hello": "Hello",
                    "@hello": {"placeholders": {}},
                    "count": "{n} items",
                    "@count": {"placeholders": {"n": {"type": "int"}}},
                },
            )
            zh = _write(
                tmp,
                "app_zh.arb",
                {
                    "@@locale": "zh",
                    "hello": "你好",
                    "@hello": {"placeholders": {}},
                    "count": "{n} 項",
                    "@count": {"placeholders": {"n": {"type": "int"}}},
                },
            )
            errors = check_arb.check_files([en, zh])
            self.assertEqual(errors, [])

    def test_missing_key_fails(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            en = _write(tmp, "app_en.arb", {"hello": "Hello", "bye": "Bye"})
            zh = _write(tmp, "app_zh.arb", {"hello": "你好"})
            errors = check_arb.check_files([en, zh])
            self.assertTrue(any("missing key" in e and "bye" in e for e in errors))

    def test_empty_value_fails(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            en = _write(tmp, "app_en.arb", {"hello": "Hello"})
            zh = _write(tmp, "app_zh.arb", {"hello": "   "})
            errors = check_arb.check_files([en, zh])
            self.assertTrue(any("empty" in e and "hello" in e for e in errors))

    def test_placeholder_name_mismatch_fails(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            en = _write(
                tmp,
                "app_en.arb",
                {
                    "count": "{n} items",
                    "@count": {"placeholders": {"n": {"type": "int"}}},
                },
            )
            zh = _write(
                tmp,
                "app_zh.arb",
                {
                    "count": "{count} 項",
                    "@count": {"placeholders": {"count": {"type": "int"}}},
                },
            )
            errors = check_arb.check_files([en, zh])
            self.assertTrue(any("placeholder" in e and "count" in e for e in errors))

    def test_placeholder_type_mismatch_fails(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            en = _write(
                tmp,
                "app_en.arb",
                {
                    "count": "{n} items",
                    "@count": {"placeholders": {"n": {"type": "int"}}},
                },
            )
            zh = _write(
                tmp,
                "app_zh.arb",
                {
                    "count": "{n} 項",
                    "@count": {"placeholders": {"n": {"type": "String"}}},
                },
            )
            errors = check_arb.check_files([en, zh])
            self.assertTrue(any("placeholder type" in e for e in errors))

    def test_duplicate_json_key_fails(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            path = tmp / "app_en.arb"
            path.write_text('{"hello":"A","hello":"B"}\n', encoding="utf-8")
            zh = _write(tmp, "app_zh.arb", {"hello": "你好"})
            errors = check_arb.check_files([path, zh])
            self.assertTrue(any("duplicate JSON key" in e for e in errors))

    def test_malformed_json_fails(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            path = tmp / "app_en.arb"
            path.write_text("{not json", encoding="utf-8")
            zh = _write(tmp, "app_zh.arb", {"hello": "你好"})
            errors = check_arb.check_files([path, zh])
            self.assertTrue(any("malformed JSON" in e for e in errors))

    def test_nonstandard_json_number_fails(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            path = tmp / "app_en.arb"
            path.write_text(
                '{"hello":"Hello","@hello":{"description":NaN}}\n',
                encoding="utf-8",
            )
            zh = _write(tmp, "app_zh.arb", {"hello": "你好"})
            errors = check_arb.check_files([path, zh])
            self.assertTrue(any("malformed JSON" in e for e in errors), errors)

    def test_template_with_no_messages_fails(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            en = _write(tmp, "app_en.arb", {"@@locale": "en"})
            zh = _write(tmp, "app_zh.arb", {"@@locale": "zh"})
            errors = check_arb.check_files([en, zh])
            self.assertTrue(
                any("contains no messages" in e for e in errors),
                errors,
            )

    def test_omitted_translation_metadata_inherits_template(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            en = _write(
                tmp,
                "app_en.arb",
                {
                    "count": "{n} items",
                    "@count": {"placeholders": {"n": {"type": "int"}}},
                },
            )
            zh = _write(tmp, "app_zh.arb", {"count": "{n} 項"})
            self.assertEqual(check_arb.check_files([en, zh]), [])

    def test_plural_branch_text_is_not_a_placeholder_name(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            payload = {
                "count": "{count, plural, =0{No items} other{{count} items}}",
                "@count": {"placeholders": {"count": {"type": "int"}}},
            }
            en = _write(tmp, "app_en.arb", payload)
            zh = _write(
                tmp,
                "app_zh.arb",
                {
                    "count": "{count, plural, =0{沒有項目} other{{count} 項}}",
                },
            )
            self.assertEqual(check_arb.check_files([en, zh]), [])

    def test_template_text_must_match_template_metadata(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            en = _write(
                tmp,
                "app_en.arb",
                {
                    "count": "{count} items",
                    "@count": {"placeholders": {"n": {"type": "int"}}},
                },
            )
            zh = _write(tmp, "app_zh.arb", {"count": "{n} 項"})
            errors = check_arb.check_files([en, zh])
            self.assertTrue(
                any("text" in e and "metadata" in e for e in errors),
                errors,
            )

    def test_omitted_metadata_still_catches_icu_drift(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            en = _write(
                tmp,
                "app_en.arb",
                {
                    "count": "{n} items",
                    "@count": {"placeholders": {"n": {"type": "int"}}},
                },
            )
            zh = _write(tmp, "app_zh.arb", {"count": "{count} 項"})
            errors = check_arb.check_files([en, zh])
            self.assertTrue(any("placeholder names" in e and "count" in e for e in errors))

    def test_one_word_plural_branch_is_not_a_placeholder(self) -> None:
        self.assertEqual(
            check_arb._icu_names("{count, plural, one{item} other{items}}"),
            {"count"},
        )
        self.assertEqual(
            check_arb._icu_names(
                "{gender, select, male{he} female{she} other{they}}"
            ),
            {"gender"},
        )
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            payload = {
                "count": "{count, plural, one{item} other{items}}",
                "@count": {"placeholders": {"count": {"type": "int"}}},
            }
            en = _write(tmp, "app_en.arb", payload)
            zh = _write(
                tmp,
                "app_zh.arb",
                {"count": "{count, plural, one{項} other{項}}"},
            )
            self.assertEqual(check_arb.check_files([en, zh]), [])

    def test_empty_template_metadata_must_still_match_text(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            en = _write(
                tmp,
                "app_en.arb",
                {
                    "count": "{count} items",
                    "@count": {"placeholders": {}},
                },
            )
            zh = _write(tmp, "app_zh.arb", {"count": "{count} 項"})
            errors = check_arb.check_files([en, zh])
            self.assertTrue(
                any("text" in e and "metadata" in e for e in errors),
                errors,
            )

    def test_plain_template_text_with_placeholder_metadata_fails(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            en = _write(
                tmp,
                "app_en.arb",
                {
                    "count": "items",
                    "@count": {"placeholders": {"count": {"type": "int"}}},
                },
            )
            zh = _write(tmp, "app_zh.arb", {"count": "{count}"})
            errors = check_arb.check_files([en, zh])
            self.assertTrue(
                any("text" in e and "metadata" in e for e in errors),
                errors,
            )

    def test_main_returns_nonzero_on_failure(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            en = _write(tmp, "app_en.arb", {"hello": "Hello"})
            zh = _write(tmp, "app_zh.arb", {})
            code = check_arb.main([str(en), str(zh)])
            self.assertNotEqual(code, 0)


if __name__ == "__main__":
    unittest.main()
