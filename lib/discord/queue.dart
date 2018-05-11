import 'dart:async';

import 'package:dartsicord/dartsicord.dart';

class UserSignup {
  final DateTime time;
  final User user;
  bool ready;

  UserSignup(this.user)
      : time = new DateTime.now(),
        ready = false;
}

class RedStarQueue extends Object with StarQueue {
  @override
  final String name;

  @override
  final maxPlayers = 5;

  RedStarQueue(this.name);
}

class WhiteStarQueue extends Object with StarQueue {
  @override
  final String name;

  @override
  final maxPlayers = 20;

  WhiteStarQueue(this.name);
}

abstract class StarQueue {
  String get name;
  int get maxPlayers;

  final signups = <UserSignup>[];

  Future<Message> handleCommand(
      List<String> args, MessageCreateEvent event) async {
    Message message;
    // Amount of time before the response should be removed.
    var timeout = new Duration(seconds: 30);

    String command;
    if (args.isEmpty) {
      command = 'list';
    } else {
      command = args.removeAt(0);
    }
    switch (command) {
      case 'clear':
        message = await clear(event);
        break;
      case 'in':
        message = await signup(event);
        break;
      case 'out':
        message = await signout(event);
        break;
      case 'l':
      case 'list':
        message = await list(event);
        timeout = new Duration(seconds: 180);
        break;
      case 'ping-afk':
        message = await pingAfk(event);
        break;
      case 'r':
      case 'ready':
        message = await ready(event);
        break;
      default:
        message = await event.message
            .reply('Unrecognized subcommand for !$name $command $args');
        break;
    }

    try {
      new Future.delayed(new Duration(seconds: 5), event.message.delete);
    } catch (_) {}

    new Future.delayed(timeout, message.delete);

    return message;
  }

  Future<Message> clear(MessageCreateEvent event) {
    signups.clear();
    return event.message.reply('All users removed from the $name queue.');
  }

  Future<Message> list(MessageCreateEvent event) {
    var message = new StringBuffer(
        'There are ${signups.length}/$maxPlayers players in the $name queue:');
    for (var signup in signups) {
      var ready = signup.ready ? ':white_check_mark: ' : ':clock1:';
      message.write('\n  - $ready${signup.user.username}');
    }
    return event.message.reply(message.toString());
  }

  Future<Message> pingAfk(MessageCreateEvent event) {
    var message = new StringBuffer();
    for (var waiting in signups.where((s) => !s.ready)) {
      message.write('${waiting.user.mention} ');
    }
    message.write('we are waiting on you ready up!');
    return event.message.reply(message.toString());
  }

  Future<Message> ready(MessageCreateEvent event) {
    var readies = event.message.mentions.isEmpty
        ? [event.author]
        : event.message.mentions;
    var message = new StringBuffer();
    for (var ready in readies) {
      var existing = signups.firstWhere(
          (signup) => signup.user.id.id == ready.id.id,
          orElse: () => null);
      if (existing == null) {
        message.writeln('${ready.mention} was not in the queue.');
      } else if (existing.ready) {
        message.writeln('${ready.mention} was already ready.');
      } else {
        existing.ready = true;
        message.writeln('${ready.mention} is now ready.');
      }
    }
    var readyCount = signups.where((s) => s.ready).length;
    message.writeln(
        '$readyCount/${signups.length} players are ready, waiting on:');
    for (var waiting in signups.where((s) => !s.ready)) {
      message.writeln('  - ${waiting.user.username}');
    }
    return event.message.reply(message.toString());
  }

  Future<Message> signup(MessageCreateEvent event) {
    var additions = event.message.mentions.isEmpty
        ? [event.author]
        : event.message.mentions;
    var message = new StringBuffer();
    for (var toAdd in additions) {
      if (signups.length == maxPlayers) {
        message.writeln('Sorry @${toAdd.mention} the queue is full!');
      } else if (signups.any((signup) => signup.user.id.id == toAdd.id.id)) {
        message.writeln('${toAdd.mention} is already in the queue!');
      } else {
        signups.add(new UserSignup(toAdd));
        message.writeln('${toAdd.mention} has been added to the queue!');
      }
    }
    message
        .writeln('There are now ${signups.length} users in the $name queue.');
    return event.message.reply(message.toString());
  }

  Future<Message> signout(MessageCreateEvent event) {
    var removals = event.message.mentions.isEmpty
        ? [event.author]
        : event.message.mentions;
    var message = new StringBuffer();
    for (var toRemove in removals) {
      var existing = signups.firstWhere(
          (signup) => signup.user.id.id == toRemove.id.id,
          orElse: () => null);
      if (existing == null) {
        message.writeln('${toRemove.mention} was not in the queue.');
      } else {
        signups.remove(existing);
        var by = event.author.id.id == toRemove.id.id
            ? ''
            : ' by ${event.author.mention}';
        message
            .writeln(':x: ${toRemove.mention} was removed from the queue$by.');
      }
    }
    message.writeln('There are now ${signups.length} users in the queue.');
    return event.message.reply(message.toString());
  }
}
