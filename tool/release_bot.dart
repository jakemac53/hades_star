import 'dart:io';
import 'package:path/path.dart' as p;

main(List<String> args) async {
  var outputPath = 'release';
  if (args.length == 1) {
    outputPath = args.first;
  } else if (args.length > 1) {
    throw 'Only expected on arg, the relase dir!';
  }
  print('cleaning up old release dirs');
  var outputDir = Directory(outputPath);
  if (await outputDir.exists()) {
    await outputDir.delete(recursive: true);
  }
  await Directory(p.join(outputDir.path, 'bin')).create(recursive: true);
  print('snapshotting bootstrap script');
  await Process.run('dart', [
    '--snapshot=${p.join(outputDir.path, 'bin', 'macvault_bootstrap.dart.snapshot')}',
    p.join('bin', 'macvault_bootstrap.dart'),
  ]);
  print('snapshotting main vault script');
  await Process.run('dart', [
    '--snapshot=${p.join(outputDir.path, 'bin', 'macvault.dart.snapshot')}',
    p.join('bin', 'macvault.dart'),
  ]);
  print('copying dart vm and secrets');
  await File(Platform.executable)
      .copy(p.join(outputDir.path, p.basename(Platform.executable)));
  await File(p.join('bin', 'macvault_client_token.txt'))
      .copy(p.join(outputDir.path, 'bin', 'macvault_client_token.txt'));
  await File(p.join('bin', 'macvault_db.txt'))
      .copy(p.join(outputDir.path, 'bin', 'macvault_db.txt'));
  print('done!');
}
