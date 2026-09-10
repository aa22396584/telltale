# Localization working documents

Telltale ships three languages, and they do not all carry the same claim. English is the
template. Traditional Chinese is a human translation, reviewed against the documents below.
German is DeepL output that was then read end to end and corrected by hand. Simplified
Chinese is still deliberately not shipped; `lib/l10n/locale_resolution.dart` says so in
code, and `zh-Hans` must never be dressed up as 繁體中文.

## What the German locale claims, and what it does not

Mechanically it is held to the same standard as any other locale, and the checks are the
ones that can be automated: `test/l10n/arb_parity_test.dart` and
`tool/i18n_verify/check_arb.py` require the same keys, the same ICU arguments and no empty
values, every token on [do-not-translate.md](do-not-translate.md) was held out of the
translation request and verified in the result, and each plural branch was rewritten by
hand — a machine glues the argument to the noun (`{count}-Codes`) and starts new sentences
inside a branch, which breaks the sentence the branch sits in.

What it does not claim is a native speaker's reading on a screen. The correction pass fixed
the errors a reader of German can see in the string: `Port` as *Hafen*, `Mass` as *Messe*,
`Drive` as *Laufwerk*, `Displacement` as *Verdrängung*, `Stopped by you` as *Ich habe bei
Ihnen vorbeigeschaut*, and — the ones that matter here — `read-only` as *schreibgeschützt*,
`clear` drifting between *löschen*, *Freigabe* and *Bereinigung*, and `The ECU did not
answer` becoming *Der Befehl „ECU" wurde nicht beantwortet*. What it cannot fix is a
sentence that reads correctly and lands with less force than the English, which is the
failure [hedge-register.md](hedge-register.md) exists to name. So: a German string that
reads wrongly is a defect report, not a matter of taste, and the register is the standard
it is judged against.

These three documents and this index are the contract a translation is reviewed against. They are written in
English because they are read while editing English ARB entries, and because the terms
they define appear in both languages side by side.

| Document | What it settles |
|---|---|
| [glossary.md](glossary.md) | Term pairs, each with the file and line that established it |
| [do-not-translate.md](do-not-translate.md) | Tokens that must stay byte-identical, and why the line falls where it does |
| [hedge-register.md](hedge-register.md) | Sentences whose qualifiers are load-bearing |

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
