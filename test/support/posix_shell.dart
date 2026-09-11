/// Locate a POSIX shell that can execute `tool/release/*.sh` on this host.
///
/// Linux and macOS use `bash` from PATH. Windows must not use the
/// `WindowsApps` `bash.exe` stub: that launches WSL without the Dart
/// `environment:` map, so `TAG:?TAG is required` even when the test set TAG.
/// Git-for-Windows bash receives the map. WSL is a fallback that injects
/// the same variables on the command line.
///
/// A host with neither Git bash nor WSL skips the contract tests with an
/// explicit reason. That skip is false on Linux/macOS, so
/// `tool/workshop/count_dart_tests.py` and `assert_no_skips.py` keep
/// counting the same cases in CI.
library;

import 'dart:convert';
import 'dart:io';

import 'posix_path.dart';

enum PosixShellKind { posix, gitBash, wsl }

class PosixShell {
  PosixShell._(this.executable, this.kind, {this.wslMountPrefix = '/mnt'});

  final String executable;
  final PosixShellKind kind;

  /// WSL `[automount] root` (no trailing slash). Git-bash and POSIX ignore this.
  final String wslMountPrefix;

  bool get isWsl => kind == PosixShellKind.wsl;

  /// Honour `TELLTALE_POSIX_SHELL=git|wsl` so a Windows host that has both
  /// can prove each dispatch path. Unset prefers Git bash, then WSL.
  static PosixShell? discover() {
    if (!Platform.isWindows) {
      return PosixShell._('bash', PosixShellKind.posix);
    }
    final pin = Platform.environment['TELLTALE_POSIX_SHELL']?.trim().toLowerCase();
    if (pin == 'git') return _gitBash();
    if (pin == 'wsl') return _wsl();
    return _gitBash() ?? _wsl();
  }

  static PosixShell? _gitBash() {
    for (final candidate in _gitBashCandidates()) {
      if (!_isGitBash(candidate)) continue;
      return PosixShell._(candidate, PosixShellKind.gitBash);
    }
    return null;
  }

  static Iterable<String> _gitBashCandidates() sync* {
    yield r'C:\Program Files\Git\bin\bash.exe';
    yield r'C:\Program Files\Git\usr\bin\bash.exe';
    yield r'C:\Program Files (x86)\Git\bin\bash.exe';
    yield r'C:\Program Files (x86)\Git\usr\bin\bash.exe';
    for (final root in [
      Platform.environment['ProgramFiles'],
      Platform.environment['ProgramFiles(x86)'],
    ]) {
      if (root != null && root.isNotEmpty) {
        yield '$root\\Git\\bin\\bash.exe';
        yield '$root\\Git\\usr\\bin\\bash.exe';
      }
    }
    final local = Platform.environment['LOCALAPPDATA'];
    if (local != null && local.isNotEmpty) {
      yield '$local\\Programs\\Git\\bin\\bash.exe';
    }
    final git = _whichOnPath('git.exe');
    if (git != null) {
      final dir = File(git).parent.path;
      yield '$dir\\bash.exe';
      yield '$dir\\..\\bin\\bash.exe';
      yield '$dir\\..\\usr\\bin\\bash.exe';
    }
    final path = Platform.environment['PATH'] ?? '';
    for (final dir in path.split(';')) {
      if (dir.isEmpty) continue;
      final trimmed = dir.replaceAll(RegExp(r'[\\/]+$'), '');
      yield '$trimmed\\bash.exe';
    }
  }

  /// Test-visible so PATH / Program Files (x86) search cannot silently shrink.
  static List<String> gitBashCandidateList() => _gitBashCandidates().toList();

  static String? _whichOnPath(String exe) {
    final path = Platform.environment['PATH'] ?? '';
    for (final dir in path.split(';')) {
      if (dir.isEmpty) continue;
      final candidate = '$dir\\$exe';
      if (File(candidate).existsSync()) return candidate;
    }
    return null;
  }

  /// Git-for-Windows reports `msys`. Cygwin uses `/cygdrive/c` rather than
  /// `/c`, so it is not a drop-in for `posixShellPath(..., wsl: false)`.
  static bool ostypeLooksLikeGitBash(String ostype) =>
      ostype.toLowerCase().contains('msys');

  static bool _isGitBash(String executable) {
    final lower = executable.replaceAll('/', '\\').toLowerCase();
    if (lower.contains('windowsapps')) return false;
    if (!File(executable).existsSync()) return false;
    try {
      final result = Process.runSync(
        executable,
        const ['-lc', r'echo "$OSTYPE"'],
      );
      if (result.exitCode != 0) return false;
      final ostype = (result.stdout as String).toLowerCase();
      return ostypeLooksLikeGitBash(ostype);
    } on ProcessException {
      return false;
    }
  }

