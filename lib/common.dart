import 'dart:html';

import 'package:meta/meta.dart';

import 'star.dart';

abstract class Drawable {
  void draw(CanvasRenderingContext2D renderCtx, GameContext gameCtx);
}

class GameContext {
  final Star star;
  final double scale;

  GameContext({@required this.star, @required this.scale});
}

abstract class Position {
  double get x;
  double get y;
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
  final double x;
  @override
  final double y;

  SimplePosition({@required this.x, @required this.y});
}
