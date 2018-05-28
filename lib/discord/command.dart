import 'dart:async';

import 'package:dartsicord/dartsicord.dart';

import 'feature.dart';

abstract class Command {
  final String abbr;
  final String name;
  final String description;
  final String usage;

  // The parent feature containing this command
  final Feature feature;

  Command(this.name, this.description, this.feature, {this.abbr, this.usage});

  Future<Message> handleEvent(List<String> args, MessageCreateEvent event);
}
