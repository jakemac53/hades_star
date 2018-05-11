import 'dart:async';

import 'package:dartsicord/dartsicord.dart';

Future<void> tidy(MessageCreateEvent event, List<String> args) async {
  var deleteCount = args.isEmpty ? 10 : int.tryParse(args.first) ?? 10;
  var channel = event.message.channel;
  var messages = await channel.getMessages(
      limit: deleteCount,
      base: event.message,
      downloadType: MessageDownloadType.before);
  try {
    await channel.bulkDeleteMessages(messages.toList());
    new Future.delayed(new Duration(seconds: 2), event.message.delete);
  } catch (_) {
    await event.message
        .reply('Unable to delete messages, please check permissions.');
  }
}
