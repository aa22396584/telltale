# Torque PID formula dialect

This is the compatibility subset `FormulaEngine` actually evaluates. A CSV
header, a wiki page, or a file Torque Pro can open is not proof that every
equation in it will compute here.

External qualification against a named Torque Pro build is **not-run**. The
published reference used to name wiki functions is:

- https://wiki.torque-bhp.com/view/Equations
- MediaWiki `oldid=603`, last modified 7 February 2022

That page is a reference to verify, not a runtime oracle and not permission to
invent compatibility.

## Supported

Indexed bytes `A`..`N` bind to the reply's *data* bytes (Mode 01 drops the
`0x41` prefix plus PID; Mode 22 drops `0x62` plus two PID bytes). A letter
past the payload is `byteBeyondResponse`, not zero.

| Construct | Shape | Notes |
| --- | --- | --- |
| Arithmetic | `+ - * / % ^` | `%` is Java/Torque remainder (sign of the dividend), not Dart Euclidean `%`. |
| Bitwise / compare | `& \| ~ ! == != > < >= <=` | Integers via `toInt()` for `&` / `\|` / `~`. |
| Grouping | `( … )` | Nested past 256 groups is `parenthesisNestingTooDeep`. |
| `SIGNED(letter)` | `SIGNED(A)` | 8-bit two's complement of that byte. Not `SIGNED16(`. |
| `SIGNED8(x)` | unary | Same 8-bit conversion as `SIGNED`, of the toward-zero integer's low 8 bits. `SIGNED8(255)` is -1, matching `SIGNED(A)` of 0xFF, not `SIGNED16(255)`. `2SIGNED8(0)` is `unparsableTerm`, not 0. Grouped `SIGNED8((A-1))` is accepted. |
| `SIGNED16(x)` | unary | 16-bit two's complement of the toward-zero integer (Java `(short)` of the low 16 bits). `SIGNED16(255)` is 255, not `SIGNED(A)` of 0xFF. `SIGNED16((A*256)+B)` is the two-byte form. Not `INT16(A:B)`. `2SIGNED16(0)` is `unparsableTerm`, not 0. Grouped `SIGNED16((A-1))` is accepted. |
| `SIGNED24(x)` | unary | 24-bit two's complement of the toward-zero integer's low 24 bits. `SIGNED24(8388608)` is -8388608. `SIGNED24(255)` is 255, not `SIGNED8(255)`. `2SIGNED24(0)` is `unparsableTerm`, not 0. Grouped `SIGNED24((A-1))` is accepted. |
| `SIGNED32(x)` | unary | 32-bit two's complement of the toward-zero integer's low 32 bits. `SIGNED32(2147483648)` is -2147483648. `SIGNED32(255)` is 255, not `SIGNED8(255)`. `2SIGNED32(0)` is `unparsableTerm`, not 0. Grouped `SIGNED32((A-1))` is accepted. |
| `FLOAT32(a:b:c:d)` | arity 4 | IEEE754 binary32 from four inputs. A is the most significant byte (sign bit). Each input uses the toward-zero integer's low 8 bits. `FLOAT32(63:128:0:0)` is 1.0. Little-endian payloads use `FLOAT32(D:C:B:A)`. Inf/NaN is `resultNotFinite`, not 0. A single comma form (`FLOAT32(A,B,C,D)`) is accepted. Wrong arity is `unparsableTerm`. `2FLOAT32(0:0:0:0)` is `unparsableTerm`, not 0. Grouped `FLOAT32((A-1):B:C:D)` is accepted. Not `FLOAT64`. |
| `INT(x)` | unary | Toward-zero integer of a finite value. `INT(1.9)` is 1. `INT(-1.9)` is -1, not floor -2. `2INT(1)` is `unparsableTerm`, not 21. Grouped `INT((A-1))` is accepted. Not `INT16(A:B)` / `INT24` / `INT32`. |
| `VAL{hex}` | `VAL{010C}` | Same-controller cached PID. Missing/stale/ambiguous is not a syntax error. |
| `BARO` | identifier, no `(` | Cached ambient pressure for the requesting controller. |
| `ABS(x)` | unary | Nested past 64 function reductions is `functionNestingTooDeep`. |
| `LOG10(x)` | unary | Domain error when `x <= 0`. Not `LOG(`. |
| `LOG(x)` | unary | Natural log (base e). Domain error when `x <= 0`. Not `LOG10(` or `LOG1P(`. |
| `LOG1P(x)` | unary | Natural log of `(1+x)`, matching Java `Math.log1p` (tiny `x` is not cancelled to 0). Domain `x > -1`; `x <= -1` is `resultNotFinite`. Not `LOG(` or `LOG10(`. `2LOG1P(0)` is `unparsableTerm`, not 0. Grouped `LOG1P((A-1))` is accepted. |
| `SQRT(x)` | unary | Domain error when `x < 0`. Zero is allowed. |
| `SIN(x)` / `COS(x)` / `TAN(x)` | unary | Radians, matching Java `Math.sin`/`cos`/`tan`. Not degrees. `2SIN(0)` is `unparsableTerm`, not 20. |
| `MIN(a:b)` / `MAX(a:b)` | arity 2 | Wiki colon form. A single comma (`MAX(A,B)`) is accepted. Arguments may be grouped (`MIN((A+1):B)`). Empty sides or a second top-level separator are `unparsableTerm`, not a number. |
| `BIT(value:bit)` | arity 2 | Wiki colon form. Returns 0 or 1. A negative or non-integer bit index is `unparsableTerm`, not 0. |

