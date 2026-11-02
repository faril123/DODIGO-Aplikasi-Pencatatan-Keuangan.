import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// Ambil OverlayState SEBELUM menutup sheet, lalu panggil fungsi ini.
void tampilkanConfetti(OverlayState overlay) {
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _ConfettiLayer(onSelesai: () => entry.remove()),
  );
  overlay.insert(entry);
}

class _ConfettiLayer extends StatefulWidget {
  final VoidCallback onSelesai;
  const _ConfettiLayer({required this.onSelesai});

  @override
  State<_ConfettiLayer> createState() => _ConfettiLayerState();
}

class _ConfettiLayerState extends State<_ConfettiLayer> {
  final _controller = ConfettiController(duration: const Duration(seconds: 2));

  @override
  void initState() {
    super.initState();
    _controller.play();
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) widget.onSelesai();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConfettiWidget(
          confettiController: _controller,
          blastDirection: pi / 2,
          blastDirectionality: BlastDirectionality.explosive,
          emissionFrequency: 0.05,
          numberOfParticles: 20,
          gravity: 0.2,
          shouldLoop: false,
          colors: [
            AppColors.primary,
            AppColors.success,
            AppColors.error,
            AppColors.primaryLight,
            Colors.white,
          ],
        ),
      ),
    );
  }
}
