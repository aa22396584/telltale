import 'package:flutter_test/flutter_test.dart';

import 'posix_path.dart';

void main() {
  test('Windows separators become the POSIX roster spelling', () {
    expect(
      posixPath(r'lib\state\app_share_entry_controller.dart'),
      'lib/state/app_share_entry_controller.dart',
    );
  });

  test('POSIX paths are unchanged', () {
    expect(
      posixPath('lib/state/app_share_entry_controller.dart'),
      'lib/state/app_share_entry_controller.dart',
    );
  });

  test('drive-letter paths become Git-bash and WSL spellings', () {
    const windows = r'C:\Users\aa\AppData\Local\Temp\notes\CHANGELOG.md';
    expect(
      posixShellPath(windows, wsl: false),
      '/c/Users/aa/AppData/Local/Temp/notes/CHANGELOG.md',
    );
    expect(
      posixShellPath(windows, wsl: true),
      '/mnt/c/Users/aa/AppData/Local/Temp/notes/CHANGELOG.md',
    );
  });

  test('WSL mount prefix is not hard-coded to /mnt', () {
    const windows = r'C:\Users\aa\AppData\Local\Temp\notes\CHANGELOG.md';
    expect(
      posixShellPath(windows, wsl: true, wslMountPrefix: '/custom'),
      '/custom/c/Users/aa/AppData/Local/Temp/notes/CHANGELOG.md',
    );
    expect(
      posixShellPath(windows, wsl: true, wslMountPrefix: ''),
      '/c/Users/aa/AppData/Local/Temp/notes/CHANGELOG.md',
    );
  });

  test('relative script paths keep their slash form', () {
    expect(
      posixShellPath('tool/release/release_notes.sh', wsl: false),
      'tool/release/release_notes.sh',
    );
    expect(
      posixShellPath(r'tool\release\release_notes.sh', wsl: true),
      'tool/release/release_notes.sh',
    );
  });
}