Authoring (`FormulaEngine.preflight`) uses stand-in bytes and `VAL`/`BARO`
samples so a well-formed formula can be saved before a live reading exists.
Runtime evaluation still refuses missing or stale dependencies.

## Unsupported

These wiki names are detected as `NAME(` and fail as
`FormulaIssue.unsupportedConstruct`. They are **not** evaluated as zero and
are **not** stripped out of the equation.

`EWMAF` `TAVG` `RAVG` `AVG` `TDLY` `RDLY` `TOT`
`INT32` `INT24` `INT16`
`FLOAT64` `LOOKUP` `CLOSEST` `RANDOM` `BARO()`

`LOG10` is not classified as `LOG`. `SIGNED8(x)` is the same 8-bit
conversion as `SIGNED(A)`, not `SIGNED16`. `SIGNED16(x)` is not classified as `SIGNED` or `INT16`. `SIGNED24(x)` is 24-bit, not `SIGNED16`. `SIGNED32(x)` is 32-bit, not `SIGNED24`. `FLOAT32(A:B:C:D)` is not `FLOAT64`. `INT(x)` is not `INT16`. `BARO` without parentheses is the identifier above; `BARO()` is
the wiki function that reads the Android barometer or ECU baro **in psi**,
which this engine does not implement.

### INT16 is unclaimed

The wiki text for `INT16(A:B)` says it "can be used in place of `(A*255)+B`".
The conventional big-endian two-byte integer is `(A*256)+B`. Those are
different numbers for every `A > 0`. This dialect does not implement `INT16`
and does not treat the wiki sentence as an executable oracle. Write
`(A*256)+B` (or `(A*255)+B` if that is the identity you measured) explicitly.

## Unknown

A token that is not a number, an operator, a supported name, or an
unsupported wiki `NAME(` is `unparsableTerm`. Example: `FOOZ(A)`.

## Resource limits

- Function reduction: 64 passes (`functionNestingTooDeep`).
- Parenthesis collapse: 256 (`parenthesisNestingTooDeep`).
- No `eval`, shell, network, or script execution.

## CSV columns

Named imports require Name, ModeAndPID, and Equation after header
normalization. Telltale-only export columns are not a Torque Pro interchange
format. See `PidCsv` and `test/pid_compatibility/`.

## What this file is not

- Not a claim that Torque Pro will round-trip Telltale's full export.
- Not a claim that every wiki example was executed in Torque Pro here.
- Not a new vehicle pack or a UDS stack.
