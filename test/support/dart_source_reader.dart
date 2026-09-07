/// One reader for "which part of this Dart file am I looking at", shared by
/// every source-scanning guard.
///
/// It was written inside `test/l10n/transport_issue_guard_test.dart`, whose
/// header explains at length why a substring search is not enough: a
/// `TransportIssue.` written in a comment satisfied one, and
/// `'${notes.join('；')}'` puts a quote inside an interpolation, which a
/// quote-toggling scanner reads as closing the outer literal — desynchronising
/// every quote after it in the file. A guard that stops seeing constructions is
/// one that reports success.
///
/// It lives here because a second guard now needs it, and this repo's tests
/// already say what happens to two copies of the same rule: they drift apart,
/// and the weaker one is the one that stays green. The transport guard's
/// "the reader itself: what counts as code" test still drives this code, so the
/// fixtures that pin the bugs it has actually had — an escape check that
/// compared one character against the two-character string `r'\\'` and was
/// therefore always false, and raw strings like `r'C:\'` where a backslash is
/// content rather than an escape — keep holding it. How many there have been
/// is left out on purpose: the sentence said "two" until the next one was
/// found, and a number in a comment goes stale without anything failing.
///
/// `dart_source_reader_test.dart`, beside this file, is the other half: the
/// fixtures for where a comment ends — nested block comments, and the line
/// terminators that end a `//` — which assert the classification of every
/// character rather than a consequence of it. Both are needed. The
/// transport guard measures what a guard SEES, which is the failure that
/// matters; a region map measures what the reader SAYS, which is the only
/// thing an injected quote cannot resynchronise away from.
///
/// [SourceRegion] is a three-way answer rather than the original bool mask
/// because "not code" was not specific enough: a guard that forbids Chinese in
/// string literals has to allow it in comments, and this repo writes its
/// comments in Chinese.
library;

/// What a single character of a Dart source file is part of.
enum SourceRegion {
  /// Real code: not inside a string literal and not inside a comment.
  code,

  /// Inside a string literal, including its opening and closing quotes.
  ///
  /// The code inside `${...}` is [code], not this: an interpolation re-enters
  /// the language, and the string that opened it resumes at the matching `}`.
  string,

  /// Inside a `//` line comment or a `/* */` block comment.
  comment,
}

/// Raw strings do not process escapes, so a backslash in one is content.
class _Frame {
  const _Frame.string(this.quote, {this.raw = false}) : braceDepth = -1;
  const _Frame.interpolation(this.braceDepth) : quote = '', raw = false;

  final String quote;
  final int braceDepth;
  final bool raw;

  bool get isString => braceDepth < 0;
}

