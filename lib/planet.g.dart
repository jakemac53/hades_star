// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'planet.dart';

// **************************************************************************
// Generator: JsonSerializableGenerator
// **************************************************************************

Planet _$PlanetFromJson(Map<String, dynamic> json) => new Planet(
    x: (json['x'] as num)?.toDouble(), y: (json['y'] as num)?.toDouble());

abstract class _$PlanetSerializerMixin {
  double get x;
  double get y;
  Map<String, dynamic> toJson() => <String, dynamic>{'x': x, 'y': y};
}
