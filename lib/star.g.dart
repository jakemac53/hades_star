// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'star.dart';

// **************************************************************************
// Generator: JsonSerializableGenerator
// **************************************************************************

Star _$StarFromJson(Map<String, dynamic> json) => new Star(
    height: (json['height'] as num)?.toDouble(),
    width: (json['width'] as num)?.toDouble(),
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
  Map<String, dynamic> toJson() => <String, dynamic>{
        'firebaseId': firebaseId,
        'name': name,
        'x': x,
        'y': y,
        'height': height,
        'width': width
      };
}
