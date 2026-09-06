# Localization working documents

Telltale ships two languages, English and Traditional Chinese, and nothing else.
Simplified Chinese is deliberately not shipped; `lib/l10n/locale_resolution.dart` says so
in code, and `zh-Hans` must never be dressed up as 繁體中文.

These four files are the contract a translation is reviewed against. They are written in
English because they are read while editing English ARB entries, and because the terms
they define appear in both languages side by side.

| Document | What it settles |
|---|---|
| [glossary.md](glossary.md) | 145 term pairs, each with the file that already established it |
| [do-not-translate.md](do-not-translate.md) | 227 tokens that must stay byte-identical, and why the line falls where it does |
| [hedge-register.md](hedge-register.md) | 26 sentences whose qualifiers are load-bearing |
| [string-inventory.md](string-inventory.md) | per-string migration state (added by the extraction waves) |

## The rule these exist to enforce

> A plausible wrong number is worse than no number.

The same holds for prose. A fluent English sentence that quietly drops "not certification",
"observed", "estimated" or "partial" is not a good translation with a small flaw in it — it
is a false claim about a vehicle, published under this project's name. Fluency is not the
acceptance criterion; preserved force is.

## What is checked automatically

`test/l10n/glossary_evidence_test.dart` parses `glossary.md` and fails when a cited file no
longer contains the Chinese term it cites. A glossary nobody verifies becomes folklore
within one refactor.

`test/l10n/arb_parity_test.dart` fails when the ARB files disagree on which messages exist,
on placeholders, or when `app_zh.arb` drifts from `app_zh_Hant.arb`.

Neither can tell you a translation is *good*. They can only tell you it is *present and
structurally intact*, which is the part a machine can honestly judge.
