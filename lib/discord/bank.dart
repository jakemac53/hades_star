import 'dart:async';

import 'package:dartsicord/dartsicord.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:firebase/firebase_io.dart' as firebase;

part 'bank.g.dart';

final artifactSalvageValues = [
  160,
  400,
  800,
  1200,
  1600,
  2000,
  2400,
  2400,
];

final profitRatio = 1.5;

final List<num> artifactCoinValues = () {
  var values = <num>[1];
  for (var i = 1; i < artifactSalvageValues.length; i++) {
    var salvageValue = artifactSalvageValues[i];
    var prevSalvageValue = artifactSalvageValues[i - 1];
    var prevCoinValue = values[i - 1];
    var rate = salvageValue * profitRatio / prevSalvageValue;
    values.add(prevCoinValue * rate);
  }
  return values;
}();

final _firebaseIdExpando = new Expando<String>();

class Bank {
  static const commands = const [
    '!new_account',
    '!balance',
    '!transfer',
    '!price',
    '!price_chart'
  ];

  final firebase.FirebaseClient _client;

  final _rootDbUri =
      'https://firestore.googleapis.com/v1beta1/projects/hades-star-a1bff/databases/(default)/documents';

  Bank(this._client);

  Future<Null> handleCommand(
      String command, List<String> args, MessageCreateEvent event) async {
    switch (command) {
      case '!new_account':
        if (event.message.mentions.isNotEmpty) {
          for (var newUser in event.message.mentions) {
            await Account.create(event, newUser, _client, _rootDbUri);
          }
        } else {
          await Account.create(
              event, event.message.author, _client, _rootDbUri);
        }
        break;
      case '!balance':
        Future printBalance(User user) async {
          var account = await Account.get(_client, _rootDbUri, user.id.id);
          if (account == null) {
            await event.message
                .reply('No account found for ${event.author.mention}');
          } else {
            await event.message.reply(
                '${user.mention} your balance is ${account.balance} Weybucks');
          }
        }
        if (event.message.mentions.isNotEmpty) {
          for (var user in event.message.mentions) {
            await printBalance(user);
          }
        } else {
          await printBalance(event.message.author);
        }
        break;
      case '!transfer':
        await Transaction.create(args, event, _client, _rootDbUri);
        break;
      case '!price':
        if (args.length > 2) {
          await event.message.reply(
              'Expected one or two arguments, the lvl of artifact and the amount');
          return;
        }
        var lvl = int.tryParse(args.first);
        if (lvl == null) {
          await event.message.reply(
              'Expected a number (artifact level) but got ${args.first}');
          return;
        }
        var amount = 1;
        if (args.length == 2) {
          amount = int.tryParse(args[1]);
          if (amount == null) {
            await event.message
                .reply('Expected a number of artifacts but got ${args[1]}');
            return;
          }
        }
        var price = amount * artifactCoinValues[lvl - 1];
        await event.message.reply(
            'I recommend a price of ${price.toStringAsFixed(2)} Weybucks '
            'for $amount rs$lvl artifacts');
        break;
      case '!price_chart':
        var message = new StringBuffer('The prices are as follows:');
        message.writeln();
        for (var i = 0; i < artifactCoinValues.length; i++) {
          var price = artifactCoinValues[i].toStringAsFixed(2);
          message.writeln('**rs${i + 1}**: $price Weybucks');
        }
        await event.message.reply(message.toString());
        break;
    }
  }
}

@JsonSerializable()
class Account extends Object with _$AccountSerializerMixin {
  @override
  num balance;

  String get firebaseId => _firebaseIdExpando[this];

  Account({@required this.balance});

  factory Account.fromJson(Map<String, dynamic> data, String id) {
    var account = _$AccountFromJson(data);
    _firebaseIdExpando[account] = '$id';
    return account;
  }

  // Path the to table containing the accounts by id.
  static String get _firebaseDbTable => '/accounts';
  static Uri _firebaseDbUri(String rootDbUri, {String subPath}) =>
      Uri.parse('$rootDbUri$_firebaseDbTable${subPath != null ? subPath : ''}');

