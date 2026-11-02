import 'package:flutter/services.dart';

/// Mengubah 50000 menjadi 50.000 saat mengetik.
class RupiahInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > 12) digits = digits.substring(0, 12);
    if (digits.isEmpty) return const TextEditingValue(text: '');
    final text = formatRibuan(int.parse(digits));
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

String formatRibuan(num value) => value.round().toString().replaceAllMapped(
  RegExp(r'(\d)(?=(\d{3})+$)'),
  (m) => '${m[1]}.',
);
