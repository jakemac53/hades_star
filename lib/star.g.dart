// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'star.dart';

// **************************************************************************
// Generator: JsonSerializableGenerator
// **************************************************************************

Star _$StarFromJson(Map<String, dynamic> json) => new Star(
    planets: (json['planets'] as List)
        ?.map((e) =>
            e == null ? null : new Planet.fromJson(e as Map<String, dynamic>))
        ?.toList(),
    height: (json['height'] as num)?.toDouble(),
    width: (json['width'] as num)?.toDouble(),
    sectors: (json['sectors'] as List)
        ?.map((e) =>
            e == null ? null : new Sector.fromJson(e as Map<String, dynamic>))
        ?.toList(),
    jumpGates: (json['jumpGates'] as List)
        ?.map((e) =>
            e == null ? null : new JumpGate.fromJson(e as Map<String, dynamic>))
        ?.toList(),
    firebaseId: json['firebaseId'] as String,
    name: json['name'] as String)
  ..x = (json['x'] as num)?.toDouble()
  ..y = (json['y'] as num)?.toDouble();

abstract class _$StarSerializerMixin {
  String get firebaseId;
  String get name;
  double get x;
  double get y;
  double get height;
  double get width;
  List<Planet> get planets;
  List<Sector> get sectors;
  List<JumpGate> get jumpGates;
  Map<String, dynamic> toJson() => <String, dynamic>{
        'firebaseId': firebaseId,
        'name': name,
        'x': x,
        'y': y,
        'height': height,
        'width': width,
        'planets': planets,
        'sectors': sectors,
        'jumpGates': jumpGates
      };
}
