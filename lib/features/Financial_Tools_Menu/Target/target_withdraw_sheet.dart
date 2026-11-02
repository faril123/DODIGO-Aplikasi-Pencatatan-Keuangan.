import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_text.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/theme/app_palette.dart';
import '../../../shared/models/target_model.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../transaction/transaction_provider.dart';
import '../../wallet/wallet_provider.dart';
import '../../../core/utils/rupiah_input_formatter.dart';
import 'target_form_widgets.dart';
import 'target_detail_sheet.dart';
import 'target_provider.dart';

class TargetWithdrawSheet extends ConsumerStatefulWidget {
  final TargetModel target;
  const TargetWithdrawSheet({super.key, required this.target});

  @override
  ConsumerState<TargetWithdrawSheet> createState() =>
      _TargetWithdrawSheetState();
}

class _TargetWithdrawSheetState extends ConsumerState<TargetWithdrawSheet> {
  final _amountController = TextEditingController();
  String? _walletId;
  bool _saving = false;

  double get _amount =>
      double.tryParse(
        _amountController.text.replaceAll(RegExp(r'[^0-9]'), ''),
      ) ??
      0;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    final amount =
        double.tryParse(
          _amountController.text.replaceAll(RegExp(r'[^0-9]'), ''),
        ) ??
        0;

    if (_walletId == null) {
      _snack('Pilih wallet tujuan dulu.');
      return;
    }
    if (amount <= 0) {
      _snack('Nominal harus lebih dari 0.');
      return;
    }
    if (amount > widget.target.currentAmount) {
      _snack(
        'Maksimal ${formatRupiah(widget.target.currentAmount)} yang bisa ditarik.',
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await ref
          .read(targetRepositoryProvider)
          .tarikDana(widget.target, amount, _walletId!);
      ref.invalidate(targetsProvider);
      ref.invalidate(transactionsProvider);
      ref.invalidate(targetDepositsProvider(widget.target.id));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _snack('Gagal menarik dana: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  @override
  Widget build(BuildContext context) {
    final t = widget.target;
    final lebih = _amount > t.currentAmount;

    return SheetFrame(
      title: 'Tarik Dana',
      subtitle: '${t.title} • terkumpul ${formatRupiah(t.currentAmount)}',
      icon: Icons.north_east_rounded,
      children: [
        TextField(
          controller: _amountController,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [RupiahInputFormatter()],
          onChanged: (_) => setState(() {}),
          decoration: appInput(
            'Nominal ditarik',
            prefix: 'Rp ',
            icon: Icons.payments_outlined,
          ),
        ),
        AnimatedSize(
          duration: 200.ms,
          alignment: Alignment.topLeft,
          child: lebih
              ? Padding(
                  padding: const EdgeInsets.only(top: 8, left: 4),
                  child: Text(
                    'Maksimal ${formatRupiah(t.currentAmount)}',
                    style: AppTextStyles.caption.copyWith(
                      color: context.pal.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: [
            QuickChip(
              label: 'Tarik semua',
              onTap: () {
                _amountController.text = formatRibuan(t.currentAmount);
                setState(() {});
              },
            ),
          ],
        ),
        const SizedBox(height: 14),
        Consumer(
          builder: (context, ref, _) {
            final walletsAsync = ref.watch(walletsProvider);
            return walletsAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Gagal memuat wallet: $e'),
              data: (wallets) {
                if (wallets.isEmpty) {
                  return Text(
                    'Belum ada wallet.',
                    style: AppTextStyles.caption,
                  );
                }
                _walletId ??= wallets.first.id;
                return WalletChipPicker(
                  label: 'Masukkan ke',
                  wallets: wallets,
                  selectedId: _walletId,
                  onChanged: (id) => setState(() => _walletId = id),
                );
              },
            );
          },
        ),
        const SizedBox(height: 20),
        PrimaryButton(text: 'Tarik Dana', loading: _saving, onPressed: _simpan),
      ],
    );
  }
}
