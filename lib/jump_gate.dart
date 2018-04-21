import 'dart:html';
import 'dart:math' as math;

import 'package:meta/meta.dart';

import 'common.dart';

class JumpGate extends GameObject with DockingPoint {
  static final SIZE = 50.0;

  @override
  double x;

  @override
  double y;

  @override
  double get height => SIZE;

  @override
  double get width => SIZE;

  JumpGate({@required this.x, @required this.y});

  @override
  void draw(CanvasRenderingContext2D renderCtx, GameContext gameCtx) {
    renderCtx.setFillColorRgb(0, 255, 255);
    renderCtx.beginPath();
    renderCtx.arc(centerX, centerY, width / 2, 0, math.pi * 2);
    renderCtx.fill();
  }
}
