import 'dart:async';
import 'dart:html';
import 'dart:math' as math;

import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

import 'star.dart';

abstract class DockingPoint implements GameObject {
  int get dockingPointOffset => 10;

  Position get dockingPoint =>
      new SimplePosition(x: centerX, y: y + height + dockingPointOffset);
}

abstract class Selectable implements GameObject {
  @JsonKey(ignore: true)
  bool isSelected = false;

  void select() {
    isSelected = true;
  }

  void deselect() {
    isSelected = false;
  }

  void drawSelectionCircle(CanvasRenderingContext2D renderCtx) {
    if (!isSelected) return;
    renderCtx.setStrokeColorRgb(255, 255, 255);
    renderCtx.beginPath();
    renderCtx.arc(centerX, centerY, width / 2 + 8, 0, math.pi * 2);
    var oldLineWidth = renderCtx.lineWidth;
    renderCtx.lineWidth = 6;
    renderCtx.stroke();
    renderCtx.lineWidth = oldLineWidth;
  }
}

abstract class Draggable implements GameObject {
  Stream<Null> startDrag(MouseEvent e, CanvasElement el, GameContext gameCtx) {
    var controller = new StreamController<Null>();
    var startObjectPos = new Point(x, y);
    var startMousePos = e.client;
    var subscriptions = <StreamSubscription>[];
    subscriptions.add(el.onMouseMove.listen((MouseEvent moveEvent) {
      moveEvent.preventDefault();
      var newPos = moveEvent.client;
      var offset =
          new Point(newPos.x - startMousePos.x, newPos.y - startMousePos.y);
      x = startObjectPos.x + offset.x / gameCtx.scale;
      y = startObjectPos.y + offset.y / gameCtx.scale;
      controller.add(null);
    }));
    subscriptions.add(el.onMouseUp.listen((e) {
      e.preventDefault();
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

class FirebaseObject {
  final String firebaseId;
  FirebaseObject(this.firebaseId);
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

bool rectCollide(num x, num y, GameObject object, num scale) {
  x = x / scale;
  y = y / scale;
  var width = object.width / scale;
  var height = object.height / scale;
  if (x < object.x || x > object.x + width) return false;
  if (y < object.y || y > object.y + height) return false;
  return true;
}
