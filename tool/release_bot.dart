import 'dart:io';
import 'package:path/path.dart' as p;

main() async {
  print('cleaning up old release dirs');
  var existing = Directory('release');
  if (await existing.exists()) {
    await existing.delete(recursive: true);
  }
  await Directory(p.join('release', 'bin')).create(recursive: true);
  print('snapshotting bootstrap script');
  await Process.run('dart', [
    '--snapshot=${p.join('release', 'bin', 'macvault_bootstrap.snapshot')}',
    p.join('bin', 'macvault_bootstrap.dart'),
  ]);
  print('snapshotting main vault script');
  await Process.run('dart', [
    '--snapshot==${p.join('release', 'bin', 'macvault.snapshot')}',
    p.join('bin', 'macvault.dart'),
  ]);
  print('copying dart vm');
  await File(Platform.executable)
      .copy(p.join('release', p.basename(Platform.executable)));
  print('done!');
}