  static Future<Account> create(MessageCreateEvent event, User forUser,
      firebase.FirebaseClient client, String rootDbUri) async {
    var userId = forUser.id.id;
    var account = new Account(balance: 100);
    var uri = _firebaseDbUri(rootDbUri)
        .replace(queryParameters: {'documentId': '$userId'});
    await client.post(uri, {
      'fields': account.toJson().map((k, v) {
        return new MapEntry(k, _toFirebaseValue(v));
      })
    });
    _firebaseIdExpando[account] = '$userId';
    await event.message.reply('New account created for ${forUser.mention}, '
        'seeded with ${account.balance} Weybucks');
    return account;
  }

  static Future<Account> get(
      firebase.FirebaseClient client, String rootDbUri, int discordId) async {
    var uri = _firebaseDbUri(rootDbUri, subPath: '/$discordId');
    dynamic result;
    try {
      result = await client.get(uri);
    } on NotFoundException catch (_) {
      return null;
    }
    var account = new Account(
        balance: result['fields']['balance']['doubleValue'] as num ??
            int.tryParse(
                result['fields']['balance']['integerValue'] as String));
    _firebaseIdExpando[account] = '$discordId';
    return account;
  }

  Future<Null> changeBalance(
      num difference, firebase.FirebaseClient client, String rootDbUri) async {
    var uri = _firebaseDbUri(rootDbUri, subPath: '/$firebaseId');
    balance += difference;
    await client.patch(uri, {
      'fields': toJson().map((k, v) {
        return new MapEntry(k, _toFirebaseValue(v));
      })
    });
  }
}

Map<String, dynamic> _toFirebaseValue(dynamic value) {
  if (value is String) {
    return {'stringValue': value};
  } else if (value is num) {
    return {'doubleValue': value};
  } else if (value is bool) {
    return {'booleanValue': value};
  } else if (value == null) {
    return {'nullValue': null};
  } else {
    throw new UnsupportedError('Unsupported value type $value');
  }
}

@JsonSerializable()
class Transaction extends Object with _$TransactionSerializerMixin {
  @override
  final int from;

  @override
  final int to;

  @override
  final num amount;

  @override
  final DateTime date;

  String get firebaseId => _firebaseIdExpando[this];

  Transaction(
      {@required this.from,
      @required this.to,
      @required this.amount,
      @required this.date});

  factory Transaction.fromJson(Map<String, dynamic> data, String id) {
    var transaction = _$TransactionFromJson(data);
    _firebaseIdExpando[transaction] = id;
    return transaction;
  }

  // Path the to table containing the accounts by id.
  static String get _firebaseDbTable => '/transactions';
  static Uri _firebaseDbUri(String rootDbUri) =>
      Uri.parse('$rootDbUri$_firebaseDbTable');

  static Future<Transaction> create(List<String> args, MessageCreateEvent event,
      firebase.FirebaseClient client, String rootDbUri) async {
    if (args.length != 2) {
      await event.message
          .reply('Expected exactly two arguments, an amount and a @mention');
      return null;
    }
    if (event.message.mentions.length != 1) {
      await event.message
          .reply('You must @mention exactly one person to transfer to.');
      return null;
    }
    var amount = double.tryParse(args.first) ?? double.tryParse(args[1]);
    var from = event.message.author;
    var to = event.message.mentions.first;
    var fromAccount = await Account.get(client, rootDbUri, from.id.id);
    if (fromAccount == null) {
      await event.message.reply('${to.mention} does not have an account!\n'
          'They must create on with !new_account.');
      return null;
    }
    var toAccount = await Account.get(client, rootDbUri, to.id.id);
    if (toAccount == null) {
      await event.message.reply('${from.mention} you do not have an account!\n'
          'You must create one with !new_account.');
      return null;
    }

    await event.message.reply(
        'Transferring $amount Weybucks from ${from.mention} to ${to.mention}...');
    var transaction = new Transaction(
        from: from.id.id,
        to: to.id.id,
        amount: amount,
        date: new DateTime.now());
    var result = await client.post(_firebaseDbUri(rootDbUri), {
      'fields': transaction.toJson().map((k, v) {
        return new MapEntry(k, _toFirebaseValue(v));
      })
    });
    _firebaseIdExpando[transaction] = result['name'] as String;
    await toAccount.changeBalance(amount, client, rootDbUri);
    await fromAccount.changeBalance(-amount, client, rootDbUri);
    await event.message.reply('Transaction successful!\n'
        '${from.mention}\'s balance: ${fromAccount.balance} Weybucks\n'
        '${to.mention}\'s balance: ${toAccount.balance} Weybucks');
    return transaction;
  }
}
