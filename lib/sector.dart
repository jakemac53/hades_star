import 'dart:html';
import 'dart:math' as math;

import 'package:meta/meta.dart';

import 'common.dart';

class Sector extends GameObject {
  static final HEIGHT = WIDTH * math.sqrt(3) / 2;
  static const WIDTH = SIZE * 2;
  static const SIZE = 300.0;

  @override
  double x;

  @override
  double y;

  @override
  double get height => HEIGHT;

  @override
  double get width => WIDTH;

  @override
  void draw(CanvasRenderingContext2D renderCtx, GameContext gameCtx) {
    Position hexCorner(int i) {
      var deg = 60 * i;
      var rad = math.pi / 180 * deg;
      var position = new SimplePosition(
          x: x + SIZE * math.cos(rad), y: y + SIZE * math.sin(rad));
      return new SimplePosition(x: position.x, y: position.y);
    }

    renderCtx.setStrokeColorRgb(255, 255, 255);
    renderCtx.beginPath();
    var start = hexCorner(5);
    renderCtx.moveTo(start.x, start.y);
    for (var point = 0; point < 6; point++) {
      var position = hexCorner(point);
      renderCtx.lineTo(position.x, position.y);
    }
    renderCtx.stroke();
  }

  Sector({@required this.x, @required this.y});
}
