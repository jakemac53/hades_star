// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bank.dart';

// **************************************************************************
// Generator: JsonSerializableGenerator
// **************************************************************************

TellerRequest _$TellerRequestFromJson(Map<String, dynamic> json) =>
    new TellerRequest(username: json['username'] as String);

abstract class _$TellerRequestSerializerMixin {
  String get username;
  Map<String, dynamic> toJson() => <String, dynamic>{'username': username};
}

Account _$AccountFromJson(Map<String, dynamic> json) =>
    new Account(balance: json['balance'] as num);

abstract class _$AccountSerializerMixin {
  num get balance;
  Map<String, dynamic> toJson() => <String, dynamic>{'balance': balance};
}

Transaction _$TransactionFromJson(Map<String, dynamic> json) => new Transaction(
    from: json['from'] as int,
    to: json['to'] as int,
    amount: json['amount'] as num,
    date: json['date'] == null ? null : DateTime.parse(json['date'] as String));

abstract class _$TransactionSerializerMixin {
  int get from;
  int get to;
  num get amount;
  DateTime get date;
  Map<String, dynamic> toJson() => <String, dynamic>{
        'from': from,
        'to': to,
        'amount': amount,
        'date': date?.toIso8601String()
      };
}