  static PosixShell? _wsl({String executable = 'wsl.exe'}) {
    // Missing wsl.exe throws ProcessException; a nonzero result does not.
    // Either must become null so the contract tests skip instead of aborting.
    final ProcessResult probe;
    try {
      probe = Process.runSync(
        executable,
        const ['-e', 'bash', '-lc', 'echo telltale-bash-ok'],
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      );
    } on ProcessException {
      return null;
    }
    if (probe.exitCode != 0) return null;
    if (!(probe.stdout as String).contains('telltale-bash-ok')) return null;
    final prefix = _probeWslMountPrefix(executable);
    for (final windowsPath in wslRequiredWindowsPaths()) {
      final converted = posixShellPath(
        windowsPath,
        wsl: true,
        wslMountPrefix: prefix,
      );
      if (!wslDirectoryExists(executable, converted)) return null;
    }
    return PosixShell._(
      executable,
      PosixShellKind.wsl,
      wslMountPrefix: prefix,
    );
  }

  /// Checkout plus `Directory.systemTemp`: the contract suite's fixtures
  /// are created in temp, which may be a different Windows drive.
  static List<String> wslRequiredWindowsPaths() => [
        Directory.current.path,
        Directory.systemTemp.path,
      ];

  /// True when [distroPath] exists inside WSL. False when automount is
  /// off, the drive is missing, or [executable] cannot launch.
  static bool wslDirectoryExists(String executable, String distroPath) {
    try {
      final result = Process.runSync(
        executable,
        ['-e', 'bash', '-lc', 'test -d ${_shQuote(distroPath)}'],
      );
      return result.exitCode == 0;
    } on ProcessException {
      return false;
    }
  }

  static String _probeWslMountPrefix(String executable) {
    try {
      final probe = Process.runSync(
        executable,
        const ['-e', 'bash', '-lc', "wslpath -a 'C:/'"],
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      );
      if (probe.exitCode != 0) return '/mnt';
      final sample = (probe.stdout as String).trim();
      final match =
          RegExp(r'^(.*)/c/?$', caseSensitive: false).firstMatch(sample);
      if (match == null) return '/mnt';
      return match.group(1)!;
    } on ProcessException {
      return '/mnt';
    }
  }

  /// Same launch as [_wsl]. Tests pin a missing path so the skip path
  /// stays mutation-proved on hosts that do have WSL.
  static PosixShell? probeWsl(String executable) =>
      _wsl(executable: executable);

  String toShellPath(String path) => posixShellPath(
        path,
        wsl: isWsl,
        wslMountPrefix: wslMountPrefix,
      );

  /// Run [script] (repo-relative or absolute) with [args], converting
  /// Windows paths in arguments and `*_PATH` environment values.
  ProcessResult runScript(
    String script,
    List<String> args, {
    Map<String, String>? environment,
    bool includeParentEnvironment = true,
    Encoding? stdoutEncoding = utf8,
    Encoding? stderrEncoding = utf8,
  }) {
    final convertedEnv = {
      if (environment != null)
        for (final entry in environment.entries)
          entry.key: _convertEnvValue(entry.key, entry.value),
    };
    return _run(
      [toShellPath(script), ...args.map(_convertArg)],
      environment: convertedEnv,
      includeParentEnvironment: includeParentEnvironment,
      stdoutEncoding: stdoutEncoding,
      stderrEncoding: stderrEncoding,
    );
  }

  ProcessResult chmod(String mode, String path) {
    // Git-bash `chmod` on NTFS does not make the file unreadable to awk;
    // icacls does. POSIX still uses chmod so Linux CI keeps proving the
    // same refuse-on-unreadable path.
    if (Platform.isWindows) return _windowsAcl(mode, path);
    final quoted = _shQuote(toShellPath(path));
    return _run(['-c', chmodInvocation(mode, quoted)]);
  }

  /// `chmod MODE PATH` with no GNU `--`.
  ///
  /// Test paths never start with `-`. GNU chmod accepts the bare form.
  /// BSD chmod treats `--` as a filename, exits 1, and still applies the
  /// mode to the real path — so `posix_shell_test` failed on Mac while the
  /// file did become unreadable.
  static String chmodInvocation(String mode, String quotedPath) =>
      'chmod $mode $quotedPath';

  ProcessResult _windowsAcl(String mode, String path) {
    final user = Platform.environment['USERNAME'] ?? '';
    if (mode == '000') {
      return Process.runSync('icacls', [path, '/deny', '$user:(R)']);
    }
    final removed = Process.runSync('icacls', [path, '/remove:d', user]);
    if (removed.exitCode != 0) return removed;
    return Process.runSync('icacls', [path, '/grant:r', '$user:(R,W)']);
  }

