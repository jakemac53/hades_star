import 'dart:async';
import 'dart:io';

import 'package:dartsicord/dartsicord.dart';
import 'package:hades_simulator/discord.dart';

final queues = <String, StarQueue>{
  '!lotus-rs5': new RedStarQueue('lotus-rs5'),
  '!lotus-rs6': new RedStarQueue('lotus-rs6'),
  '!wey-rs5': new RedStarQueue('wey-rs5'),
  '!wey-rs6': new RedStarQueue('wey-rs6'),
  '!wey-rs7': new RedStarQueue('wey-rs7'),
  '!wey-ws': new WhiteStarQueue('wey-ws'),
};

main() async {
  final whiteSpaceRegex = new RegExp(r'\s+');
  final client = new DiscordClient();
  client.onMessage.listen((event) async {
    if (!event.message.content.startsWith('!')) return;
    var args = event.message.content.split(whiteSpaceRegex);
    var command = args[0];
    args.removeAt(0);

    var queue = queues[command];
    if (queue != null) {
      await handleRsCommand(args, event, queue);
    }
  });

  await client.connect(new File('bin/client_token.txt').readAsStringSync());
}

Future handleRsCommand(
    List<String> args, MessageCreateEvent event, StarQueue queue) async {
  var command = args[0];
  args.removeAt(0);
  switch (command) {
    case 'clear':
      queue.clear(event);
      break;
    case 'in':
      queue.signup(event);
      break;
    case 'out':
      queue.signout(event);
      break;
    case 'list':
      queue.list(event);
      break;
    default:
      await event.message
          .reply('Unrecognized subcommand for !${queue.name} $command $args');
      break;
  }
}
