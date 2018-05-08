import 'dart:async';

import 'package:dartsicord/dartsicord.dart';

Future<Message> help(MessageCreateEvent event, Iterable<String> queueNames) {
  var message = new StringBuffer();
  message.writeln('To use a queue, type <queue-name> <command-name>');
  message.writeln();
  message.writeln('The available queues are the following:');
  message.writeln();
  for (var name in queueNames) {
    message.writeln('  $name');
  }
  message.writeln();
  message.writeln('The available commands are:');
  message.writeln();
  for (var command in ['in', 'out', 'ready', 'ping-afk', 'tidy', 'list']) {
    message.writeln('  $command');
  }
  return event.message.reply(message.toString());
}
