import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../shared/models/target_model.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../core/utils/rupiah_input_formatter.dart';
import 'target_form_widgets.dart';
import 'target_provider.dart';

class TargetEditSheet extends ConsumerStatefulWidget {
  final TargetModel target;
  const TargetEditSheet({super.key, required this.target});

  @override
  ConsumerState<TargetEditSheet> createState() => _TargetEditSheetState();
}

class _TargetEditSheetState extends ConsumerState<TargetEditSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  final _picker = ImagePicker();
  DateTime? _deadline;
  File? _gambar;
  String? _emoji;
  String? _urlFoto; // foto yang sudah tersimpan di Storage
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final t = widget.target;
    _titleController = TextEditingController(text: t.title);
    _amountController = TextEditingController(
      text: formatRibuan(t.targetAmount),
    );
    _deadline = t.deadline;
    final url = t.imageUrl;
    if (url != null && url.isNotEmpty) {
      if (url.startsWith('emoji:')) {
        _emoji = url.substring(6);
      } else {
        _urlFoto = url;
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  // ignore: unused_element
  bool get _adaGambar => _gambar != null || _emoji != null || _urlFoto != null;

  Future<void> _pilihGambar() async {
    final x = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 80,
    );
    if (x != null) {
      setState(() {
        _gambar = File(x.path);
        _emoji = null;
        _urlFoto = null;
      });
    }
  }

  Future<void> _pilihDeadline() async {
    final hasil = await pilihTanggalApp(
      context,
      initial: _deadline,
      first: DateTime.now().subtract(const Duration(days: 365)),
    );
    if (hasil != null) setState(() => _deadline = hasil);
  }

  Future<void> _simpan() async {
    final title = _titleController.text.trim();
    final amount =
        double.tryParse(
          _amountController.text.replaceAll(RegExp(r'[^0-9]'), ''),
        ) ??
        0;

    if (title.isEmpty || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama dan nominal target wajib diisi.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final repo = ref.read(targetRepositoryProvider);
      final String? imageUrl;
      if (_gambar != null) {
        imageUrl = await repo.uploadGambar(_gambar!);
      } else if (_emoji != null) {
        imageUrl = 'emoji:$_emoji';
      } else {
        imageUrl = _urlFoto;
      }

      await repo.updateTarget(
        widget.target,
        title: title,
        targetAmount: amount,
        deadline: _deadline,
        imageUrl: imageUrl,
      );
      ref.invalidate(targetsProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan perubahan: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider? foto;
    if (_gambar != null) {
      foto = FileImage(_gambar!);
    } else if (_urlFoto != null) {
      foto = NetworkImage(_urlFoto!);
    }

    return SheetFrame(
      title: 'Edit Target',
      subtitle: widget.target.title,
      children: [
        TargetImagePicker(
          foto: foto,
          emoji: _emoji,
          onUpload: _pilihGambar,
          onEmoji: (e) => setState(() {
            _emoji = e;
            if (e != null) {
              _gambar = null;
              _urlFoto = null;
            }
          }),
          onClear: () => setState(() {
            _gambar = null;
            _emoji = null;
            _urlFoto = null;
          }),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _titleController,
          textCapitalization: TextCapitalization.sentences,
          decoration: appInput('Nama target', icon: Icons.flag_outlined),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          inputFormatters: [RupiahInputFormatter()],
          decoration: appInput(
            'Nominal target',
            prefix: 'Rp ',
            icon: Icons.payments_outlined,
          ),
        ),
        const SizedBox(height: 12),
        DateField(
          label: 'Tenggat waktu',
          hint: 'Tanpa batas waktu (opsional)',
          value: _deadline,
          onTap: _pilihDeadline,
          onClear: () => setState(() => _deadline = null),
        ),
        const SizedBox(height: 20),
        PrimaryButton(
          text: 'Simpan Perubahan',
          loading: _saving,
          onPressed: _simpan,
        ),
      ],
    );
  }
}
