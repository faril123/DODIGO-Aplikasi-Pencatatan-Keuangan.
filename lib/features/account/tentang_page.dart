import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text.dart';
import 'support_widgets.dart';

/// Versi aplikasi dari pubspec.yaml, mis. "1.0.0".
final versiAplikasiProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return info.version;
});

class TentangPage extends ConsumerWidget {
  const TentangPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final versi = ref.watch(versiAplikasiProvider).valueOrNull ?? '-';

    return SupportScaffold(
      title: 'Tentang DODIGI',
      children: [
        const SizedBox(height: 8),
        Center(
          child: Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryLight,
              border: Border.all(color: Colors.black, width: 0.5),
            ),
            child: Icon(
              Icons.account_balance_wallet_outlined,
              size: 38,
              color: AppColors.primaryDark,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            'DODIGI',
            style: AppTextStyles.title.copyWith(fontSize: 22),
          ),
        ),
        Center(child: Text('Versi $versi', style: AppTextStyles.caption)),
        const SizedBox(height: 20),
        SupportCard(
          child: Text(
            'DODIGI membantu kamu mencatat pemasukan dan pengeluaran, memantau budget, membayar tagihan tepat waktu, dan mencapai target tabungan.',
            style: AppTextStyles.body,
          ),
        ),
        const SizedBox(height: 10),
        SupportCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.code, color: AppColors.primaryDark),
                title: const Text('Dibangun dengan'),
                subtitle: const Text('Flutter & Supabase'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.description_outlined,
                  color: AppColors.primaryDark,
                ),
                title: const Text('Lisensi open source'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => showLicensePage(
                  context: context,
                  applicationName: 'DODIGI',
                  applicationVersion: versi,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
