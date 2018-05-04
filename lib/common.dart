import 'dart:async';
import 'dart:html';
import 'dart:math' as math;

import 'package:firebase/firebase.dart' as firebase;
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

abstract class FirebaseObject {
  final String firebaseId;

  /// Gives the table name for this object based on [starId].
  String tableId(String starId);

  FirebaseObject(this.firebaseId);

  /// Updates an object in the database.
  ///
  /// If [starId] is present then the objects are stored at
  /// `/$tableId/$starId/$firebaseId`, otherwise they are stored at
  ///  `/$tableId/$firebaseId`.
  Future<void> updateFirebase(firebase.Database db, String starId) {
    var ref = db.ref(tableId(starId)).child(firebaseId);
    return ref.set(toJson());
  }

  Map<String, dynamic> toJson();
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

int computeDistance(Position from, Position to) {
  var xDiff = from.x - to.x;
  var yDiff = from.y - to.y;
  return math.sqrt(math.pow(xDiff.abs(), 2) + math.pow(yDiff.abs(), 2)).round();
}

bool rectCollide(num x, num y, GameObject object) {
  var extraSize = 30;
  var checkWidth = object.width + extraSize;
  var checkHeight = object.height + extraSize;
  var checkX = object.x - extraSize / 2;
  var checkY = object.y - extraSize / 2;
  if (x < checkX || x > checkX + checkWidth) return false;
  if (y < checkY || y > checkY + checkHeight) return false;
  return true;
}
