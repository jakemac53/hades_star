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
  var dbname = await new File('bin/macvault_db.txt').readAsString();
  final whiteSpaceRegex = new RegExp(r'\s+');
  final client = new DiscordClient();
  final firebaseClient = new firebase.FirebaseClient.anonymous();
  final bank = new Bank(firebaseClient, dbname, 1.0, 300.0,
      new User('macvault', '', new Snowflake(455897532506046467)));
  client.onMessage.listen((event) async {
    var supportedChannels = [
      456047681639415819,
      519133051788197888,
    ];
    // Supermoon art bank channel.
    if (!supportedChannels.contains(event.channel.id.id)) return;
    // Blargbot
    if (event.author.id.id == 134133271750639616) {
      await event.message.delete();
      return;
    }
    if (!event.message.content.startsWith('!')) return;
    var args = event.message.content.split(whiteSpaceRegex);
    var command = args[0].toLowerCase();
    args.removeAt(0);
    // Allow a space between the `!` and the next command.
    if (command == '!') {
      command += args[0].toLowerCase();
      args.removeAt(0);
    }

    if (command == '!help') {
      await bank.help(event);
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
