import 'dart:html';
import 'dart:math' as math;

import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

import 'common.dart';

part 'sector.g.dart';

@JsonSerializable()
class Sector extends FirebaseObject with GameObject, _$SectorSerializerMixin {
  static final HEIGHT = WIDTH * math.sqrt(3) / 2;
  static const WIDTH = SIZE * 2;
  static const SIZE = 250.0;

  @override
  String tableId(String starId) => '/sectors/$starId';

  @override
  double x;

  @override
  double y;

  @override
  double get height => HEIGHT;

  @override
  double get width => WIDTH;

  @override
  final String name;

  Sector(
      {@required this.x,
      @required this.y,
      @required this.name,
      @required String firebaseId})
      : super(firebaseId);

  factory Sector.fromJson(Map<String, dynamic> json) => _$SectorFromJson(json);

  @override
  void draw(CanvasRenderingContext2D renderCtx, GameContext gameCtx) {
    Position hexCorner(int i) {
      var deg = 60 * i;
      var rad = math.pi / 180 * deg;
      var position =
          new Point(x + SIZE * math.cos(rad), y + SIZE * math.sin(rad));
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

    renderCtx.font = '75px sans-serif';
    if (name.endsWith('1')) {
      renderCtx.setFillColorRgb(259, 69, 0);
    } else if (name.endsWith('2')) {
      renderCtx.setFillColorRgb(244, 164, 66);
    } else if (name.endsWith('3')) {
      renderCtx.setFillColorRgb(242, 239, 62);
    } else if (name.endsWith('4')) {
      renderCtx.setFillColorRgb(57, 229, 65);
    } else if (name.endsWith('5')) {
      renderCtx.setFillColorRgb(61, 127, 219);
    } else if (name.endsWith('6')) {
      renderCtx.setFillColorRgb(149, 57, 214);
    } else if (name.endsWith('7')) {
      renderCtx.setFillColorRgb(71, 17, 109);
    }
    renderCtx.fillText(name, x - 130, y - 150);
  }
}
