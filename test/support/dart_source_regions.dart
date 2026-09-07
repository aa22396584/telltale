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
/// fixtures that pin the two bugs it has actually had — an escape check that
/// compared one character against the two-character string `r'\\'` and was
/// therefore always false, and raw strings like `r'C:\'` where a backslash is
/// content rather than an escape — keep holding it.
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
      if (c == r'$' && i + 1 < src.length && src[i + 1] == '{') {
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
      while (i < src.length && src[i] != '\n') {
        i++;
      }
      mark(start, i, SourceRegion.comment);
      continue;
    }
    if (c == '/' && i + 1 < src.length && src[i + 1] == '*') {
      final close = src.indexOf('*/', i + 2);
      final end = close == -1 ? src.length : close + 2;
      mark(i, end, SourceRegion.comment);
      i = end;
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

/// [src] with everything that is not string-literal content replaced by a
/// space — the inverse view, for guards that police what the strings say.
String stringLiteralsOnly(String src) => onlyRegion(src, SourceRegion.string);
