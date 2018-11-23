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
  // Artificially inflated
  4800,
  // 2400,
];

final _firebaseIdExpando = new Expando<String>();

class Bank {
  static const commands = const [
    '!new_account',
    '!balance',
    '!transfer',
    '!price',
    '!price_chart',
    '!teller',
    '!banker'
  ];

  final num profitRatio;

  final int branchManagerId;

  final User botUser;

  List<num> get artifactCoinValues {
    var values = <num>[1];
    for (var i = 1; i < artifactSalvageValues.length; i++) {
      var salvageValue = artifactSalvageValues[i];
      var prevSalvageValue = artifactSalvageValues[i - 1];
      var prevCoinValue = values[i - 1];
      var rate = salvageValue * profitRatio / prevSalvageValue;
      values.add(prevCoinValue * rate);
    }
    return values;
  }

  final firebase.FirebaseClient _client;

  final String firebaseProject;

  final num newAccountCredit;

  final Teller teller;

  String get _rootDbUri =>
      'https://firestore.googleapis.com/v1beta1/projects/$firebaseProject/databases/(default)/documents';

  Bank(this._client, this.firebaseProject, this.profitRatio,
      this.newAccountCredit, this.botUser, {this.branchManagerId})
      : teller = new Teller(_client, firebaseProject, botUser,
            branchManagerId: branchManagerId);

