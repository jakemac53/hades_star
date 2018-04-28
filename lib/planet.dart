import 'dart:html';
import 'dart:math' as math;

import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

import 'common.dart';

part 'planet.g.dart';

@JsonSerializable()
class Planet extends GameObject
    with Draggable, DockingPoint, Selectable, _$PlanetSerializerMixin {
  static const SIZE = 60.0;

  @override
  double x;
  @override
  double y;
  @override
  double get width => SIZE;
  @override
  double get height => SIZE;

  Planet({@required this.x, @required this.y});

  factory Planet.fromJson(Map<String, dynamic> json) => _$PlanetFromJson(json);

  @override
  void draw(CanvasRenderingContext2D renderCtx, GameContext gameCtx) {
    renderCtx.setFillColorRgb(255, 0, 0);
    renderCtx.setStrokeColorRgb(255, 0, 0);
    renderCtx.beginPath();
    renderCtx.arc(centerX, centerY, width / 2, 0, math.pi * 2);
    renderCtx.fill();

    if (isSelected) {
      renderCtx.setStrokeColorRgb(255, 255, 255);
      renderCtx.beginPath();
      renderCtx.arc(centerX, centerY, width / 2 + 8, 0, math.pi * 2);
      var oldLineWidth = renderCtx.lineWidth;
      renderCtx.lineWidth = 6;
      renderCtx.stroke();
      renderCtx.lineWidth = oldLineWidth;
    }
  }
}
