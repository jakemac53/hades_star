import 'dart:async';

import 'package:dartsicord/dartsicord.dart';

Future<Message> help(
    MessageCreateEvent event, Iterable<String> queueNames) async {
  var message = new StringBuffer();
  message.writeln('There is one top level command, `!tidy`.');
  message.writeln();
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
  for (var command in ['in', 'out', 'ready', 'ping-afk', 'clear', 'list']) {
    message.writeln('  $command');
  }

  var response = await event.message.reply(message.toString());

  try {
    new Future.delayed(new Duration(seconds: 5), event.message.delete);
  } catch (_) {}
  var timeout = new Duration(seconds: 300);
  new Future.delayed(timeout, response.delete);

  return response;
}
