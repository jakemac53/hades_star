import 'dart:async';
import 'dart:html';

import 'package:meta/meta.dart';

import 'star.dart';

abstract class DockingPoint implements GameObject {
  int get dockingPointOffset => 10;

  Position get dockingPoint =>
      new SimplePosition(x: centerX, y: y + height + dockingPointOffset);
}

abstract class Draggable implements Position {
  Stream<Null> startDrag(MouseEvent e, CanvasElement el, GameContext gameCtx) {
    var controller = new StreamController<Null>();
    var startObjectPos = new Point(x, y);
    var startMousePos = e.client;
    var subscriptions = <StreamSubscription>[];
    subscriptions.add(el.onMouseMove.listen((MouseEvent moveEvent) {
      var newPos = moveEvent.client;
      var offset =
          new Point(newPos.x - startMousePos.x, newPos.y - startMousePos.y);
      x = startObjectPos.x + offset.x / gameCtx.scale;
      y = startObjectPos.y + offset.y / gameCtx.scale;
      controller.add(null);
    }));
    subscriptions.add(el.onMouseUp.listen((_) {
      for (var subscription in subscriptions) {
        subscription.cancel();
      }
      controller.close();
    }));
    return controller.stream;
  }
}

abstract class Drawable {
  void draw(CanvasRenderingContext2D renderCtx, GameContext gameCtx);
}

class GameContext {
  final Star star;
  final double scale;

  GameContext({@required this.star, @required this.scale});
}

abstract class Position {
  double x;
  double y;
}

abstract class Size {
  double get width;
  double get height;
}

abstract class GameObject implements Position, Size, Drawable {
  double get centerX => x + width / 2;
  double get centerY => y + height / 2;
}

class SimplePosition implements Position {
  @override
  double x;
  @override
  double y;

  SimplePosition({@required this.x, @required this.y});
}
