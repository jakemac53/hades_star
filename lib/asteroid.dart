import 'dart:html';

import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

import 'common.dart';

part 'asteroid.g.dart';

final ImageElement _asteroidImage = () {
  return document.getElementById('asteroid') as ImageElement;
}();

@JsonSerializable()
class Asteroid extends FirebaseObject
    with
        Draggable,
        DockingPoint,
        GameObject,
        Selectable,
        _$AsteroidSerializerMixin {
  static const SIZE = 25.0;

  @override
  String tableId(String starId) => '/asteroids/$starId';

  @override
  double x;
  @override
  double y;
  @override
  double get width => SIZE;
  @override
  double get height => SIZE;

  Asteroid({@required this.x, @required this.y, @required String firebaseId})
      : super(firebaseId);

  factory Asteroid.fromJson(Map<String, dynamic> json) =>
      _$AsteroidFromJson(json);

  @override
  void draw(CanvasRenderingContext2D renderCtx, GameContext gameCtx) {
    renderCtx.drawImageScaled(_asteroidImage, x, y, width, height);

    drawSelectionCircle(renderCtx);
  }
}
