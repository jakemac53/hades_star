// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sector.dart';

// **************************************************************************
// Generator: JsonSerializableGenerator
// **************************************************************************

Sector _$SectorFromJson(Map<String, dynamic> json) => new Sector(
    x: (json['x'] as num)?.toDouble(),
    y: (json['y'] as num)?.toDouble(),
    name: json['name'] as String);

abstract class _$SectorSerializerMixin {
  double get x;
  double get y;
  String get name;
  Map<String, dynamic> toJson() =>
      <String, dynamic>{'x': x, 'y': y, 'name': name};
}
