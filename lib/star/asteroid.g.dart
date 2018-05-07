// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'asteroid.dart';

// **************************************************************************
// Generator: JsonSerializableGenerator
// **************************************************************************

Asteroid _$AsteroidFromJson(Map<String, dynamic> json) => new Asteroid(
    x: (json['x'] as num)?.toDouble(),
    y: (json['y'] as num)?.toDouble(),
    firebaseId: json['firebaseId'] as String);

abstract class _$AsteroidSerializerMixin {
  String get firebaseId;
  double get x;
  double get y;
  Map<String, dynamic> toJson() =>
      <String, dynamic>{'firebaseId': firebaseId, 'x': x, 'y': y};
}
