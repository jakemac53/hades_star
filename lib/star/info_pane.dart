import 'dart:html';

import 'package:meta/meta.dart';

import 'common.dart';

class InfoPane {
  final HtmlElement parent;

  InfoPane({@required this.parent});

  void renderPathDetails(List<Position> path) {
    parent.children.clear();
    if (path.length < 2) return;
    path = path.toList();

    var distance = 0;
    var last = path.removeLast();
    while (path.isNotEmpty) {
      var next = path.removeLast();
      var from = last is DockingPoint ? last.dockingPoint : last;
      var to = next is DockingPoint ? next.dockingPoint : next;
      distance += computeDistance(from, to);
      last = next;
    }

    parent.children
        .add(new HeadingElement.h2()..text = 'Distance: ${distance}au');
    var table = new TableElement();
    var columnCount = ships.length + 1;
    var rowCount = twModifiers.length + 1;
    for (var r = 0; r < rowCount; r++) {
      var tr = table.addRow();
      for (var c = 0; c < columnCount; c++) {
        var tc = tr.addCell();
        if (r == 0) {
          if (c == 0) continue;
          tc.text = ships[c - 1].name;
        } else {
          if (c == 0) {
            tc.text = 'TW${r-1}';
          } else {
            var ship = ships[c - 1];
            var tw = twModifiers[r - 1];
            var time = distance / ship.speed / tw;
            tc.text = '${time.toStringAsFixed(2)}h';
          }
        }
      }
    }
    parent.children.add(table);
  }
}

final ships = [
  new _Ship('battleship', 60),
  new _Ship('miner', 43),
  new _Ship('rocket', 132),
  new _Ship('transport', 57)
];

final twModifiers = [1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7, 1.8, 1.9, 2.0, 2.1];

class _Ship {
  // Name of the ship.
  final String name;

  // Speed in AU.
  final int speed;

  _Ship(this.name, this.speed);
}