/// Classifies every character of [src]. The result has one entry per code unit,
/// so anything matched against a derived view can still be located in [src].
List<SourceRegion> sourceRegions(String src) {
  final regions = List<SourceRegion>.filled(src.length, SourceRegion.code);
  void mark(int from, int to, SourceRegion region) {
    for (var i = from; i < to && i < src.length; i++) {
      regions[i] = region;
    }
  }

  final frames = <_Frame>[];
  var braces = 0;
  var i = 0;
  while (i < src.length) {
    final inString = frames.isNotEmpty && frames.last.isString;
    final c = src[i];

    if (inString) {
      // The escape pair, both halves. Comparing `c` against a two-character
      // string here was always false, so no escape was honoured and
      // `'don\'t reopen'` closed the literal at the apostrophe, inverting
      // everything after it in the file. The `raw` test is not decoration:
      // fixing the comparison alone breaks `r'C:\'`, which has no escapes.
      if (c == '\\' && !frames.last.raw) {
        mark(i, i + 2, SourceRegion.string);
        i += 2;
        continue;
      }
      // `raw` here for the same reason it is on the escape above, and found
      // the same way -- by a reviewer, not by the fixtures. Dart reads
      // `r'${x}'` as six literal characters, so entering an interpolation
      // frame classifies `x` as *code*. `stringLiteralsOnly` then drops it,
      // and a guard asking "is there Chinese in a string literal here" is
      // handed a file with the string removed. It answers no, in green.
      if (c == r'$' &&
          !frames.last.raw &&
          i + 1 < src.length &&
          src[i + 1] == '{') {
        braces++;
        frames.add(_Frame.interpolation(braces));
        mark(i, i + 2, SourceRegion.string);
        i += 2;
        continue;
      }
      if (src.startsWith(frames.last.quote, i)) {
        mark(i, i + frames.last.quote.length, SourceRegion.string);
        i += frames.last.quote.length;
        frames.removeLast();
        continue;
      }
      regions[i] = SourceRegion.string;
      i++;
      continue;
    }

    if (c == '/' && i + 1 < src.length && src[i + 1] == '/') {
      final start = i;
      // A bare CR ends a line comment too. Dart's NEWLINE is CR, LF or CRLF,
      // and `// comment\rconst a = '測試';` compiles and prints 測試 — run,
      // not read. Stopping only at LF swallowed that declaration into the
      // comment, so a guard asking what the strings say saw no string at all:
      // the same shape as the nested-comment bug below, one branch over.
      // Found by review, not by the fixtures; no `.dart` file in this repo
      // has a CR today, so it was latent.
      //
      // The terminator itself stays outside the comment, which is what this
      // branch already did with LF — so after this, a CR inside a `//` line is
      // code, and `withoutComments` leaves it in place rather than blanking
      // it. That REMOVES an inconsistency rather than adding one: before, a
      // `\r` was swallowed into the comment on a line that had one and left
      // alone on a line that did not, so two line endings in one file were
      // treated differently depending on a comment. Review checked the two
      // `multiLine` guards that could care; both anchor on `^`, which still
      // matches after the `\n`, and no guard here anchors on `$`.
      //
      // One asymmetry does remain, and it is in [onlyRegion] rather than here:
      // its blanking special-cases `\n` only, so a `\r` outside the chosen
      // region becomes a space. Offsets still line up, so nothing reads it
      // wrong — but the next person tracing a line ending through this file
      // should not have to find that out twice.
      while (i < src.length && src[i] != '\n' && src[i] != '\r') {
        i++;
      }
      mark(start, i, SourceRegion.comment);
      continue;
    }
    if (c == '/' && i + 1 < src.length && src[i + 1] == '*') {
      // Dart block comments NEST, so the end is the matching `*/` and not the
      // first one. `indexOf('*/', i + 2)` was the reader's fourth silent bug:
      // in `/* /* */ don't\n*/\nconst a = '測試';` — a file that compiles and
      // prints 測試 — it ended the comment at the inner close, the apostrophe
      // in `don't` opened a phantom literal, and 測試 came out as *code*.
      // `stringLiteralsOnly` drops code, so a guard asking what the strings
      // say was handed the file with the string taken out, and answered no.
      //
      // No string handling inside this loop, deliberately: a comment has no
      // string literals in it. `/* " /* " */ */` compiles, which it could not
      // if the quotes hid the inner `/*` — the trailing `*/` would then be a
      // stray. Verified by compiling it, not by reading the grammar.
      //
      // `j += 2` on both arms for the same reason `indexOf` started at
      // `i + 2`: the `*` of an inner `/*` must not be reused as the `*` of a
      // close. `/* /*/ */` is unterminated in Dart, and resuming one character
      // on reads it as balanced.
      var depth = 1;
      var j = i + 2;
      while (j < src.length && depth > 0) {
        if (src[j] == '/' && j + 1 < src.length && src[j + 1] == '*') {
          depth++;
          j += 2;
        } else if (src[j] == '*' && j + 1 < src.length && src[j + 1] == '/') {
          depth--;
          j += 2;
        } else {
          j++;
        }
      }
      // Depth still open means there is no close: the rest of the file is
      // comment. That was already this branch's behaviour for `close == -1`,
      // and it is the safe direction — the alternative invents a literal out
      // of whatever punctuation follows.
      mark(i, j, SourceRegion.comment);
      i = j;
      continue;
    }
    if (c == "'" || c == '"') {
      // Dart has exactly four string forms, and that is why this is finite
      // work rather than a heuristic. A triple quote read as three toggles
      // inverts the rest of the file; two such strings then cancel, so the
      // file ends balanced while the region between them is invisible. No
      // end-state check can see that — inversions pair up — so this has to be
      // right rather than merely self-consistent.
      final triple = c * 3;
      final quote = src.startsWith(triple, i) ? triple : c;
      frames.add(_Frame.string(quote, raw: i > 0 && src[i - 1] == 'r'));
      mark(i, i + quote.length, SourceRegion.string);
      i += quote.length;
      continue;
    }
    if (c == '{') braces++;
    if (c == '}') {
      if (frames.isNotEmpty &&
          !frames.last.isString &&
          frames.last.braceDepth == braces) {
        // Back into the string that opened this interpolation. The brace
        // belongs to the literal, not to the code inside it.
        frames.removeLast();
        braces--;
        regions[i] = SourceRegion.string;
        i++;
        continue;
      }
      braces--;
    }
    regions[i] = SourceRegion.code;
    i++;
  }
  return regions;
}

