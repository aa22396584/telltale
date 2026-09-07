// A reader that tells Dart code from the strings and comments around it.
//
// Extracted from `test/l10n/transport_issue_guard_test.dart`, which needed it
// first and still owns the fixtures that prove it — see the "the reader itself"
// test there. It lives here because a second guard now scans for a second
// construction (`test/l10n/datum_reason_guard_test.dart`), and the alternative
// to sharing this was a third hand-written parser. Two of the three bugs this
// file has already survived came from exactly that: a naive scanner that had
// never met an interpolated quote or an escaped apostrophe.
//
// Not a `_test.dart` file, so `flutter test` does not run it on its own; the
// fixtures that hold it honest run from the transport guard.
library;

/// [src] with every string and comment character replaced by a space.
///
/// Offsets and line breaks are preserved, so anything matched against this can
/// still be located in the original.
String codeOnly(String src) {
  final mask = codeMask(src);
  final out = StringBuffer();
  for (var i = 0; i < src.length; i++) {
    out.write(mask[i] ? src[i] : (src[i] == '\n' ? '\n' : ' '));
  }
  return out.toString();
}

/// True at every index that is real code -- not inside a string literal and not
/// inside a comment.
///
/// One pass, shared by every reader in this file, because they have to agree.
/// Two
/// things made the naive version wrong:
///
///   * `// TODO: pick a TransportIssue. for this one` satisfied a substring
///     search, so a throw with no identifier passed. Precedent for stripping
///     first: `test/l10n/l04_status_l10n_test.dart` does the same, for the same
///     reason -- comments may name the rule; code may not.
///   * `'${tierNotes.join('；')}'` in `classic_transport.dart` puts a quote
///     inside an interpolation. Tracking quotes alone reads the inner `'` as
///     closing the outer literal. It happens to resynchronise there because the
///     nested quotes pair up, which is luck, not correctness -- an odd number
///     desynchronises everything after it in the file, and a guard that stops
///     seeing constructions is one that reports success.
///
/// So interpolation is a stack: `${` inside a string re-enters code, and the
/// matching `}` returns to the string that opened it.
class _Frame {
  const _Frame.string(this.quote, {this.raw = false}) : braceDepth = -1;
  const _Frame.interpolation(this.braceDepth) : quote = '', raw = false;

  final String quote;
  final int braceDepth;

  /// Raw strings do not process escapes, so a backslash in one is content.
  final bool raw;

  bool get isString => braceDepth < 0;
}

List<bool> codeMask(String src) {
  final mask = List<bool>.filled(src.length, false);
  final frames = <_Frame>[];
  var braces = 0;
  var i = 0;
  while (i < src.length) {
    final inString = frames.isNotEmpty && frames.last.isString;
    final c = src[i];

    if (inString) {
      // Was `c == r'\\'`, comparing one character against a two-character
      // string -- always false, so no escape was ever honoured and
      // `'don\\'t reopen'` closed the literal at the apostrophe, inverting the
      // mask for the rest of the file. Everyday Dart, and far likelier than any
      // triple-quote shape. The `raw` test is not decoration: fixing the
      // comparison alone breaks `r'C:\\'`, which has no escapes to honour.
      if (c == '\\' && !frames.last.raw) {
        i += 2;
        continue;
      }
      if (c == r'$' && i + 1 < src.length && src[i + 1] == '{') {
        braces++;
        frames.add(_Frame.interpolation(braces));
        i += 2;
        continue;
      }
      if (src.startsWith(frames.last.quote, i)) {
        i += frames.last.quote.length;
        frames.removeLast();
        continue;
      }
      i++;
      continue;
    }

    if (c == '/' && i + 1 < src.length && src[i + 1] == '/') {
      while (i < src.length && src[i] != '\n') {
        i++;
      }
      continue;
    }
    if (c == '/' && i + 1 < src.length && src[i + 1] == '*') {
      final close = src.indexOf('*/', i + 2);
      i = close == -1 ? src.length : close + 2;
      continue;
    }
    if (c == "'" || c == '"') {
      // Dart has exactly four string forms, and that is why this is finite
      // work rather than a heuristic. A triple quote read as three toggles
      // inverts the rest of the file; two such strings then cancel, so the file
      // ends balanced while the region between them is invisible. No end-state
      // check can see that -- inversions pair up -- so the mask has to be right.
      final triple = c * 3;
      final quote = src.startsWith(triple, i) ? triple : c;
      frames.add(
        _Frame.string(quote, raw: i > 0 && src[i - 1] == 'r'),
      );
      i += quote.length;
      continue;
    }
    if (c == '{') braces++;
    if (c == '}') {
      if (frames.isNotEmpty &&
          !frames.last.isString &&
          frames.last.braceDepth == braces) {
        frames.removeLast(); // back into the string that opened this
        braces--;
        i++;
        continue;
      }
      braces--;
    }
    mask[i] = true;
    i++;
  }
  return mask;
}

/// The top-level arguments of the call whose `(` is at [open], read through
/// [mask] so string and comment content cannot look like syntax.
List<String>? topLevelArgs(String src, List<bool> mask, int open) {
  final args = <String>[];
  final cur = StringBuffer();
  var depth = 0;
  for (var i = open; i < src.length; i++) {
    final c = src[i];
    if (mask[i]) {
      if (c == '(' || c == '[' || c == '{') {
        depth++;
        if (depth == 1) continue;
      } else if (c == ')' || c == ']' || c == '}') {
        depth--;
        if (depth == 0) {
          if (cur.toString().trim().isNotEmpty) args.add(cur.toString());
          return args;
        }
      } else if (c == ',' && depth == 1) {
        args.add(cur.toString());
        cur.clear();
        continue;
      }
    }
    cur.write(c);
  }
  return null;
}
