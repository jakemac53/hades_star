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
  Completer<Null> done;
  while (true) {
    print('Connecting: ${new DateTime.now()}');
    done = new Completer();
    DiscordClient client;
    client = await runZoned(run, onError: (e) async {
      if (e is! WebSocketException) return;
      try {
        await client?.disconnect();
      } catch (_) {}
      print('Disconnected: ${new DateTime.now()}');
      await new Future.delayed(new Duration(seconds: 15));
      done.complete();
    });
    print('Connected: ${new DateTime.now()}');
    // block until we get errors, then restart the client;
    await done.future;
  }
}

Future<DiscordClient> run() async {
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
  return client;
}
