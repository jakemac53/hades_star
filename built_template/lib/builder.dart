import 'dart:async';

import 'package:build/build.dart';

TemplateBuilder createBuilder(BuilderOptions options) => new TemplateBuilder();

class TemplateBuilder extends Builder {
  @override
  final buildExtensions = const {
    '.template': const ['']
  };

  @override
  Future build(BuildStep buildStep) async {
    var content = await buildStep.readAsString(buildStep.inputId);
    var matches = _regex.allMatches(content);
    var output = new StringBuffer();
    var lastEnd = 0;
    for (var match in matches) {
      output.write(content.substring(lastEnd, match.start));
      var group = match.group(0);
      // remove the braces
      group = group.substring(2, group.length - 2).trim();
      // get the command
      var parts = group.split(' ');
      if (parts.length != 2) {
        log.severe('Invalid template tag ${match.group(0)}.\n'
            'Expected a command followed by a value like {{command value}}.');
        return null;
      }
      var command = parts.first;
      var value = parts.last;
      switch (command) {
        case 'digest':
          var id = new AssetId.resolve(value, from: buildStep.inputId);
          output.write(await buildStep.digest(id));
          break;
        default:
          log.severe('Unrecognized template command: $command');
      }
      lastEnd = match.end;
    }
    output.write(content.substring(lastEnd, content.length));

    await buildStep.writeAsString(
        buildStep.inputId.changeExtension(''), output.toString());
  }
}

final _regex = new RegExp('{{([^{}]+)}}', multiLine: true);
