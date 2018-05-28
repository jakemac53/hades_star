import 'dart:async';

import 'package:dartsicord/dartsicord.dart';

import 'command.dart';
import 'feature.dart';

class QueueFeature extends Feature {
  @override
  String get help => '''
To use a queue, type an action. If there are multiple queues going,
you will need to follow the action with a queue name.

The following actions are available:

- `!new @role`: starts a new queue for the given role
- `!queue` or `!q`: lists the open queues and their members
- `!in` or `!i`: signs you up for a queue
- `!out` or `!out`: removes your from a queue
- `!ready` or `!r`: mark yourself as ready for a queue, all members must be ready before launch
- `!ping-afk` or `!p`: ping unreadied members in the queue
- `!clear` or `!c`: deletes the queue

''';

  @override
  String get name => 'Red/White star queue manager';

  /// Active queues indexed by channel and role id.
  final queues = <int, Map<int, StarQueue>>{};

  @override
  final commands = <Command>[];

  QueueFeature() {
    commands.addAll([
      new NewQueueCommand(this),
    ]);
  }
}

abstract class QueueCommand extends Command {
  QueueCommand(String name, String description, QueueFeature feature,
      {String abbr, String usage})
      : super(name, description, feature, abbr: abbr, usage: usage);

  @override
  QueueFeature get feature => super.feature as QueueFeature;

  StarQueue fetchQueue(MessageCreateEvent event, {Role role}) {
    var channelId = event.channel.id.id;
    var channelQueues =
        feature.queues.putIfAbsent(channelId, () => <int, StarQueue>{});
    if (role == null && channelQueues.values.length == 1) {
      role = channelQueues.values.first.role;
    }
    if (role = null) return null;
    var roleId = role.id.id;
    var queue = channelQueues[roleId];
    return queue;
  }

  StarQueue createQueue(int numPlayers, Role role, MessageCreateEvent event) {
    var channelId = event.channel.id.id;
    var roleId = role.id.id;
    var channelQueues =
        feature.queues.putIfAbsent(channelId, () => <int, StarQueue>{});
    var queue = new StarQueue(role, maxPlayers: 5);
    channelQueues[roleId] = queue;
    return queue;
  }
}

/// Creates a new queue.
class NewQueueCommand extends QueueCommand {
  NewQueueCommand(QueueFeature feature)
      : super('!new', 'starts a new queue for the given role', feature,
            usage: '!new @role <num-players>', abbr: '!n');

  @override
  Future<Message> handleEvent(
      List<String> args, MessageCreateEvent event) async {
    if (event.message.roleMentions.length != 1) {
      await event.message.reply(
          'You must provide exactly one role mention with the !new command.');
      return null;
    }
    var role = event.message.roleMentions.first;

    if (fetchQueue(event, role: role) != null) {
      return event.message
          .reply('An active queue already exists for that role!');
    } else {
      int numPlayers;
      var argsToTry = args.toList();
      while (argsToTry.isNotEmpty && numPlayers == null) {
        numPlayers = int.tryParse(argsToTry.removeAt(0));
      }
      numPlayers ??= 5;
      var queue = createQueue(numPlayers, role, event);
      await queue.signup([event.author], event);
      return queue.list(event);
    }
  }
}

class InQueueCommand extends QueueCommand {
  InQueueCommand(QueueFeature feature)
      : super('!in', 'signs you up for a queue', feature);

  @override
  Future<Message> handleEvent(
      List<String> args, MessageCreateEvent event) async {
    var queue = fetchQueue(event);
    if (queue == null) {}
    var additions = event.message.mentions.isEmpty
        ? [event.author]
        : event.message.mentions;
    return queue.signup(additions, event);
  }
}

class UserSignup {
  final DateTime time;
  final User user;
  bool ready;

  UserSignup(this.user)
      : time = new DateTime.now(),
        ready = false;
}

class StarQueue {
  final Role role;

  final int maxPlayers;

  final signups = <UserSignup>[];

  StarQueue(this.role, {int maxPlayers}) : maxPlayers = maxPlayers ?? 5;

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
            .reply('Unrecognized subcommand for !${role.name} $command $args');
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
    return event.message
        .reply('All users removed from the ${role.name} queue.');
  }

  Future<Message> list(MessageCreateEvent event) {
    var message = new StringBuffer(
        'There are ${signups.length}/$maxPlayers players in the ${role.name} queue:');
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

  Future<Message> signup(List<User> users, MessageCreateEvent event) {
    var message = new StringBuffer();
    for (var toAdd in users) {
      if (signups.length == maxPlayers) {
        message.writeln('Sorry @${toAdd.mention} the queue is full!');
      } else if (signups.any((signup) => signup.user.id.id == toAdd.id.id)) {
        message.writeln('${toAdd.mention} is already in the queue!');
      } else {
        signups.add(new UserSignup(toAdd));
        message.writeln('${toAdd.mention} has been added to the queue!');
      }
    }
    message.writeln(
        'There are now ${signups.length} users in the ${role.name} queue.');
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
