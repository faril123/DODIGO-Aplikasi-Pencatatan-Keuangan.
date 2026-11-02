import 'package:flutter/material.dart';

class AppCategory {
  final String label;
  final IconData icon;

  const AppCategory(this.label, this.icon);
}

class AppCategories {
  AppCategories._();

  static const expense = [
    AppCategory('Makanan', Icons.restaurant),
    AppCategory('Transportasi', Icons.directions_car_outlined),
    AppCategory('Belanja', Icons.shopping_bag_outlined),
    AppCategory('Tagihan', Icons.receipt_long_outlined),
    AppCategory('Cicilan', Icons.credit_card_outlined),
    AppCategory('Langganan', Icons.subscriptions_outlined),
    AppCategory('Lainnya', Icons.more_horiz),
  ];

  static const income = [
    AppCategory('Gaji', Icons.payments_outlined),
    AppCategory('Freelance', Icons.work_outline),
    AppCategory('Bonus', Icons.card_giftcard),
    AppCategory('Lainnya', Icons.more_horiz),
  ];
}
