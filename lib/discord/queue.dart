import 'package:dartsicord/dartsicord.dart';

class RedStarQueue extends Object with StarQueue {
  @override
  final name;

  @override
  final maxPlayers = 5;

  RedStarQueue(this.name);
}

class WhiteStarQueue extends Object with StarQueue {
  @override
  final name;

  @override
  final maxPlayers = 20;

  WhiteStarQueue(this.name);
}

abstract class StarQueue {
  String get name;
  int get maxPlayers;

  final users = <User>[];

  void clear(MessageCreateEvent event) {
    users.clear();
    event.message.reply('All users removed from the $name queue.');
  }

  void list(MessageCreateEvent event) {
    var message = new StringBuffer(
        'There are ${users.length}/$maxPlayers players in the $name queue:');
    for (var user in users) {
      message.write('\n  - ${user.username}');
    }
    event.message.reply(message.toString());
  }

  void signup(MessageCreateEvent event) {
    var additions = event.message.mentions.isEmpty
        ? [event.author]
        : event.message.mentions;
    var message = new StringBuffer();
    for (var toAdd in additions) {
      if (users.length == maxPlayers) {
        message.writeln('Sorry @${toAdd.mention} the queue is full!');
        return;
      } else if (users.any((user) => user.id.id == toAdd.id.id)) {
        message.writeln('${toAdd.mention} is already in the queue!');
        return;
      } else {
        users.add(toAdd);
        message.writeln('${toAdd.mention} has been added to the queue!');
      }
    }
    message.writeln('There are now ${users.length} users in the $name queue.');
    event.message.reply(message.toString());
  }

  void signout(MessageCreateEvent event) {
    var removals = event.message.mentions.isEmpty
        ? [event.author]
        : event.message.mentions;
    var message = new StringBuffer();
    for (var toRemove in removals) {
      var existing = users.firstWhere((user) => user.id.id == toRemove.id.id,
          orElse: () => null);
      if (existing == null) {
        message.writeln('${toRemove.mention} was not in the queue.');
      } else {
        users.remove(existing);
        var by = event.author.id.id == toRemove.id.id
            ? ''
            : ' by ${event.author.mention}';
        message.writeln('${toRemove.mention} was removed from the queue$by.');
      }
    }
    message.writeln('There are now ${users.length} users in the queue.');
    event.message.reply(message.toString());
  }
}
