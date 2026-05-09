import 'package:flutter/material.dart';

class EditProfileResult {
  final String name;
  final String bio;

  const EditProfileResult({required this.name, required this.bio});
}

class EditProfileDialog extends StatefulWidget {
  final String title;
  final String nameLabel;
  final String bioLabel;
  final String cancelLabel;
  final String saveLabel;
  final String initialName;
  final String initialBio;

  const EditProfileDialog({
    super.key,
    required this.title,
    required this.nameLabel,
    required this.bioLabel,
    required this.cancelLabel,
    required this.saveLabel,
    required this.initialName,
    required this.initialBio,
  });

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _bioController;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _bioController = TextEditingController(text: widget.initialBio);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _close([EditProfileResult? result]) async {
    if (_closing) return;
    _closing = true;
    FocusManager.instance.primaryFocus?.unfocus();
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: widget.nameLabel),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bioController,
              decoration: InputDecoration(labelText: widget.bioLabel),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => _close(), child: Text(widget.cancelLabel)),
        ElevatedButton(
          onPressed: () {
            _close(
              EditProfileResult(
                name: _nameController.text.trim(),
                bio: _bioController.text.trim(),
              ),
            );
          },
          child: Text(widget.saveLabel),
        ),
      ],
    );
  }
}
