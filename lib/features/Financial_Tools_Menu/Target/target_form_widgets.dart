import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text.dart';
import '../../../core/theme/app_palette.dart';
import '../../../shared/models/wallet_model.dart';
import '../../../shared/widgets/pressable_scale.dart';

// showAppSheet, SheetFrame, appInput, DateField, pilihTanggalApp
// sekarang satu sumber di app_form_widgets (sudah mendukung dark mode).
export '../../../shared/widgets/app_form_widgets.dart';

const kIkonTarget = [
  ('🎮', 'Gaming'),
  ('✈️', 'Liburan'),
  ('🏠', 'Rumah'),
  ('🚗', 'Kendaraan'),
  ('📱', 'Gadget'),
  ('💻', 'Laptop'),
  ('🎓', 'Pendidikan'),
  ('💍', 'Pernikahan'),
  ('🛡️', 'Dana Darurat'),
  ('👟', 'Fashion'),
  ('🎁', 'Hadiah'),
  ('💰', 'Tabungan'),
];

const _teksGelap = Color(0xFF2B1B10);

class TargetImagePicker extends StatelessWidget {
  final ImageProvider? foto; // file lokal atau foto tersimpan
  final String? emoji;
  final VoidCallback onUpload;
  final ValueChanged<String?> onEmoji;
  final VoidCallback? onClear;

  const TargetImagePicker({
    super.key,
    required this.foto,
    required this.emoji,
    required this.onUpload,
    required this.onEmoji,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final adaGambar = foto != null || emoji != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            PressableScale(
              scale: .95,
              child: GestureDetector(
                onTap: onUpload,
                child: AnimatedContainer(
                  duration: 250.ms,
                  width: 92,
                  height: 92,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: pal.primaryLight,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: adaGambar ? AppColors.primary : pal.outline,
                      width: adaGambar ? 1.5 : 0.5,
                    ),
                    image: foto == null
                        ? null
                        : DecorationImage(image: foto!, fit: BoxFit.cover),
                  ),
                  child: foto != null
                      ? null
                      : AnimatedSwitcher(
                          duration: 220.ms,
                          transitionBuilder: (c, a) =>
                              ScaleTransition(scale: a, child: c),
                          child: emoji != null
                              ? Text(
                                  emoji!,
                                  key: ValueKey(emoji),
                                  style: const TextStyle(fontSize: 42),
                                )
                              : Icon(
                                  Icons.add_photo_alternate_outlined,
                                  key: const ValueKey('kosong'),
                                  size: 32,
                                  color: pal.primaryDark,
                                ),
                        ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PressableScale(
                    scale: .96,
                    child: OutlinedButton.icon(
                      onPressed: onUpload,
                      icon: const Icon(Icons.upload_rounded, size: 18),
                      label: const Text('Upload gambar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: pal.primaryDark,
                        side: BorderSide(color: pal.outline, width: 0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  AnimatedSize(
                    duration: 200.ms,
                    alignment: Alignment.topLeft,
                    child: (adaGambar && onClear != null)
                        ? TextButton(
                            onPressed: onClear,
                            child: const Text('Hapus gambar'),
                          )
                        : Padding(
                            padding: const EdgeInsets.only(top: 8, left: 4),
                            child: Text(
                              'Atau pilih ikon di bawah',
                              style: AppTextStyles.caption,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: kIkonTarget.map((e) {
            final sel = emoji == e.$1;
            return Tooltip(
              message: e.$2,
              child: PressableScale(
                scale: .88,
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onEmoji(sel ? null : e.$1);
                  },
                  child: AnimatedContainer(
                    duration: 180.ms,
                    width: 46,
                    height: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: sel
                          ? AppColors.primary.withValues(alpha: 0.25)
                          : pal.field,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: sel ? AppColors.primary : pal.outline,
                        width: sel ? 1.5 : 0.5,
                      ),
                    ),
                    child: AnimatedScale(
                      scale: sel ? 1.18 : 1,
                      duration: 220.ms,
                      curve: Curves.easeOutBack,
                      child: Text(e.$1, style: const TextStyle(fontSize: 22)),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Pilihan wallet berupa chip horizontal (pengganti dropdown).
class WalletChipPicker extends StatelessWidget {
  final String label;
  final List<WalletModel> wallets;
  final String? selectedId;
  final ValueChanged<String> onChanged;

  const WalletChipPicker({
    super.key,
    required this.label,
    required this.wallets,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption),
        const SizedBox(height: 8),
        SizedBox(
          height: 46,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: wallets.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final w = wallets[i];
              final sel = w.id == selectedId;
              final warna = sel ? _teksGelap : pal.textSecondary;
              return PressableScale(
                scale: .95,
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onChanged(w.id);
                  },
                  child: AnimatedContainer(
                    duration: 180.ms,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: sel ? AppColors.primary : pal.field,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: sel ? AppColors.primary : pal.outline,
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(w.type.icon, size: 16, color: warna),
                        const SizedBox(width: 6),
                        Text(
                          w.name,
                          style: AppTextStyles.caption.copyWith(
                            color: warna,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Chip kecil untuk nominal cepat.
class QuickChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const QuickChip({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    return PressableScale(
      scale: .92,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: pal.primaryLight,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: pal.outline, width: 0.5),
          ),
          child: Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: pal.primaryDark,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
