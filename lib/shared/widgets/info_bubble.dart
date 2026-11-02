import 'package:flutter/material.dart';

import '../../core/constants/app_text.dart';
import '../../core/theme/app_palette.dart';

void showInfoBubble(
  BuildContext context, {
  required bool success,
  required List<String> messages,
}) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;

  entry = OverlayEntry(
    builder: (context) => _InfoBubbleWidget(
      success: success,
      messages: messages,
      onDone: () => entry.remove(),
    ),
  );

  overlay.insert(entry);
}

class _InfoBubbleWidget extends StatefulWidget {
  final bool success;
  final List<String> messages;
  final VoidCallback onDone;

  const _InfoBubbleWidget({
    required this.success,
    required this.messages,
    required this.onDone,
  });

  @override
  State<_InfoBubbleWidget> createState() => _InfoBubbleWidgetState();
}

class _InfoBubbleWidgetState extends State<_InfoBubbleWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _scale = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    _controller.forward();
    Future.delayed(const Duration(milliseconds: 2000), () async {
      if (!mounted) return;
      await _controller.reverse();
      widget.onDone();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.success ? context.pal.success : context.pal.error;
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 20,
      right: 20,
      child: ScaleTransition(
        scale: _scale,
        child: FadeTransition(
          opacity: _opacity,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.pal.card,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: color.withValues(alpha: 0.4)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    widget.success ? Icons.check_circle : Icons.error_outline,
                    color: color,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.success ? 'Berhasil!' : 'Belum bisa disimpan',
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        ...widget.messages.map(
                          (m) => Text(m, style: AppTextStyles.caption),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
