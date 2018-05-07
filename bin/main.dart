import 'dart:io';

import 'package:dartsicord/dartsicord.dart';

main() {
  final client = new DiscordClient();

  client.onMessage.listen((event) async {
    if (event.message.content.toLowerCase() == 'ping') {
      await event.message.reply('pong');
    }
  });

  client.connect(new File('bin/client_token.txt').readAsStringSync());
}
