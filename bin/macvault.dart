import 'dart:async';
import 'dart:io';

import 'package:dartsicord/dartsicord.dart';
import 'package:firebase/firebase_io.dart' as firebase;
import 'package:hades_simulator/discord.dart';

main() async {
  Completer<Null> done;
  while (true) {
    print('Connecting: ${new DateTime.now()}');
    done = new Completer();
    DiscordClient discordClient;

    discordClient = await runZoned(run, onError: (e) async {
      if (e is! WebSocketException) {
        print(e);
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
  final bank = new Bank(firebaseClient, 'macvault-5e930');
  client.onMessage.listen((event) async {
    if (!event.message.content.startsWith('!')) return;
    var args = event.message.content.split(whiteSpaceRegex);
    var command = args[0];
    args.removeAt(0);

    if (command == '!help') {
      await bank.help(event);
    } else if (command == '!tidy') {
      await tidy(event, args);
    } else if (Bank.commands.contains(command)) {
      await bank.handleCommand(command, args, event);
    }
  });

  await client.connect(
      new File('bin/macvault_client_token.txt').readAsLinesSync().first);
  return client;
}
