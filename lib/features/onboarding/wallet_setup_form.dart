import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_text.dart';

import '../../shared/models/wallet_model.dart';
import '../../shared/widgets/info_bubble.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/wallet_type_picker.dart';

import '../wallet/wallet_provider.dart';
import 'package:flutter/services.dart';

class WalletSetupForm extends ConsumerStatefulWidget {
  final ValueChanged<WalletModel> onSaved;

  const WalletSetupForm({super.key, required this.onSaved});

  @override
  ConsumerState<WalletSetupForm> createState() => _WalletSetupFormState();
}

class _RibuanInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) {
      return const TextEditingValue(text: '');
    }

    final formatted = digitsOnly.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _WalletSetupFormState extends ConsumerState<WalletSetupForm> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController(text: '0');
  WalletType _type = WalletType.cash;
  bool _saving = false;

  Future<void> _lanjut() async {
    final errors = <String>[];
    final name = _nameController.text.trim();
    final amountText = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final amount = double.tryParse(amountText);

    if (name.isEmpty) errors.add('Nama wallet belum diisi.');
    if (amount == null || amount < 0) errors.add('Saldo awal tidak valid.');

    if (errors.isNotEmpty) {
      showInfoBubble(context, success: false, messages: errors);
      return;
    }

    setState(() => _saving = true);

    try {
      final wallet = WalletModel(
        id: '',
        name: name,
        type: _type,
        initialBalance: amount!,
      );

      await ref.read(walletRepositoryProvider).addWallet(wallet);

      if (!mounted) return;
      showInfoBubble(
        context,
        success: true,
        messages: ['Wallet "$name" berhasil ditambahkan.'],
      );

      widget.onSaved(wallet);

      if (!mounted) return;
      _nameController.clear();
      _amountController.text = '0';
      setState(() => _type = WalletType.cash);
    } catch (e) {
      if (mounted) {
        showInfoBubble(
          context,
          success: false,
          messages: ['Gagal menyimpan: $e'],
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Nama Wallet', style: AppTextStyles.title.copyWith(fontSize: 15)),
        const SizedBox(height: 8),
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            hintText: 'Misal: Dompet Utama, Rekening BCA',
          ),
        ),
        const SizedBox(height: 20),
        Text('Jenis Wallet', style: AppTextStyles.title.copyWith(fontSize: 15)),
        const SizedBox(height: 8),
        WalletTypePicker(
          selected: _type,
          onChanged: (t) => setState(() => _type = t),
        ),
        const SizedBox(height: 20),
        Text('Saldo Awal', style: AppTextStyles.title.copyWith(fontSize: 15)),
        const SizedBox(height: 8),
        TextField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          inputFormatters: [_RibuanInputFormatter()],
          onTap: () {
            _amountController.selection = TextSelection(
              baseOffset: 0,
              extentOffset: _amountController.text.length,
            );
          },
          decoration: const InputDecoration(prefixText: 'Rp '),
        ),
        const SizedBox(height: 6),
        Text(
          'Saldo selanjutnya akan mengikuti transaksi yang kamu catat.',
          style: AppTextStyles.caption,
        ),
        const SizedBox(height: 24),
        PrimaryButton(text: 'Lanjut →', loading: _saving, onPressed: _lanjut),
      ],
    );
  }
}
