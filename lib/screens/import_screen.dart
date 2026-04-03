// lib/screens/import_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../router/app_router.dart';
import '../services/api_service.dart';

class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  final _urlController = TextEditingController();
  bool _isUploading = false;
  String? _uploadError;

  final _api = ApiService();

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _pickFromGallery() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return;

    final file = File(result.files.single.path!);
    await _uploadAndNavigate(file);
  }

  Future<void> _uploadAndNavigate(File file) async {
    setState(() { _isUploading = true; _uploadError = null; });
    try {
      final videoId = await _api.uploadVideo(file);
      if (mounted) {
        context.pushReplacement(AppRoutes.languagePicker, extra: videoId);
      }
    } catch (e) {
      setState(() { _uploadError = 'Erreur lors de l\'upload : $e'; });
    } finally {
      setState(() { _isUploading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(title: const Text('Importer une vidéo')),
      body: _isUploading
          ? const _UploadingIndicator()
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // En-tête
            const Text(
              'Choisissez une source',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Importez depuis votre galerie ou collez un lien vidéo',
              style: TextStyle(fontSize: 14, color: AppColors.textSecond),
            ),
            const SizedBox(height: 32),

            // Option Galerie
            _ImportOption(
              icon: Icons.photo_library_rounded,
              title: 'Galerie locale',
              subtitle: 'MP4, MKV, AVI, MOV, WEBM',
              color: AppColors.primary,
              onTap: _pickFromGallery,
            ),
            const SizedBox(height: 16),

            // Option URL
            _ImportOption(
              icon: Icons.link_rounded,
              title: 'Depuis une URL',
              subtitle: 'YouTube, liens directs',
              color: AppColors.accent,
              onTap: () => _showUrlDialog(context),
            ),

            if (_uploadError != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.error.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: AppColors.error, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _uploadError!,
                        style: const TextStyle(
                            color: AppColors.error, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),
            // Formats supportés
            _SupportedFormats(),
          ],
        ),
      ),
    );
  }

  void _showUrlDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24, right: 24, top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Coller un lien vidéo',
              style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _urlController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'https://youtube.com/watch?v=...',
                hintStyle: const TextStyle(color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.bgSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // TODO: télécharger la vidéo depuis l'URL
              },
              child: const Text('Importer'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ─── Widgets internes ────────────────────────────────────────────────────────

class _ImportOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ImportOption({
    required this.icon, required this.title, required this.subtitle,
    required this.color, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecond)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: color, size: 16),
          ],
        ),
      ),
    );
  }
}

class _UploadingIndicator extends StatelessWidget {
  const _UploadingIndicator();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: 20),
          Text('Upload en cours…',
              style: TextStyle(color: AppColors.textSecond)),
        ],
      ),
    );
  }
}

class _SupportedFormats extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final formats = ['MP4', 'MKV', 'AVI', 'MOV', 'WEBM'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Formats supportés',
            style: TextStyle(fontSize: 12,
                color: AppColors.textMuted, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: formats.map((f) => Chip(
            label: Text(f,
                style: const TextStyle(fontSize: 11,
                    color: AppColors.textSecond)),
            backgroundColor: AppColors.bgSurface,
            side: const BorderSide(color: AppColors.border),
            padding: EdgeInsets.zero,
          )).toList(),
        ),
      ],
    );
  }
}