import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/post_model.dart';
import '../../services/database_service.dart';

class CreatePostScreen extends StatefulWidget {
  final String username;

  const CreatePostScreen({
    super.key,
    required this.username,
  });

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final DatabaseService _db = DatabaseService.instance;
  final ImagePicker _picker = ImagePicker();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _descCtrl = TextEditingController();
  final FocusNode _descFocus = FocusNode();

  File? _selectedImage;
  bool _saving = false;
  bool _descriptionTouched = false;

  String get _imageStatusLabel {
    return _selectedImage == null
        ? 'Selector de imagen. No hay imagen seleccionada.'
        : 'Selector de imagen. Imagen seleccionada.';
  }

  Future<void> _pickImage() async {
    if (_saving) return;

    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (picked == null) {
        if (!mounted) return;
        SemanticsService.announce(
          'Selección de imagen cancelada.',
          Directionality.of(context),
          assertiveness: Assertiveness.assertive,
        );
        return;
      }

      setState(() {
        _selectedImage = File(picked.path);
      });

      if (!mounted) return;
      SemanticsService.announce(
        'Imagen seleccionada correctamente.',
        Directionality.of(context),
        assertiveness: Assertiveness.assertive,
      );
    } catch (_) {
      if (!mounted) return;
      SemanticsService.announce(
        'Error al seleccionar la imagen.',
        Directionality.of(context),
        assertiveness: Assertiveness.assertive,
      );

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('No se pudo seleccionar la imagen.'),
          ),
        );
    }
  }

  void _announceError(String message) {
    if (!mounted) return;
    SemanticsService.announce(message, Directionality.of(context), assertiveness: Assertiveness.assertive);
  }

  Future<void> _save() async {
    if (_saving) return;

    setState(() {
      _descriptionTouched = true;
    });

    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      _descFocus.requestFocus();
      _announceError('Error. La descripción es obligatoria.');
      return;
    }

    setState(() {
      _saving = true;
    });

    _announceError('Publicando post.');

    try {
      await _db.createPost(
        PostModel(
          user: widget.username,
          imagePath: _selectedImage?.path ?? 'placeholder',
          description: _descCtrl.text.trim(),
          date: DateTime.now().toIso8601String(),
          likes: 0,
        ),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Semantics(
              liveRegion: true,
              child: const Text('Publicación creada correctamente.'),
            ),
          ),
        );

      SemanticsService.announce(
        'Publicación creada correctamente.',
        Directionality.of(context),
        assertiveness: Assertiveness.assertive,
      );

      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _saving = false;
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Semantics(
              liveRegion: true,
              child: const Text('Error al publicar la publicación.'),
            ),
          ),
        );

      _announceError('Error al publicar la publicación.');
    }
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _descFocus.dispose();
    super.dispose();
  }

  Widget _buildImageSelector() {
    final hasImage = _selectedImage != null;

    return Semantics(
      button: true,
      image: true,
      label: _imageStatusLabel,
      hint: hasImage
          ? 'Doble toque para cambiar la imagen.'
          : 'Doble toque para seleccionar una imagen.',
      child: InkWell(
        onTap: _pickImage,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 180),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black12),
            color: Colors.grey.shade100,
          ),
          child: hasImage
              ? ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.file(
              _selectedImage!,
              height: 220,
              width: double.infinity,
              fit: BoxFit.cover,
              excludeFromSemantics: true,
              errorBuilder: (context, error, stackTrace) {
                return SizedBox(
                  height: 220,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      ExcludeSemantics(
                        child: Icon(Icons.broken_image_outlined, size: 56),
                      ),
                      SizedBox(height: 8),
                      ExcludeSemantics(
                        child: Text('No se pudo mostrar la imagen'),
                      ),
                    ],
                  ),
                );
              },
            ),
          )
              : SizedBox(
            height: 180,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                ExcludeSemantics(
                  child: Icon(Icons.add_photo_alternate_outlined, size: 56),
                ),
                SizedBox(height: 10),
                ExcludeSemantics(
                  child: Text('Seleccionar imagen'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Descripción *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descCtrl,
          focusNode: _descFocus,
          maxLines: 4,
          textInputAction: TextInputAction.done,
          autovalidateMode: _descriptionTouched
              ? AutovalidateMode.onUserInteraction
              : AutovalidateMode.disabled,
          decoration: const InputDecoration(
            hintText: 'Escribe una descripción para tu publicación',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
          onChanged: (_) {
            if (!_descriptionTouched) {
              setState(() {
                _descriptionTouched = true;
              });
            }
          },
          validator: (value) {
            final text = value?.trim() ?? '';
            if (text.isEmpty) {
              return 'La descripción es obligatoria';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPublishButton() {
    return Semantics(
      button: true,
      enabled: !_saving,
      label: _saving ? 'Publicando publicación' : 'Publicar publicación',
      hint: _saving
          ? 'Espera a que termine la publicación'
          : 'Doble toque para publicar',
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _saving ? null : _save,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
          ),
          child: _saving
              ? Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              ),
              SizedBox(width: 12),
              Text('Publicando...'),
            ],
          )
              : const Text('Publicar'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo post'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildImageSelector(),
                const SizedBox(height: 20),
                _buildDescriptionField(),
                const SizedBox(height: 20),
                _buildPublishButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}