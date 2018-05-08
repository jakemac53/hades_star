import 'dart:async';
import 'dart:io';

import 'package:dartsicord/dartsicord.dart';
import 'package:hades_simulator/discord.dart';

final queues = <String, StarQueue>{
  '!wey-rs5': new RedStarQueue('wey-rs5'),
  '!wey-rs6': new RedStarQueue('wey-rs6'),
  '!wey-rs7': new RedStarQueue('wey-rs7'),
  '!wey-ws': new WhiteStarQueue('wey-ws'),
  '!lotus-rs5': new RedStarQueue('lotus-rs5'),
  '!lotus-rs6': new RedStarQueue('lotus-rs6'),
  '!lotus-ws': new WhiteStarQueue('lotus-ws'),
};

main() async {
  final whiteSpaceRegex = new RegExp(r'\s+');
  final client = new DiscordClient();
  client.onMessage.listen((event) async {
    if (!event.message.content.startsWith('!')) return;
    var args = event.message.content.split(whiteSpaceRegex);
    var command = args[0];
    args.removeAt(0);
    Message message;

    if (command == '!help') {
      message = await help(event);
      new Future.delayed(new Duration(seconds: 60), () async {
        await message.delete();
      });
      try {
        await event.message.delete();
      } catch (_) {}
    } else if (command == '!tidy') {
      await tidy(event, args);
    } else {
      var queue = queues[command];
      if (queue != null) {
        message = await queue.handleCommand(args, event);
        new Future.delayed(new Duration(seconds: 15), () async {
          await message.delete();
        });
      }
    }

    if (message != null) {}
  });

  await client.connect(new File('bin/client_token.txt').readAsStringSync());
}

Future<void> tidy(MessageCreateEvent event, List<String> args) async {
  var deleteCount = args.isEmpty ? 10 : int.tryParse(args.first) ?? 10;
  var channel = event.message.channel;
  var messages = await channel.getMessages(
      limit: deleteCount,
      base: event.message,
      downloadType: MessageDownloadType.before);
  await channel.bulkDeleteMessages(messages.toList()..add(event.message));
}

Future<Message> help(MessageCreateEvent event) {
  var message = new StringBuffer();
  message.writeln('To use a queue, type <queue-name> <command-name>');
  message.writeln();
  message.writeln('The available queues are the following:');
  message.writeln();
  for (var name in queues.keys) {
    message.writeln('  $name');
  }
  message.writeln();
  message.writeln('The available commands are:');
  message.writeln();
  for (var command in ['in', 'out', 'ready', 'ping-afk', 'clear', 'list']) {
    message.writeln('  $command');
  }
  return event.message.reply(message.toString());
}
