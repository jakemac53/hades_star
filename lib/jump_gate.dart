import 'dart:html';
import 'dart:math' as math;

import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

import 'common.dart';

part 'jump_gate.g.dart';

@JsonSerializable()
class JumpGate extends GameObject
    with DockingPoint, Selectable, _$JumpGateSerializerMixin {
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

  factory JumpGate.fromJson(Map<String, dynamic> json) =>
      _$JumpGateFromJson(json);

  @override
  void draw(CanvasRenderingContext2D renderCtx, GameContext gameCtx) {
    renderCtx.setFillColorRgb(0, 255, 255);
    renderCtx.beginPath();
    renderCtx.arc(centerX, centerY, width / 2, 0, math.pi * 2);
    renderCtx.fill();

    drawSelectionCircle(renderCtx);
  }
}
