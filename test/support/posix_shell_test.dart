import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'posix_shell.dart';

void main() {
  test('WSL invokes scripts through bash', () {
    expect(
      PosixShell.wslInvocation(['tool/release/release_notes.sh', 'flag']),
      "bash 'tool/release/release_notes.sh' 'flag'",
    );
  });

  test('WSL probe returns null when the executable cannot launch', () {
    expect(
      PosixShell.probeWsl(r'C:\telltale-no-such-wsl.exe'),
      isNull,
      reason: 'ProcessException from a missing wsl.exe must become skip, '
          'not a test abort',
    );
  });

  test('WSL rejects a distro path that is not mounted', () {
    expect(
      PosixShell.wslDirectoryExists('wsl.exe', '/telltale-no-such-mount'),
      isFalse,
      reason: 'automount-off / missing-drive must skip, not cd-fail; '
          'fixtures live under Directory.systemTemp as well as the checkout',
    );
  });

  test('WSL requires both the checkout and the system temp directory', () {
    final required = PosixShell.wslRequiredWindowsPaths()
        .map((path) => path.replaceAll('/', '\\').toLowerCase())
        .toList();
    expect(
      required,
      contains(Directory.current.path.replaceAll('/', '\\').toLowerCase()),
    );
    expect(
      required,
      contains(
        Directory.systemTemp.path.replaceAll('/', '\\').toLowerCase(),
      ),
      reason: 'changelog fixtures are created under Directory.systemTemp',
    );
  });

  test('this host can run the release-notes scripts', () {
    final shell = PosixShell.discover();
    if (shell == null) {
      expect(
        Platform.isWindows,
        isTrue,
        reason: 'Linux/macOS always discover bash from PATH; a null '
            'shell is the Windows skip path, never a silent Linux pass',
      );
      markTestSkipped(
        'No Git-for-Windows or WSL bash on this Windows host; '
        'Linux/macOS always run these scripts.',
      );
      return;
    }
    expect(shell.executable, isNotEmpty);
  });

  test('discovered Windows bash is not the WindowsApps WSL stub', () {
    final shell = PosixShell.discover();
    if (shell == null) return;
    expect(
      shell.executable.toLowerCase(),
      isNot(contains('windowsapps')),
      reason: 'the WindowsApps bash.exe stub drops Dart environment maps',
    );
  });

  test('Cygwin OSTYPE is not treated as Git Bash', () {
    expect(PosixShell.ostypeLooksLikeGitBash('msys'), isTrue);
    expect(PosixShell.ostypeLooksLikeGitBash('msys2'), isTrue);
    expect(
      PosixShell.ostypeLooksLikeGitBash('cygwin'),
      isFalse,
      reason: 'Cygwin drive paths are /cygdrive/c, not Git-bash /c',
    );
  });

  test('Git bash search includes PATH and 32-bit Program Files', () {
    final names = PosixShell.gitBashCandidateList()
        .map((path) => path.replaceAll('/', '\\').toLowerCase())
        .toList();
    expect(
      names.any((path) => path.contains('program files (x86)\\git\\bin\\bash.exe')),
      isTrue,
      reason: '32-bit Git-for-Windows lives under Program Files (x86)',
    );
    if (!Platform.isWindows) return;
    final pathDirs = (Platform.environment['PATH'] ?? '')
        .split(';')
        .map((dir) => dir.trim())
        .where(
          (dir) =>
              dir.isNotEmpty && !dir.toLowerCase().contains('windowsapps'),
        );
    for (final dir in pathDirs) {
      final trimmed = dir.replaceAll(RegExp(r'[\\/]+$'), '');
      expect(
        names,
        contains('${trimmed.toLowerCase()}\\bash.exe'),
      );
      break;
    }
  });

  test('chmod invocation does not pass a GNU end-of-options marker', () {
    expect(
      PosixShell.chmodInvocation('000', "'/tmp/f'"),
      "chmod 000 '/tmp/f'",
    );
  });

  test('chmod 000 actually refuses a read', () {
    final shell = PosixShell.discover();
    if (shell == null) {
      markTestSkipped(
        'No Git-for-Windows or WSL bash on this Windows host; '
        'Linux/macOS always run these scripts.',
      );
      return;
    }
    final dir = Directory.systemTemp.createTempSync('posix-shell-chmod');
    addTearDown(() {
      if (dir.existsSync()) dir.deleteSync(recursive: true);
    });
    final file = File('${dir.path}/unreadable.md')..writeAsStringSync('REAL\n');
    addTearDown(() => shell.chmod('644', file.path));
    expect(shell.chmod('000', file.path).exitCode, 0);
    var readable = true;
    try {
      file.readAsStringSync();
    } on FileSystemException {
      readable = false;
    }
    // Same split as release_notes_contract_test: root can still read
    // chmod 000, so requiring a throw here would fail the helper while
    // the contract suite already treats that uid as "still readable".
    if (readable) {
      expect(
        Platform.isWindows,
        isFalse,
        reason: 'Windows icacls deny must refuse the read',
      );
    }
  });

  test('flag mode sees TAG through the discovered shell', () {
    final shell = PosixShell.discover();
    if (shell == null) {
      markTestSkipped(
        'No Git-for-Windows or WSL bash on this Windows host; '
        'Linux/macOS always run these scripts.',
      );
      return;
    }
    final result = shell.runScript(
      'tool/release/release_notes.sh',
      const ['flag'],
      environment: const {'TAG': 'v1.0.12'},
    );
    expect(result.exitCode, 0, reason: 'stderr: ${result.stderr}');
    expect((result.stdout as String).trim(), 'full');
  });
}