  Future<Null> handleCommand(
      String command, List<String> args, MessageCreateEvent event) async {
    switch (command.toLowerCase()) {
      case '!new_account':
        if (event.message.mentions.isNotEmpty) {
          for (var newUser in event.message.mentions) {
            await Account.create(
                event, newUser, _client, _rootDbUri, newAccountCredit);
          }
        } else {
          await Account.create(event, event.message.author, _client, _rootDbUri,
              newAccountCredit);
        }
        break;
      case '!balance':
        Future printBalance(User user) async {
          var account = await Account.get(_client, _rootDbUri, user.id.id);
          if (account == null) {
            await event.message.reply('No account found for ${user.mention}');
          } else {
            await event.message.reply(
                '${user.mention} your balance is ${account.balance} MacBucks');
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
        var lvl = int.tryParse(args.first.toLowerCase().startsWith('rs')
            ? args.first.substring(2)
            : args.first);
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
            'I recommend a price of ${price.toStringAsFixed(2)} MacBucks '
            'for $amount rs$lvl artifacts');
        break;
      case '!price_chart':
        var message = new StringBuffer('The prices are as follows:');
        message.writeln();
        for (var i = 0; i < artifactCoinValues.length; i++) {
          var price = artifactCoinValues[i].toStringAsFixed(2);
          message.writeln('**rs${i + 1}**: $price MacBucks');
        }
        message.writeln('Market rate for all other artifacts.');
        await event.message.reply(message.toString());
        break;
      case '!teller':
        await teller.handleCommand(args.first, args.skip(1).toList(), event);
        break;
      case '!banker':
        await teller.handleBankerCommand(
            args.first, args.skip(1).toList(), event);
        break;
      default:
        var message =
            await event.message.reply('Unrecognized command `$command`');
        new Future.delayed(new Duration(seconds: 15), message.delete);
    }
  }

  Future help(MessageCreateEvent event) async {
    var message = '''
The commands are the following:

- `!new_account`: Creates a new account for yourself. 
- `!balance`: Lists your balance.
- `!transfer @person <amount>`: transfer credits to another person.
- `!price <rs-level> <amount>`: Lists a recommended price for some artifacts. 
- `!price_chart`: Lists the full recommended price chart.

Many of these commands default to the current user, but you can
@mention somebody to make it operate on that user instead. 
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

class Teller {
  final firebase.FirebaseClient _client;
  final String firebaseProject;
  final int branchManagerId;
  final User _botUser;

  String get _rootDbUri =>
      'https://firestore.googleapis.com/v1beta1/projects/$firebaseProject/databases/(default)/documents';

  Teller(this._client, this.firebaseProject, this._botUser,
      {this.branchManagerId});

  Future<Null> handleCommand(
      String command, List<String> args, MessageCreateEvent event) async {
    Message response;
    var timeout = new Duration(seconds: 300);
    switch (command.toLowerCase()) {
      case 'list':
        response = await listRequests(event);
        break;
      case 'request':
        var reply = new StringBuffer();
        if (event.message.mentions.length > 1) {
          reply.write('You can only make a request for one person at a time.');
        } else {
          var requestMessage =
              args.where((arg) => !arg.startsWith('<@')).join(' ');
          var user = event.message.mentions.isNotEmpty
              ? event.message.mentions.first
              : event.author;
          reply.writeln(await newRequest(user, requestMessage,
              branchManagerId: branchManagerId));
        }
        response = await event.message.reply(reply.toString());
        break;
      case 'cancel':
        var message = new StringBuffer();
        if (event.message.mentions.isNotEmpty) {
          for (var user in event.message.mentions) {
            message.writeln(await cancel(user));
          }
        } else {
          message.writeln(await cancel(event.message.author));
        }
        response = await event.message.reply(message.toString());
        break;
      case 'help':
        await help(event);
        return;
        break;
      case 'accounts':
        response = await listAccounts(event);
        break;
      default:
        response = await event.message.reply('Unrecognized command `$command`');
        timeout = new Duration(seconds: 30);
        break;
    }

    if (response != null) {
      try {
        new Future.delayed(new Duration(seconds: 5), event.message.delete);
      } catch (_) {}
      new Future.delayed(timeout, response.delete);
    }
  }

  Future<Null> handleBankerCommand(
      String command, List<String> args, MessageCreateEvent event) async {
    Message response;
    var timeout = new Duration(seconds: 300);
    if (event.author.id.id != branchManagerId) {
      response = await event.message
          .reply('You don\'t have permission to execute this command!');
    } else {
      switch (command.toLowerCase()) {
        case 'transfer':
          await Transaction.create(args, event, _client, _rootDbUri,
              from: _botUser);
          break;
        default:
          response =
              await event.message.reply('Unrecognized command `$command`');
          timeout = new Duration(seconds: 30);
          break;
      }
    }

    if (response != null) {
      try {
        new Future.delayed(new Duration(seconds: 5), event.message.delete);
      } catch (_) {}
      new Future.delayed(timeout, response.delete);
    }
  }

  Future<Message> listAccounts(MessageCreateEvent event) async {
    var accounts = await Account.list(_client, _rootDbUri);
    var message =
        new StringBuffer('Here is a list of all the current account balances:');
    message.writeln('');
    for (var account in accounts) {
      message.writeln('${account.username}: `${account.balance}`');
    }
    return event.message.reply(message.toString());
  }

  Future<Message> listRequests(MessageCreateEvent event) async {
    var requests = await TellerRequest.list(_client, _rootDbUri);
    var message =
        new StringBuffer('There are ${requests.length} pending requests:');
    message.writeln('');
    for (var request in requests) {
      message.writeln('- ${request.username} requested ${request.message}');
    }
    return event.message.reply(message.toString());
  }

  Future<String> newRequest(User user, String message,
      {int branchManagerId}) async {
    var existing = await TellerRequest.get(_client, _rootDbUri, user.id.id);
    if (existing != null) {
      return '${user.mention} already has an outstanding teller request, '
          'you must delete that request before making a new one!';
    } else {
      await TellerRequest.create(user, message, _client, _rootDbUri);
      var branchManagerMention =
          branchManagerId == null ? '' : '<@$branchManagerId>';
      return 'Hey $branchManagerMention! ${user.mention} is requesting $message.';
    }
  }

  Future<String> cancel(User user) async {
    var existing = await TellerRequest.get(_client, _rootDbUri, user.id.id);

    if (existing == null) {
      return 'You have no pending teller request!';
    } else {
      await TellerRequest.delete(_client, _rootDbUri, user.id.id);
      return 'Request cancelled for ${user.mention}!';
    }
  }

  Future help(MessageCreateEvent event) async {
    var message = '''
The teller commands are the following:

- `request <message>`: Creates a request for the teller. You can supply any message. 
- `cancel`: Cancels any existing request you have.
- `list`: Lists all pending teller requests.
- `accounts`: Lists all accounts and their balances.
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
class TellerRequest extends Object with _$TellerRequestSerializerMixin {
  @override
  String username;
  @override
  String message;

  String get firebaseId => _firebaseIdExpando[this];

  TellerRequest({@required this.username, @required this.message});

  factory TellerRequest.fromJson(Map<String, dynamic> data, String id) {
    var request = _$TellerRequestFromJson(data);
    _firebaseIdExpando[request] = '$id';
    return request;
  }

  // Path the to table containing the accounts by id.
  static String get _firebaseDbTable => '/teller_requests';
  static Uri _firebaseDbUri(String rootDbUri, {String subPath}) =>
      Uri.parse('$rootDbUri$_firebaseDbTable${subPath != null ? subPath : ''}');

  static Future<TellerRequest> create(User forUser, String message,
      firebase.FirebaseClient client, String rootDbUri) async {
    var username = forUser.username;
    var userId = forUser.id.id;
    var request = new TellerRequest(username: username, message: message);
    var uri = _firebaseDbUri(rootDbUri)
        .replace(queryParameters: {'documentId': '$userId'});
    await client.post(uri, {
      'fields': request.toJson().map((k, v) {
        return new MapEntry(k, _toFirebaseValue(v));
      })
    });
    _firebaseIdExpando[request] = '$userId';
    return request;
  }

  static Future<List<TellerRequest>> list(
      firebase.FirebaseClient client, String rootDbUri) async {
    var uri = _firebaseDbUri(rootDbUri);
    dynamic result;
    try {
      result = await client.get(uri);
    } on NotFoundException catch (_) {
      return null;
    } on firebase.FirebaseClientException catch (_) {
      return null;
    }
    var docs =
        ((result['documents'] as List) ?? []).cast<Map<String, dynamic>>();
    return docs.map((doc) {
      var request = new TellerRequest(
          username: doc['fields']['username']['stringValue'] as String,
          message: doc['fields']['message']['stringValue'] as String);
      _firebaseIdExpando[request] = (doc['name'] as String).split('/').last;
      return request;
    }).toList();
  }

  static Future<TellerRequest> get(
      firebase.FirebaseClient client, String rootDbUri, int discordId) async {
    var uri = _firebaseDbUri(rootDbUri, subPath: '/$discordId');
    dynamic result;
    try {
      result = await client.get(uri);
    } on NotFoundException catch (_) {
      return null;
    } on firebase.FirebaseClientException catch (_) {
      return null;
    }
    var request = new TellerRequest(
        username: result['fields']['username']['stringValue'] as String,
        message: result['fields']['message']['stringValue'] as String);
    _firebaseIdExpando[request] = '$discordId';
    return request;
  }

  static Future<Null> delete(
      firebase.FirebaseClient client, String rootDbUri, int discordId) async {
    var uri = _firebaseDbUri(rootDbUri, subPath: '/$discordId');
    try {
      await client.delete(uri);
    } on NotFoundException catch (_) {
      return null;
    } on firebase.FirebaseClientException catch (_) {
      return null;
    }
  }
}

@JsonSerializable()
class Account extends Object with _$AccountSerializerMixin {
  @override
  num balance;

  @override
  final String username;

  String get firebaseId => _firebaseIdExpando[this];

  Account({@required this.balance, @required this.username});

  factory Account.fromJson(Map<String, dynamic> data, String id) {
    var account = _$AccountFromJson(data);
    _firebaseIdExpando[account] = '$id';
    return account;
  }

  // Path the to table containing the accounts by id.
  static String get _firebaseDbTable => '/accounts';
  static Uri _firebaseDbUri(String rootDbUri, {String subPath}) =>
      Uri.parse('$rootDbUri$_firebaseDbTable${subPath != null ? subPath : ''}');

  static Future<List<Account>> list(
      firebase.FirebaseClient client, String rootDbUri) async {
    var uri =
        _firebaseDbUri(rootDbUri, subPath: '?pageSize=100&orderBy=balance');
    dynamic result;
    try {
      result = await client.get(uri);
    } on NotFoundException catch (_) {
      return null;
    } on firebase.FirebaseClientException catch (_) {
      return null;
    }
    var docs =
        ((result['documents'] as List) ?? []).cast<Map<String, dynamic>>();
    return docs.map((doc) {
      var account = new Account(
          balance: doc['fields']['balance']['doubleValue'] as num ??
              int.tryParse(doc['fields']['balance']['integerValue'] as String),
          username: doc['fields']['username']['stringValue'] as String);
      _firebaseIdExpando[account] = (doc['name'] as String).split('/').last;
      return account;
    }).toList();
  }

  static Future<Account> create(
      MessageCreateEvent event,
      User forUser,
      firebase.FirebaseClient client,
      String rootDbUri,
      num newAccountCredit) async {
    var userId = forUser.id.id;

    var existing = await Account.get(client, rootDbUri, userId);
    if (existing != null) {
      await event.message
          .reply('Account already exists for ${forUser.mention}');
      return null;
    }

    var account =
        new Account(balance: newAccountCredit, username: forUser.username);
    var uri = _firebaseDbUri(rootDbUri)
        .replace(queryParameters: {'documentId': '$userId'});
    await client.post(uri, {
      'fields': account.toJson().map((k, v) {
        return new MapEntry(k, _toFirebaseValue(v));
      })
    });
    _firebaseIdExpando[account] = '$userId';
    await event.message.reply('New account created for ${forUser.mention}, '
        'seeded with ${account.balance} MacBucks');
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
    } on firebase.FirebaseClientException catch (_) {
      return null;
    }
    var account = new Account(
        balance: result['fields']['balance']['doubleValue'] as num ??
            int.tryParse(result['fields']['balance']['integerValue'] as String),
        username: result['fields']['username']['stringValue'] as String);
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
      firebase.FirebaseClient client, String rootDbUri,
      {User from}) async {
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
    from ??= event.message.author;
    var to = event.message.mentions.first;
    var fromAccount = await Account.get(client, rootDbUri, from.id.id);
    if (fromAccount == null) {
      await event.message.reply('${from.mention} does not have an account!\n'
          'They must create on with !new_account.');
      return null;
    }
    var toAccount = await Account.get(client, rootDbUri, to.id.id);
    if (toAccount == null) {
      await event.message.reply('${to.mention} you do not have an account!\n'
          'You must create one with !new_account.');
      return null;
    }

    var statusMessage = await event.message.reply(
        'Transferring $amount MacBucks from ${from.mention} to ${to.mention}...');
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
    await statusMessage.edit('Transaction successful!\n'
        '${from.mention}\'s balance: ${fromAccount.balance} MacBucks\n'
        '${to.mention}\'s balance: ${toAccount.balance} MacBucks');
    return transaction;
  }
}
