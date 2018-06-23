import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:dartsicord/dartsicord.dart';
import 'package:firebase/firebase_io.dart' as firebase;
import 'package:hades_simulator/discord.dart';

main() async {
  Completer<Null> done;
  while (true) {
    print('Connecting: ${new DateTime.now()}');
    done = new Completer();
    DiscordClient discordClient;

    discordClient = await runZoned(run, onError: (e, s) async {
      if (e is! WebSocketException) {
        print('Uncaught Exception: $e\n$s');
        return;
      }
      try {
        await discordClient?.disconnect();
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
  final firebaseClient = new firebase.FirebaseClient.anonymous();
  // final bank = new Bank(firebaseClient, 'hades-star-a1bff', 1.5, 100,
  //     new User('macvault', '', new Snowflake(455897532506046467)));
  client.onMessage.listen((event) async {
    if (!event.message.content.startsWith('!')) return;
    var args = event.message.content.split(whiteSpaceRegex);
    var command = args[0];
    args.removeAt(0);

    if (command == '!help') {
      // await help(event); //, queues.keys);
    } else if (command == '!tidy') {
      await tidy(event, args);
      // } else if (Bank.commands.contains(command)) {
      //   await bank.handleCommand(command, args, event);
    } else if (command == '!countdown') {
      var time = int.parse(args.first);
      new CountDown(await event.message.reply('$time'), time);
    }
  });

  await client.connect(new File('bin/client_token.txt').readAsStringSync());
  return client;
}

class CountDown {
  final watch = new Stopwatch();
  final Message message;
  final int seconds;
  CountDown(this.message, this.seconds) {
    watch.start();
    updateMessage();
  }

  void updateMessage() async {
    var left = max(seconds - watch.elapsedMilliseconds / 1000, 0);
    await message.edit('${left.ceil()}');
    if (left > 0) {
      new Future.delayed(
          new Duration(milliseconds: max((left % 1000), 500).floor()),
          updateMessage);
    } else {
      // ignore: unawaited_futures
      message.edit('Go!');
    }
  }
}
