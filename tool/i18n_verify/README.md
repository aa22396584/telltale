# i18n verify (#47)

`check_arb.py` compares ARB locales without Flutter. A missing English or
Traditional Chinese key is a failure; `gen-l10n` English fallback is not a
pass.

```bash
python3 tool/i18n_verify/check_arb.py lib/l10n/app_en.arb lib/l10n/app_zh.arb lib/l10n/app_zh_Hant.arb
python3 -m unittest discover -s tool/i18n_verify -p 'test_*.py'
```

Tests use fixture copies. They do not rewrite the shipped ARB files.