  String _convertArg(String value) =>
      _looksLikeWindowsAbsolute(value) ? toShellPath(value) : posixPath(value);

  String _convertEnvValue(String key, String value) {
    if (key.endsWith('_PATH') || _looksLikeWindowsAbsolute(value)) {
      return toShellPath(value);
    }
    return value;
  }

  static bool _looksLikeWindowsAbsolute(String path) =>
      path.length >= 2 && path[1] == ':';

  ProcessResult _run(
    List<String> args, {
    Map<String, String>? environment,
    bool includeParentEnvironment = true,
    Encoding? stdoutEncoding = utf8,
    Encoding? stderrEncoding = utf8,
  }) {
    switch (kind) {
      case PosixShellKind.posix:
        return Process.runSync(
          executable,
          args,
          environment: environment,
          includeParentEnvironment: includeParentEnvironment,
          workingDirectory: Directory.current.path,
          stdoutEncoding: stdoutEncoding,
          stderrEncoding: stderrEncoding,
        );
      case PosixShellKind.gitBash:
        return Process.runSync(
          executable,
          args,
          environment: _gitEnvironment(environment, includeParentEnvironment),
          includeParentEnvironment: includeParentEnvironment,
          workingDirectory: Directory.current.path,
          stdoutEncoding: stdoutEncoding,
          stderrEncoding: stderrEncoding,
        );
      case PosixShellKind.wsl:
        return _runWsl(
          args,
          environment: environment,
          includeParentEnvironment: includeParentEnvironment,
          stdoutEncoding: stdoutEncoding,
          stderrEncoding: stderrEncoding,
        );
    }
  }

  Map<String, String> _gitEnvironment(
    Map<String, String>? environment,
    bool includeParentEnvironment,
  ) {
    final env = <String, String>{...?environment};
    final gitPath = _gitPathPrefix();
    final existing = env['PATH'] ??
        (includeParentEnvironment ? Platform.environment['PATH'] : null) ??
        '';
    env['PATH'] = existing.isEmpty ? gitPath : '$gitPath;$existing';
    env['MSYS_NO_PATHCONV'] = '1';
    env.putIfAbsent(
      'SYSTEMROOT',
      () => Platform.environment['SYSTEMROOT'] ?? r'C:\Windows',
    );
    env.putIfAbsent(
      'WINDIR',
      () => Platform.environment['WINDIR'] ?? r'C:\Windows',
    );
    return env;
  }

  String _gitPathPrefix() {
    final bashDir = File(executable).parent.path;
    final usrBin = Directory('$bashDir\\..\\usr\\bin');
    if (usrBin.existsSync()) {
      return '${usrBin.path};$bashDir';
    }
    return bashDir;
  }

  ProcessResult _runWsl(
    List<String> args, {
    Map<String, String>? environment,
    bool includeParentEnvironment = true,
    Encoding? stdoutEncoding = utf8,
    Encoding? stderrEncoding = utf8,
  }) {
    final cwd = toShellPath(Directory.current.path);
    final exports = <String>[];
    // WSL's Windows stub does not receive Dart's environment map. Named keys
    // go on the command line. `wsl.exe` itself still needs a parent
    // environment so it can launch; Windows PATH is not forwarded into
    // bash, which is what `includeParentEnvironment: false` asked for.
    final injected = environment ?? const <String, String>{};
    for (final entry in injected.entries) {
      exports.add('${entry.key}=${_shQuote(entry.value)}');
    }
    final prefix = exports.isEmpty ? '' : '${exports.join(' ')} ';
    final isolated = includeParentEnvironment
        ? prefix
        : 'env -i PATH=/usr/bin:/bin $prefix';
    final command = 'cd ${_shQuote(cwd)} && $isolated${_wslCommand(args)}';
    return Process.runSync(
      executable,
      ['-e', 'bash', '-lc', command],
      stdoutEncoding: _wslEncoding(stdoutEncoding),
      stderrEncoding: _wslEncoding(stderrEncoding),
    );
  }

  static Encoding? _wslEncoding(Encoding? encoding) {
    if (encoding == null) return null;
    if (encoding is Utf8Codec) {
      return const Utf8Codec(allowMalformed: true);
    }
    return encoding;
  }

  /// WSL command line for [args]. Scripts go through `bash` so a
  /// `noexec` mount or missing `+x` is not exit 126.
  static String wslInvocation(List<String> args) {
    if (args.isNotEmpty && args.first == '-c') {
      final body = args.length > 1 ? args[1] : '';
      return 'bash -c ${_shQuote(body)}';
    }
    return 'bash ${args.map(_shQuote).join(' ')}';
  }

  String _wslCommand(List<String> args) => wslInvocation(args);

  static String _shQuote(String value) => "'${value.replaceAll("'", "'\\''")}'";
}
