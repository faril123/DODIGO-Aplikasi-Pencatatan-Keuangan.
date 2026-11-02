import 'package:flutter/material.dart';

import '../../core/constants/app_text.dart';
import 'support_widgets.dart';

const _bagian = [
  (
    Icons.inventory_2_outlined,
    'Data yang kami simpan',
    'Nama, email, dan foto profil dari akun Google yang kamu pakai untuk masuk. Data keuangan yang kamu catat: transaksi, wallet, tagihan, target, dan budget. Foto yang kamu unggah, seperti bukti transaksi atau gambar target.',
  ),
  (
    Icons.insights_outlined,
    'Untuk apa data dipakai',
    'Data dipakai hanya untuk menampilkan dan menghitung catatan keuanganmu (saldo, laporan, budget) serta menjadwalkan pengingat.',
  ),
  (
    Icons.cloud_outlined,
    'Penyimpanan',
    'Datamu disimpan di server Supabase dan terhubung ke akun Google-mu. Kamu perlu masuk dengan akun yang sama untuk melihatnya.',
  ),
  (
    Icons.notifications_none,
    'Notifikasi',
    'Pengingat dijadwalkan langsung di HP-mu. Isinya dibuat dari data di perangkat dan tidak dikirim lewat server pihak ketiga.',
  ),
  (
    Icons.verified_user_outlined,
    'Berbagi data',
    'Kami tidak menjual datamu dan tidak membagikannya untuk keperluan iklan.',
  ),
  (
    Icons.gavel_outlined,
    'Hak kamu',
    'Kamu bisa keluar kapan saja lewat menu Akun. Untuk menghapus akun beserta seluruh datanya, hubungi kami lewat email di bawah.',
  ),
];

class PrivasiPage extends StatelessWidget {
  const PrivasiPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SupportScaffold(
      title: 'Kebijakan Privasi',
      children: [
        const SupportBanner(
          icon: Icons.shield_outlined,
          title: 'Datamu aman bersamamu',
          subtitle: 'Terakhir diperbarui: Oktober 2026',
        ),
        const SizedBox(height: 14),
        ..._bagian.map(
          (b) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SupportCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SupportIconBox(b.$1),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          b.$2,
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(b.$3, style: AppTextStyles.body),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text(
            'Pertanyaan tentang privasi? Hubungi $emailDukungan',
            textAlign: TextAlign.center,
            style: AppTextStyles.caption,
          ),
        ),
      ],
    );
  }
}
