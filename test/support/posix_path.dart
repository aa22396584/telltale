/// Path spelling used by hand-typed source-scan rosters.
///
/// `Directory.listSync` yields backslashes on Windows. The guards compare
/// those paths to POSIX literals (`lib/ui/...`) and skip copy files with
/// `==` / `Set.contains`, so a backslash spelling makes the copy file look
/// like a render site and every Windows host fails the census. Normalising
/// here keeps the roster and the scan in the same alphabet; the expectations
/// stay the POSIX strings the files are committed as.
library;

/// [path] with every backslash turned into a slash.
///
/// POSIX inputs are unchanged, so Linux and macOS keep comparing equal to
/// the same literals.
String posixPath(String path) => path.replaceAll(r'\', '/');

/// [path] as a POSIX-shell absolute path for Git-for-Windows or WSL.
///
/// Relative paths keep their slash form. Drive-letter paths become
/// `/c/Users/...` (Git bash) or `$wslMountPrefix/c/Users/...` (WSL).
/// The prefix is `/mnt` by default; WSL `[automount] root` can be
/// something else, so PosixShell probes it with `wslpath` rather than
/// assuming `/mnt`. Unquoted `echo ::error::$EVIDENCE` in
/// `require_device_walk.sh` eats backslashes; converting here is what
/// lets that script name the file on Windows.
String posixShellPath(
  String path, {
  required bool wsl,
  String wslMountPrefix = '/mnt',
}) {
  final normalised = posixPath(path);
  if (normalised.length >= 2 && normalised[1] == ':') {
    final drive = normalised[0].toLowerCase();
    final rest = normalised.substring(2);
    if (!wsl) return '/$drive$rest';
    final prefix = wslMountPrefix.endsWith('/')
        ? wslMountPrefix.substring(0, wslMountPrefix.length - 1)
        : wslMountPrefix;
    return prefix.isEmpty ? '/$drive$rest' : '$prefix/$drive$rest';
  }
  return normalised;
}
