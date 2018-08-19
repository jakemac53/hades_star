// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sector.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Sector _$SectorFromJson(Map<String, dynamic> json) {
  return Sector(
      x: (json['x'] as num)?.toDouble(),
      y: (json['y'] as num)?.toDouble(),
      name: json['name'] as String,
      firebaseId: json['firebaseId'] as String);
}

abstract class _$SectorSerializerMixin {
  String get firebaseId;
  double get x;
  double get y;
  String get name;
  Map<String, dynamic> toJson() =>
      <String, dynamic>{'firebaseId': firebaseId, 'x': x, 'y': y, 'name': name};
}
