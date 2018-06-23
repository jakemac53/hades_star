import 'dart:async';
import 'dart:io';

import 'package:dartsicord/dartsicord.dart';
import 'package:firebase/firebase_io.dart' as firebase;
import 'package:hades_simulator/discord.dart';

main() async {
  print('Connecting: ${new DateTime.now()}');
  await run();
  print('Connected: ${new DateTime.now()}');
}

Future<DiscordClient> run() async {
  var dbname = await new File('macvault_db.txt').readAsString();
  final whiteSpaceRegex = new RegExp(r'\s+');
  final client = new DiscordClient();
  final firebaseClient = new firebase.FirebaseClient.anonymous();
  final bank = new Bank(firebaseClient, dbname, 1.0, 75.0,
      new User('macvault', '', new Snowflake(455897532506046467)),
      branchManagerId: 288393614520877057);
  client.onMessage.listen((event) async {
    // Supermoon art bank channel.
    if (event.channel.id.id != 456047681639415819) return;
    // Blargbot
    if (event.author.id.id == 134133271750639616) {
      await event.message.delete();
      return;
    }
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
    } else {
      var message =
          await event.message.reply('Unrecognized command `$command`');
      new Future.delayed(new Duration(seconds: 15), message.delete);
    }
  });

  await client.connect(
      new File('bin/macvault_client_token.txt').readAsLinesSync().first);
  return client;
}
