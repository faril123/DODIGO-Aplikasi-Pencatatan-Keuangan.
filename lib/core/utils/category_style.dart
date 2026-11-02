import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

const Color accentOrange = Color(0xFFFF8A3D);
const Color accentTeal = Color(0xFF2EC4B6);
const Color accentPink = Color(0xFFE8637E);
const Color accentBrown = Color(0xFFB5651D);
const Color accentBlue = Color(0xFF4A90D9);

Color categoryColor(String category) {
  switch (category) {
    case 'Makanan':
      return accentBrown;
    case 'Transportasi':
      return accentBlue;
    case 'Belanja':
      return accentPink;
    case 'Tagihan':
    case 'Cicilan':
    case 'Langganan':
      return accentTeal;
    case 'Tabungan':
    case 'Gaji':
    case 'Freelance':
    case 'Bonus':
      return AppColors.success;
    default:
      return AppColors.primaryDark;
  }
}

IconData categoryIcon(String category) {
  switch (category) {
    case 'Makanan':
      return Icons.restaurant;
    case 'Transportasi':
      return Icons.directions_car_outlined;
    case 'Belanja':
      return Icons.shopping_bag_outlined;
    case 'Tagihan':
      return Icons.receipt_long_outlined;
    case 'Cicilan':
      return Icons.credit_card_outlined;
    case 'Langganan':
      return Icons.subscriptions_outlined;
    case 'Tabungan':
      return Icons.savings_outlined;
    case 'Gaji':
      return Icons.payments_outlined;
    case 'Freelance':
      return Icons.work_outline;
    case 'Bonus':
      return Icons.card_giftcard;
    default:
      return Icons.receipt_long_outlined;
  }
}
