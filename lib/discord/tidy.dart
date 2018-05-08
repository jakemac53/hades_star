import 'dart:async';

import 'package:dartsicord/dartsicord.dart';

Future<void> tidy(MessageCreateEvent event, List<String> args) async {
  var deleteCount = args.isEmpty ? 10 : int.tryParse(args.first) ?? 10;
  var channel = event.message.channel;
  var messages = await channel.getMessages(
      limit: deleteCount,
      base: event.message,
      downloadType: MessageDownloadType.before);
  await channel.bulkDeleteMessages(messages.toList()..add(event.message));
}
