import 'dart:html';

import 'package:meta/meta.dart';

import 'common.dart';
import 'star.dart';

class Waypoint extends Object with Draggable, GameObject, Selectable {
  static const SIZE = 10.0;

  final Star star;

  @override
  double x;
  @override
  double y;
  @override
  double get width => SIZE;
  @override
  double get height => SIZE;

  Waypoint({@required this.x, @required this.y, @required this.star}) {
    // Waypoints always start out selected.
    select();
  }

  @override
  // When waypoints get deselected they dissapear.
  void deselect() {
    super.deselect();
    star.waypoints.remove(this);
  }

  @override
  void draw(CanvasRenderingContext2D renderCtx, GameContext gameCtx) {
    drawSelectionCircle(renderCtx);
  }
}
