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

    if (command == '!help') {
      await help(event, queues.keys);
    } else if (command == '!tidy') {
      await tidy(event, args);
    } else {
      var queue = queues[command];
      if (queue != null) {
        await queue.handleCommand(args, event);
      }
    }
  });

  await client.connect(new File('bin/client_token.txt').readAsStringSync());
}
