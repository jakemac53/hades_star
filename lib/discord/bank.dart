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
  static const commands = const ['!new_account', '!balance', '!transfer'];

  final firebase.FirebaseClient _client;

  final String firebaseProject;

  String get _rootDbUri =>
      'https://firestore.googleapis.com/v1beta1/projects/$firebaseProject/databases/(default)/documents';

  Bank(this._client, this.firebaseProject);

  Future<Null> handleCommand(
      String command, List<String> args, MessageCreateEvent event) async {
    switch (command) {
      case '!new_account':
        await Account.create(event, _client, _rootDbUri);
        break;
      case '!balance':
        var account =
            await Account.get(_client, _rootDbUri, event.author.id.id);
        if (account == null) {
          await event.message
              .reply('No account found for ${event.author.mention}');
        } else {
          await event.message.reply(
              '${event.author.mention} your balance is ${account.balance}');
        }
        break;
      case '!transfer':
        var transfer =
            await Transaction.create(args, event, _client, _rootDbUri);
        if (transfer != null) {
          await event.message.reply('Transaction successful!');
        }
    }
  }

  Future help(MessageCreateEvent event) async {
    var message = '''
The commands are the following:

- `!new_account`: Creates a new account for yourself. 
- `!balance`: Lists your balance.
- `!transfer @person <amount>`: transfer credits to another person
''';

    var response = await event.message.reply(message);

    try {
      new Future.delayed(new Duration(seconds: 5), event.message.delete);
    } catch (_) {}
    var timeout = new Duration(seconds: 300);
    new Future.delayed(timeout, response.delete);

    return response;
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

  static Future<Account> create(MessageCreateEvent event,
      firebase.FirebaseClient client, String rootDbUri) async {
    var author = event.message.author.id.id;
    var account = new Account(balance: 100);
    var uri = _firebaseDbUri(rootDbUri)
        .replace(queryParameters: {'documentId': '$author'});
    await client.post(uri, {
      'fields': account.toJson().map((k, v) {
        return new MapEntry(k, _toFirebaseValue(v));
      })
    });
    _firebaseIdExpando[account] = '$author';
    await event.message
        .reply('New account created for ${event.message.author.mention}, '
            'seeded with ${account.balance}');
    return account;
  }

  static Future<Account> get(
      firebase.FirebaseClient client, String rootDbUri, int discordId) async {
    var uri = _firebaseDbUri(rootDbUri, subPath: '/$discordId');
    var result = await client.get(uri);
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
    return transaction;
  }
}
