# Localization working documents

Telltale ships two languages, English and Traditional Chinese, and nothing else.
Simplified Chinese is deliberately not shipped; `lib/l10n/locale_resolution.dart` says so
in code, and `zh-Hans` must never be dressed up as 繁體中文.

These three documents and this index are the contract a translation is reviewed against. They are written in
English because they are read while editing English ARB entries, and because the terms
they define appear in both languages side by side.

| Document | What it settles |
|---|---|
| [glossary.md](glossary.md) | 145 term pairs, each with the file that already established it |
| [do-not-translate.md](do-not-translate.md) | 227 tokens that must stay byte-identical, and why the line falls where it does |
| [hedge-register.md](hedge-register.md) | 26 sentences whose qualifiers are load-bearing |

## The rule these exist to enforce

> A plausible wrong number is worse than no number.

The same holds for prose. A fluent English sentence that quietly drops "not certification",
"observed", "estimated" or "partial" is not a good translation with a small flaw in it — it
is a false claim about a vehicle, published under this project's name. Fluency is not the
acceptance criterion; preserved force is.

## What is checked automatically

`test/l10n/glossary_evidence_test.dart` parses `glossary.md` and fails when a cited term is
no longer within a few lines of the place the glossary says it is. A glossary nobody
verifies becomes folklore within one refactor.

Seven guards: every table row parses (a row count, not a lower bound, so a section cannot
change shape and vanish); every row cites a file that exists **with a line number**; the
Chinese term is at that line; the English term is at that line; an `evidenced` pairing was
actually written down together — in one file, or in the two language versions of one
document; no Chinese term carries two English forms; and the glossary never translates a
token the do-not-translate list says to leave alone.

The line numbers are the part that makes it bite. An earlier version discarded them and
compared whole files, which passed for any two words that happened to appear in two large
documents.

**What it cannot tell you** is whether a translation is *good*. It answers one question a
machine can answer honestly: is the evidence still where the glossary says it is? Force,
tone and preserved hedging are a human's job, which is what
[hedge-register.md](hedge-register.md) exists to make reviewable.

It also does not check the ARB files. Nothing in this branch does.
