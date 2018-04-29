import 'dart:html';
import 'dart:math' as math;

import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

import 'common.dart';

part 'asteroid.g.dart';

@JsonSerializable()
class Asteroid extends GameObject
    with Draggable, DockingPoint, Selectable, _$AsteroidSerializerMixin
    implements FirebaseObject {
  static const SIZE = 25.0;

  @override
  final String firebaseId;
  @override
  double x;
  @override
  double y;
  @override
  double get width => SIZE;
  @override
  double get height => SIZE;

  Asteroid({@required this.x, @required this.y, @required this.firebaseId});

  factory Asteroid.fromJson(Map<String, dynamic> json) =>
      _$AsteroidFromJson(json);

  @override
  void draw(CanvasRenderingContext2D renderCtx, GameContext gameCtx) {
    renderCtx.setFillColorRgb(255, 0, 255);
    renderCtx.setStrokeColorRgb(255, 0, 255);
    renderCtx.beginPath();
    renderCtx.arc(centerX, centerY, width / 2, 0, math.pi * 2);
    renderCtx.fill();

    drawSelectionCircle(renderCtx);
  }
}
