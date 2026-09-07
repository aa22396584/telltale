// The shared reader's own fixtures for the one thing about Dart comments that
// no substring search gets right by accident: block comments nest.
//
//     /* /* */ don't
//     */
//     const a = '測試';
//
// That file, with `void main() { print(a); }` after it, prints 測試 — verified
// by running it through `dart run`, not by reading the grammar. The `main` is
// not decoration in this sentence: the three lines alone are a valid library
// and compile, but a program is what prints. Read with `indexOf('*/')`, the
// comment ends at the FIRST close, the apostrophe in `don't` opens a phantom
// string literal, and 測試 comes out classified as *code*.
// `stringLiteralsOnly` then removes it, and a guard asking "is there a Chinese
// string literal in this file" is handed the file with the string taken out.
// It answers no, in green.
//
// That is the same failure class as the three bugs this reader has already
// had — an escape check comparing one character against a two-character
// string, raw strings where a backslash is content, and `${` inside a raw
// string — every one of which was green. Filed as ImL1s/telltale#109 rather
// than fixed inside the PR that found it, because changing what every guard
// sharing this reader sees deserves its own fixtures. How many that is, is
// not written here for the same reason the reader's own header no longer
// counts its bugs: the number was six when the issue was filed and is not
// six now, and nothing failed in between.
//
// **These fixtures assert the classification directly, character by
// character, rather than a consequence of it.** That is deliberate, and it is
// this repo's own lesson: `test/l10n/transport_issue_guard_test.dart`
// documents three fixtures that stayed green under the exact mutation they
// were written for, because the quote they injected resynchronised before the
// line they measured. A region map has nothing to resynchronise into.
//
// Where a fixture's expected reading is not obvious, the comment above it
// names the file that was compiled to establish it. Five were, each with a
// `main` that prints the declaration:
//
//   /* /* */ don't\n*/\nconst a = '測試';   -> prints 測試
//   /* /*/ */                              -> error: Comment starting with
//                                             '/*' must end with '*/'
//   /* " /* " */ */                        -> compiles, so a quote inside a
//                                             comment does not hide the `/*`
//                                             that follows it
//   /*/ don't */ const a = 'OK';           -> prints OK, so `/*/ … */` is one
//                                             comment and the scan starts two
//                                             characters in
//   // comment\rconst a = '測試';           -> prints 測試, so a bare CR ends
//                                             a line comment
library;

import 'package:flutter_test/flutter_test.dart';

import 'dart_source_reader.dart';

/// One character per code unit of [src]: `#` comment, `s` string, `c` code.
///
/// The whole classification rather than a sampled part of it, so a fixture
/// cannot pass because the reader happened to re-synchronise after the point
/// the assertion looks at.
String regionMap(String src) => sourceRegions(src)
    .map(
      (r) => switch (r) {
        SourceRegion.comment => '#',
        SourceRegion.string => 's',
        SourceRegion.code => 'c',
      },
    )
    .join();

