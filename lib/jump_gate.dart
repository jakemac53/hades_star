import 'dart:html';

import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

import 'common.dart';

part 'jump_gate.g.dart';

final ImageElement _jumpGateImage = () {
  return document.getElementById('jump_gate') as ImageElement;
}();

@JsonSerializable()
class JumpGate extends FirebaseObject
    with DockingPoint, GameObject, Selectable, _$JumpGateSerializerMixin {
  static final SIZE = 50.0;

  @override
  double x;

  @override
  double y;

  @override
  double get height => SIZE;

  @override
  double get width => SIZE;

  JumpGate({@required this.x, @required this.y, @required String firebaseId})
      : super(firebaseId);

  factory JumpGate.fromJson(Map<String, dynamic> json) =>
      _$JumpGateFromJson(json);

  @override
  void draw(CanvasRenderingContext2D renderCtx, GameContext gameCtx) {
    renderCtx.drawImageScaled(_jumpGateImage, x, y, width, height);

    drawSelectionCircle(renderCtx);
  }
}
