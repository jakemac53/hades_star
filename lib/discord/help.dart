import 'dart:async';

import 'package:dartsicord/dartsicord.dart';

Future<Message> help(MessageCreateEvent event) async {
  var message = new StringBuffer();
  message
    ..writeln('**GENERAL COMMANDS**')
    ..writeln()
    ..writeln('`!tidy <num-lines>`')
    ..writeln()
    ..writeln('  - Deletes <num-lines> from this channel.')
    ..writeln()
    ..writeln('**BANKING COMMANDS**')
    ..writeln()
    ..writeln('`!new_account`')
    ..writeln()
    ..writeln('  - Creates a new account in the bank for yourself.')
    ..writeln()
    ..writeln('`!transfer <amount> @user`')
    ..writeln()
    ..writeln('  - Transfers <amount> from your account to @user. '
        'Both users must have an account.')
    ..writeln()
    ..writeln('`!price <artifact-level> <amount>`')
    ..writeln()
    ..writeln(
        '  - Recommends a price for <amount> rs<artifact-level> artifacts.')
    ..writeln(
        '    Prices are based on rs1 arts being worth one coin, with a 150% '
        'profit margin for each tier upgrade.')
    ..writeln()
    ..writeln('`!price_chart`')
    ..writeln()
    ..writeln('  - Lists all the recommended prices.')
    ..writeln()
    ..writeln('**QUEUE COMMANDS**');

  var response = await event.message.reply(message.toString());

  try {
    new Future.delayed(new Duration(seconds: 5), event.message.delete);
  } catch (_) {}
  var timeout = new Duration(seconds: 300);
  new Future.delayed(timeout, response.delete);

  return response;
}