void main() {
  group('block comments nest', () {
    test('a nested comment ends at its matching close, not the first one', () {
      // /* /* */ */x
      // 0123456789ab   -> 11 comment characters, then `x` is code again.
      expect(
        regionMap('/* /* */ */x'),
        '${'#' * 11}c',
        reason: 'the first `*/` closes the INNER comment; reading it as the '
            'end of the outer one hands the guard the rest of the file with '
            'its regions shifted',
      );
    });

    test('the file from the issue: 測試 stays a string literal', () {
      const src = "/* /* */ don't\n*/\nconst a = '測試';";

      // 17 comment characters (through the `*/` on line 2), then the newline
      // and `const a = ` are code, `'測試'` is a string, `;` is code.
      expect(
        regionMap(src),
        '${'#' * 17}${'c' * 11}${'s' * 4}c',
        reason: 'read with indexOf, the apostrophe in `don\'t` opens a phantom '
            'literal that runs to the quote before 測試 and closes there, so '
            '測試 lands in code',
      );

      // The same statement in the two views the guards actually consume. Both
      // directions: a reader that classified 測試 as neither would satisfy one
      // of these on its own.
      expect(
        stringLiteralsOnly(src),
        contains('測試'),
        reason: 'this is the exact question the l10n guards ask, and the exact '
            'answer that came back wrong and green',
      );
      expect(
        codeOnly(src),
        isNot(contains('測試')),
        reason: 'and it must not appear as code, which is where it went',
      );
    });

    test('an unterminated nested comment runs to the end of the file', () {
      // Depth never returns to zero, so there is no close. `dart run` rejects
      // such a file outright; the reader's existing convention for a comment
      // with no close is to treat the rest as comment, and that is the safe
      // direction — the alternative invents a string literal out of whatever
      // punctuation follows.
      const src = "/* /* */ const a = '測試';";
      expect(regionMap(src), '#' * 24);
      expect(
        stringLiteralsOnly(src).contains('測試'),
        isFalse,
        reason: 'nothing here is a string literal; the whole file is one '
            'unterminated comment',
      );
    });

    test('`/*/` opens a comment and does not also close it', () {
      // `/* /*/ */` was compiled: Dart calls it unterminated. So the scan that
      // follows an inner `/*` has to resume two characters later, not one —
      // resuming one character later reads the `*/` that overlaps the `/*` it
      // just consumed, balances the depth, and ends the comment at the second
      // close.
      const src = "/* /*/ */ const a = '測試';";
      expect(regionMap(src), '#' * 25);
    });

    test('an empty block comment closes on its own `*/`', () {
      // `/**/` holds the OTHER end of the same rule: the close's own two
      // characters. Its `*/` is at offsets 2-3, so this fixture says nothing
      // about where the scan starts — it goes red when a close advances by one
      // instead of two, which leaves the `/` of `*/` to be read again.
      const src = "/**/const a = '測試';";
      expect(regionMap(src), '####${'c' * 10}${'s' * 4}c');
    });

    test('the scan starts two characters in, not one', () {
      // Where the scan STARTS, which every fixture above misses: they all put
      // the first candidate close later in the string. `/*/ don't */` is one
      // comment — compiled to check — and a scan starting at `i + 1` reads the
      // `*/` overlapping the opener at offsets 1-2, ends the comment after
      // three characters, and hands `don't` to the string scanner. 測試 then
      // lands in code again.
      //
      // Codex found this: the previous version of the comment above claimed
      // `/**/` covered it, and it does not. Nothing in this file was red under
      // that mutation.
      const src = "/*/ don't */ const a = '測試';";
      expect(regionMap(src), '${'#' * 12}${'c' * 11}${'s' * 4}c');
      expect(stringLiteralsOnly(src), contains('測試'));
    });
  });

  group('a line comment ends at the line, however the line ends', () {
    test('a bare CR ends it', () {
      // `// comment\rconst a = '測試';` compiles and prints 測試 — Dart's
      // NEWLINE is CR, LF or CRLF. Stopping only at LF put the declaration
      // inside the comment and the literal stopped being a literal.
      const src = "// comment\rconst a = '測試';";
      expect(regionMap(src), '${'#' * 10}${'c' * 11}${'s' * 4}c');
      expect(stringLiteralsOnly(src), contains('測試'));
    });

    test('and CRLF leaves both characters outside it', () {
      // The terminator is not part of the comment, which is what this file
      // already asserts for a lone LF; CRLF must not become half a comment.
      const src = "// comment\r\nconst a = '測試';";
      expect(regionMap(src), '${'#' * 10}${'c' * 12}${'s' * 4}c');
    });
  });

  group('what does not count towards the depth', () {
    test('a quote inside a comment neither opens a literal nor hides a `/*`',
        () {
      // `/* " /* " */ */` compiles, which settles it: had the quote suppressed
      // the `/*` between the quotes, the first `*/` would have closed the
      // comment and the second would be a syntax error. It is not. Comments
      // have no string literals inside them, so the depth counter must not try
      // to skip them.
      const src = "/* \" /* \" */ */ const a = '測試';";
      expect(regionMap(src), '${'#' * 15}${'c' * 11}${'s' * 4}c');
      expect(stringLiteralsOnly(src), contains('測試'));
    });

    test('`/*` and `*/` inside a string literal are content', () {
      // The mirror of the case above, and the reason the depth counter lives
      // inside the comment branch rather than being a pass over the file: at
      // code level a quote DOES open a literal, and what is inside it is not
      // syntax.
      const src = "const a = '/* */'; const b = '測試';";
      expect(
        regionMap(src),
        '${'c' * 10}${'s' * 7}${'c' * 12}${'s' * 4}c',
      );
      expect(stringLiteralsOnly(src), contains('測試'));
    });

    test('a `/*` inside a line comment does not open a block comment', () {
      const src = "// /*\nconst a = '測試';";
      expect(regionMap(src), '${'#' * 5}${'c' * 11}${'s' * 4}c');
      expect(stringLiteralsOnly(src), contains('測試'));
    });
  });
}