/// True at every index of [src] that is real code.
List<bool> codeMask(String src) =>
    sourceRegions(src).map((r) => r == SourceRegion.code).toList();

/// [src] with every character outside [region] replaced by a space.
///
/// Offsets and line breaks are preserved, so a match against the result can
/// still be reported as a line number in the original.
String onlyRegion(String src, SourceRegion region) {
  final regions = sourceRegions(src);
  final out = StringBuffer();
  for (var i = 0; i < src.length; i++) {
    out.write(
      regions[i] == region ? src[i] : (src[i] == '\n' ? '\n' : ' '),
    );
  }
  return out.toString();
}

/// [src] with every string and comment character replaced by a space.
String codeOnly(String src) => onlyRegion(src, SourceRegion.code);

/// [src] with only its comments replaced by spaces — code and string literals
/// both survive.
///
/// The view a whole-line guard needs, and the reason it is not [codeOnly]:
/// several guards here match text that legitimately lives inside a literal —
/// an `import 'package:flutter/material.dart'` is a string, and so is a
/// `join('、')` separator — so blanking literals would leave those guards
/// reading nothing and reporting success. What they actually want removed is
/// the comment, because this repo names its own rules in comments and a guard
/// that cannot tell `// AppLocalizations` from an import accuses the file that
/// documents the rule.
///
/// The naive form of this — `line.split('//').first` — truncates at the `//`
/// of a URL, which silently hides everything after it on that line. That is
/// the failure three separate guards carried a copy of.
String withoutComments(String src) {
  final regions = sourceRegions(src);
  final out = StringBuffer();
  for (var i = 0; i < src.length; i++) {
    out.write(
      regions[i] == SourceRegion.comment ? (src[i] == '\n' ? '\n' : ' ') : src[i],
    );
  }
  return out.toString();
}

/// [src] with everything that is not string-literal content replaced by a
/// space — the inverse view, for guards that police what the strings say.
String stringLiteralsOnly(String src) => onlyRegion(src, SourceRegion.string);

/// The top-level arguments of the call whose `(` is at [open], read through
/// [mask] so string and comment content cannot look like syntax.
List<String>? topLevelArgs(String src, List<bool> mask, int open) {
  final spans = topLevelArgSpans(src, mask, open);
  if (spans == null) return null;
  return [for (final (start, end) in spans) src.substring(start, end)];
}

/// The same arguments as [topLevelArgs], as `(start, end)` offsets into [src].
///
/// Offsets rather than text, so a caller can ask what an argument IS as well as
/// what it says — whether any of it is string-literal content, for instance,
/// which is invisible once the argument has been copied into a new string.
/// [topLevelArgs] is this function plus `substring`, so the two cannot disagree
/// about where an argument begins.
///
/// **[open] must be the offset of a `(` that [mask] says is code.** Every
/// caller already ensures that — two skip a match whose start is masked out,
/// and the third matches against `codeOnly`, where a `(` inside a comment or a
/// string is a space. Outside that contract the two implementations differ:
/// review measured 1392 offsets across `lib/`, `test/` and `integration_test/`
/// where the old accumulator swept up the text between [open] and the first
/// real `(` into the first argument, and this one returns it empty. None is
/// reachable, which is why the difference is documented rather than
/// reconciled — but the contract was implicit before, and an implicit contract
/// is one the next caller does not know it is breaking.
///
/// `start` cannot be read while still `-1`: reaching the read requires `depth`
/// to be 1, and the only transition from 0 to 1 is the `(` that sets it.
/// Verified rather than argued — the same review diffed every offset of every
/// file, exceptions included, and found no `RangeError` path.
List<(int, int)>? topLevelArgSpans(String src, List<bool> mask, int open) {
  final spans = <(int, int)>[];
  var start = -1;
  var depth = 0;
  for (var i = open; i < src.length; i++) {
    final c = src[i];
    if (mask[i]) {
      if (c == '(' || c == '[' || c == '{') {
        depth++;
        if (depth == 1) {
          start = i + 1;
          continue;
        }
      } else if (c == ')' || c == ']' || c == '}') {
        depth--;
        if (depth == 0) {
          if (src.substring(start, i).trim().isNotEmpty) spans.add((start, i));
          return spans;
        }
      } else if (c == ',' && depth == 1) {
        spans.add((start, i));
        start = i + 1;
        continue;
      }
    }
  }
  return null;
}
