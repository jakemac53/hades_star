import 'dart:html';
import 'dart:math' as math;

import 'package:meta/meta.dart';

import 'common.dart';

class Planet extends GameObject {
  static const SIZE = 100.0;

  @override
  final double x;
  @override
  final double y;
  @override
  double get width => SIZE;
  @override
  double get height => SIZE;

  Planet({@required this.x, @required this.y});

  @override
  void draw(CanvasRenderingContext2D renderCtx, GameContext gameCtx) {
    renderCtx.setFillColorRgb(255, 0, 0);
    renderCtx.beginPath();
    print(centerX);
    print(centerY);
    print(width / 2);
    renderCtx.arc(centerX, centerY, width / 2, 0, math.pi * 2);
    renderCtx.fill();
  }
}
