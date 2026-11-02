import 'package:flutter/material.dart';

enum WalletType { cash, bank, ewallet }

extension WalletTypeX on WalletType {
  String get value => switch (this) {
    WalletType.cash => 'cash',
    WalletType.bank => 'bank',
    WalletType.ewallet => 'ewallet',
  };

  String get label => switch (this) {
    WalletType.cash => 'Cash',
    WalletType.bank => 'Bank',
    WalletType.ewallet => 'E-Wallet',
  };

  IconData get icon => switch (this) {
    WalletType.cash => Icons.payments_outlined,
    WalletType.bank => Icons.account_balance_outlined,
    WalletType.ewallet => Icons.smartphone_outlined,
  };

  static WalletType fromValue(String value) {
    return WalletType.values.firstWhere((t) => t.value == value);
  }
}

class WalletModel {
  final String id;
  final String name;
  final WalletType type;
  final double initialBalance;

  const WalletModel({
    required this.id,
    required this.name,
    required this.type,
    required this.initialBalance,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      id: json['id'] as String,
      name: json['name'] as String,
      type: WalletTypeX.fromValue(json['type'] as String),
      initialBalance: (json['initial_balance'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toInsertJson({required String userId}) {
    return {
      'user_id': userId,
      'name': name,
      'type': type.value,
      'initial_balance': initialBalance,
    };
  }
}
