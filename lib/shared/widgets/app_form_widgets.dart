import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/constants/app_text.dart';
import '../../core/theme/app_palette.dart';

/// Bottom sheet dengan sudut atas membulat, aman dari keyboard.
Future<T?> showAppSheet<T>(BuildContext context, WidgetBuilder builder) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.pal.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: builder,
  );
}

/// Kerangka isi sheet: handle, judul, subjudul, lalu children.
class SheetFrame extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final List<Widget> children;

  const SheetFrame({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.pal.border,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: context.pal.primaryLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: context.pal.outline, width: 0.5),
                  ),
                  child: Icon(icon, color: context.pal.primaryDark),
                ).animate().scale(
                  begin: const Offset(.6, .6),
                  duration: 380.ms,
                  curve: Curves.easeOutBack,
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.title.copyWith(fontSize: 20),
                    ),
                    if (subtitle != null)
                      Text(subtitle!, style: AppTextStyles.caption),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...children
              .animate(interval: 40.ms)
              .fadeIn(duration: 300.ms)
              .slideY(
                begin: .08,
                end: 0,
                duration: 350.ms,
                curve: Curves.easeOutCubic,
              ),
        ],
      ),
    );
  }
}

/// Gaya input seragam. Border & isian diatur di AppTheme (inputDecorationTheme).
InputDecoration appInput(String label, {String? prefix, IconData? icon}) {
  return InputDecoration(
    labelText: label,
    prefixText: prefix,
    prefixIcon: icon == null ? null : Icon(icon, size: 20),
  );
}

/// Field tanggal yang bisa diketuk (membuka date picker lewat onTap).
class DateField extends StatelessWidget {
  final String label;
  final String hint;
  final DateTime? value;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const DateField({
    super.key,
    required this.label,
    required this.hint,
    required this.value,
    required this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: InputDecorator(
        decoration: appInput(label, icon: Icons.event_outlined).copyWith(
          suffixIcon: (value != null && onClear != null)
              ? IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: onClear,
                )
              : null,
        ),
        child: Text(
          value == null
              ? hint
              : DateFormat('d MMMM yyyy', 'id_ID').format(value!),
          style: AppTextStyles.body.copyWith(
            color: value == null ? context.pal.textSecondary : null,
          ),
        ),
      ),
    );
  }
}

Future<DateTime?> pilihTanggalApp(
  BuildContext context, {
  DateTime? initial,
  required DateTime first,
}) {
  return showDatePicker(
    context: context,
    initialDate: initial ?? DateTime.now(),
    firstDate: first,
    lastDate: DateTime(2100),
  );
}
