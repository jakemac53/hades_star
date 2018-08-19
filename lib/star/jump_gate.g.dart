// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'jump_gate.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

JumpGate _$JumpGateFromJson(Map<String, dynamic> json) {
  return JumpGate(
      x: (json['x'] as num)?.toDouble(),
      y: (json['y'] as num)?.toDouble(),
      firebaseId: json['firebaseId'] as String);
}

abstract class _$JumpGateSerializerMixin {
  String get firebaseId;
  double get x;
  double get y;
  Map<String, dynamic> toJson() =>
      <String, dynamic>{'firebaseId': firebaseId, 'x': x, 'y': y};
}
