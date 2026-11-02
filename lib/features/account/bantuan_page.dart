import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text.dart';
import '../../core/theme/app_palette.dart';
import '../../shared/widgets/pressable_scale.dart';
import 'support_widgets.dart';

const _faq = [
  (
    'Bagaimana cara mencatat transaksi?',
    'Tekan tombol "+" di bar navigasi bawah, isi nominal, kategori, dan wallet, lalu simpan. Kamu juga bisa melampirkan foto bukti.',
  ),
  (
    'Bagaimana saldo dihitung?',
    'Saldo wallet = saldo awal + total semua transaksi di wallet itu. Saldo awal tidak bisa diubah, jadi perubahan saldo selalu lewat transaksi.',
  ),
  (
    'Kenapa wallet tidak bisa dihapus?',
    'Wallet yang masih punya transaksi tidak bisa dihapus supaya riwayatmu tidak rusak. Pindahkan atau hapus transaksinya dulu.',
  ),
  (
    'Bagaimana tagihan rutin bekerja?',
    'Saat tagihan rutin kamu bayar, tagihan bulan berikutnya dibuat otomatis (sampai batas bulan yang kamu atur, atau tanpa batas).',
  ),
  (
    'Bagaimana budget/limit bekerja?',
    'Kamu menetapkan limit pengeluaran per kategori. Progres dihitung dari pengeluaran bulan berjalan, dan kamu diperingatkan saat mendekati 80% atau melebihi limit.',
  ),
  (
    'Kenapa pengingat tidak muncul?',
    'Pastikan pengingat aktif di Akun → Notifikasi dan izin notifikasi diberikan di pengaturan HP. Mode hemat baterai di beberapa HP juga bisa menunda notifikasi.',
  ),
  (
    'Bagaimana streak dihitung?',
    'Streak adalah jumlah hari berturut-turut kamu mencatat minimal satu transaksi. Melewatkan satu hari akan mengulang streak dari awal.',
  ),
];

class BantuanPage extends StatefulWidget {
  const BantuanPage({super.key});

  @override
  State<BantuanPage> createState() => _BantuanPageState();
}

class _BantuanPageState extends State<BantuanPage> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  OutlineInputBorder _border(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final q = _query.trim().toLowerCase();
    final hasil = _faq
        .where(
          (f) =>
              q.isEmpty ||
              f.$1.toLowerCase().contains(q) ||
              f.$2.toLowerCase().contains(q),
        )
        .toList();

    return SupportScaffold(
      title: 'Bantuan & FAQ',
      children: [
        TextField(
          controller: _controller,
          onChanged: (v) => setState(() => _query = v),
          decoration: InputDecoration(
            hintText: 'Cari pertanyaan...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      _controller.clear();
                      setState(() => _query = '');
                    },
                  ),
            filled: true,
            fillColor: pal.field,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            border: _border(pal.border),
            enabledBorder: _border(pal.border),
            focusedBorder: _border(AppColors.primary, width: 1.5),
          ),
        ),
        const SizedBox(height: 14),
        if (hasil.isEmpty)
          SupportCard(
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
            child: Column(
              children: [
                Icon(
                  Icons.search_off_rounded,
                  size: 40,
                  color: pal.primaryDark,
                ),
                const SizedBox(height: 8),
                Text('Tidak ada hasil', style: AppTextStyles.title),
                const SizedBox(height: 2),
                Text(
                  'Coba kata kunci lain, atau hubungi kami di bawah.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          )
        else
          ...hasil.map(
            (f) => Padding(
              // key: supaya status buka/tutup tidak tertukar saat difilter.
              key: ValueKey(f.$1),
              padding: const EdgeInsets.only(bottom: 10),
              child: SupportCard(
                padding: EdgeInsets.zero,
                child: Theme(
                  data: Theme.of(
                    context,
                  ).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 2,
                    ),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    expandedCrossAxisAlignment: CrossAxisAlignment.start,
                    shape: const Border(),
                    collapsedShape: const Border(),
                    iconColor: pal.primaryDark,
                    collapsedIconColor: pal.textSecondary,
                    leading: const SupportIconBox(Icons.help_outline),
                    title: Text(
                      f.$1,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    children: [Text(f.$2, style: AppTextStyles.body)],
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(height: 10),
        _buildKontakCard(context),
      ],
    );
  }

  Widget _buildKontakCard(BuildContext context) {
    const tinta = Color(0xFF2B1B10);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.pal.outline, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.mail_outline_rounded, color: tinta),
              const SizedBox(width: 8),
              Text(
                'Masih butuh bantuan?',
                style: AppTextStyles.title.copyWith(fontSize: 16, color: tinta),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Kirim pertanyaan atau laporan masalah ke email kami.',
            style: AppTextStyles.caption.copyWith(
              color: tinta.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 14),
          PressableScale(
            scale: .97,
            child: FilledButton.icon(
              onPressed: () async {
                HapticFeedback.selectionClick();
                await Clipboard.setData(
                  const ClipboardData(text: emailDukungan),
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Email disalin.')),
                  );
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: tinta,
                foregroundColor: AppColors.primary,
                shape: const StadiumBorder(),
              ),
              icon: const Icon(Icons.copy_rounded, size: 16),
              label: const Text(emailDukungan),
            ),
          ),
        ],
      ),
    );
  }
}
