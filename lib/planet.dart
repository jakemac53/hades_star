import 'dart:html';

import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

import 'common.dart';

part 'planet.g.dart';

final ImageElement _planetImage = () {
  return document.getElementById('planet') as ImageElement;
}();

@JsonSerializable()
class Planet extends FirebaseObject
    with
        Draggable,
        DockingPoint,
        GameObject,
        Selectable,
        _$PlanetSerializerMixin {
  static const SIZE = 60.0;

  @override
  double x;
  @override
  double y;
  @override
  double get width => SIZE;
  @override
  double get height => SIZE;

  Planet({@required this.x, @required this.y, @required String firebaseId})
      : super(firebaseId);

  factory Planet.fromJson(Map<String, dynamic> json) => _$PlanetFromJson(json);

  @override
  void draw(CanvasRenderingContext2D renderCtx, GameContext gameCtx) {
    renderCtx.drawImageScaled(_planetImage, x, y, width, height);

    drawSelectionCircle(renderCtx);
  }
}
