import 'package:flutter/material.dart';

class ActivityDislikeFeedback {
  const ActivityDislikeFeedback({
    required this.reason,
    required this.solution,
  });

  final String reason;
  final String solution;
}

Future<ActivityDislikeFeedback?> showActivityDislikeFeedbackDialog(
  BuildContext context, {
  String title = 'Masukan Perbaikan Kegiatan',
}) async {
  final result = await showDialog<ActivityDislikeFeedback>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _ActivityDislikeFeedbackDialog(title: title),
  );

  // Route dialog menyelesaikan Future saat pop dimulai. Tunggu animasi penutupan
  // selesai sebelum pemanggil me-refresh provider yang dapat membangun ulang
  // widget pembuka dialog.
  await Future<void>.delayed(kThemeAnimationDuration);
  return result;
}

class _ActivityDislikeFeedbackDialog extends StatefulWidget {
  const _ActivityDislikeFeedbackDialog({required this.title});

  final String title;

  @override
  State<_ActivityDislikeFeedbackDialog> createState() =>
      _ActivityDislikeFeedbackDialogState();
}

class _ActivityDislikeFeedbackDialogState
    extends State<_ActivityDislikeFeedbackDialog> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  final _solutionController = TextEditingController();
  bool _isClosing = false;

  @override
  void dispose() {
    _reasonController.dispose();
    _solutionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Dislike harus bersifat konstruktif. Jelaskan masalah dan solusi yang Anda sarankan.',
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _reasonController,
                minLines: 2,
                maxLines: 4,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Alasan tidak menyukai',
                ),
                validator: (value) => (value?.trim().length ?? 0) < 10
                    ? 'Alasan minimal 10 karakter'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _solutionController,
                minLines: 2,
                maxLines: 4,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Saran solusi/perbaikan',
                ),
                validator: (value) => (value?.trim().length ?? 0) < 10
                    ? 'Solusi minimal 10 karakter'
                    : null,
                onFieldSubmitted: (_) => _submit(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isClosing ? null : () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: _isClosing ? null : _submit,
          child: const Text('Kirim Masukan'),
        ),
      ],
    );
  }

  void _submit() {
    if (_isClosing || !(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() => _isClosing = true);
    Navigator.pop(
      context,
      ActivityDislikeFeedback(
        reason: _reasonController.text.trim(),
        solution: _solutionController.text.trim(),
      ),
    );
  }
}
