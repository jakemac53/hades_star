import 'dart:async';

import 'package:dartsicord/dartsicord.dart';

import 'command.dart';

/// A feature is a set of commands that are related to a common task.
abstract class Feature {
  /// The help string for this feature.
  String get help;

  /// The name of this feature.
  String get name;

  /// All the commands supported by this feature.
  List<Command> get commands;

  /// Returns `Future<true>` if [commandName] matches any [commands], otherwise
  /// returns `false`.
  FutureOr<bool> handleCommand(
      String commandName, List<String> args, MessageCreateEvent event) {
    for (var command in commands) {
      if (command.name == commandName || command.abbr == commandName) {
        return command.handleEvent(args, event).then((_) => true);
      }
    }
    return false;
  }
}
