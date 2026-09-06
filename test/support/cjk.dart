/// One definition of "this is still Chinese", shared by every localization test.
///
/// Nine waves each wrote their own detector and eight of them matched Han
/// characters only. That gap shipped a real defect: the powertrain catalogue
/// joined signal names with `、` (U+3001, an ideographic comma), so eighteen of
/// the fifty-one commands rendered
/// "Battery temperature 1、Battery temperature 2" to an English reader while
/// every test stayed green. Every word had been translated. The punctuation had
/// not, and nothing was looking at punctuation.
///
/// [chinese] is a drop-in [RegExp] so a file can use it wherever it used its
/// own — `hasMatch`, `contains`, `matches` — and cannot accidentally go back to
/// checking one half.
library;

/// Han ideographs, plus CJK and fullwidth punctuation.
///
/// Ranges: CJK Unified Ideographs and Extension A (U+3400–U+9FFF), CJK
/// Compatibility Ideographs (U+F900–U+FAFF), CJK Symbols and Punctuation
/// including the ideographic space and comma (U+3000–U+303F), Small Form
/// Variants (U+FE50–U+FE6F), and Halfwidth and Fullwidth Forms (U+FF00–U+FFEF).
final RegExp chinese = RegExp(r'[㐀-鿿豈-﫿　-〿︰-﹏＀-￯]');

/// Han ideographs only. Use [chinese] unless you specifically mean "a word",
/// as distinct from punctuation.
final RegExp han = RegExp(r'[㐀-鿿豈-﫿]');

/// CJK and fullwidth punctuation only: 。，、；：（）「」『』—— and U+3000.
final RegExp cjkPunctuation = RegExp(r'[　-〿︰-﹏＀-￯]');

/// True when [value] holds any Han character or any CJK/fullwidth punctuation.
bool containsChinese(String value) => chinese.hasMatch(value);

/// The offending characters in [value], for a failure message that says which.
String chineseIn(String value) => value.runes
    .map(String.fromCharCode)
    .where(chinese.hasMatch)
    .join();
