import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../auth/providers/auth_repository.dart';
import '../providers/settings_provider.dart';
import '../../../core/services/analytics_service.dart';

/// Widget pre upload a zobrazenie firemného loga
class LogoUploadWidget extends ConsumerStatefulWidget {
  const LogoUploadWidget({super.key});

  @override
  ConsumerState<LogoUploadWidget> createState() => _LogoUploadWidgetState();
}

class _LogoUploadWidgetState extends ConsumerState<LogoUploadWidget> {
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  Future<void> _pickAndUploadLogo() async {
    final user = ref.read(authStateProvider).asData?.value;
    if (user == null) return;

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );

    if (pickedFile == null) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('users')
          .child(user.id)
          .child('company_logo.png');

      UploadTask uploadTask;

      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        uploadTask = storageRef.putData(
          bytes,
          SettableMetadata(contentType: 'image/png'),
        );
      } else {
        uploadTask = storageRef.putFile(
          File(pickedFile.path),
          SettableMetadata(contentType: 'image/png'),
        );
      }

      uploadTask.snapshotEvents.listen((event) {
        setState(() {
          _uploadProgress = event.bytesTransferred / event.totalBytes;
        });
      });

      await uploadTask;
      final downloadUrl = await storageRef.getDownloadURL();

      // Update settings with new logo URL
      final currentSettings = ref.read(settingsProvider).asData?.value;
      if (currentSettings != null) {
        final updatedSettings = currentSettings.copyWith(
          companyLogoUrl: downloadUrl,
        );
        await ref
            .read(settingsControllerProvider.notifier)
            .updateSettings(updatedSettings);
        ref.read(analyticsServiceProvider).logLogoUploaded();
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Logo úspešne nahrané')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Chyba pri nahrávaní: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Future<void> _removeLogo() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Odstrániť logo?'),
        content: const Text('Naozaj chcete odstrániť firemné logo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Zrušiť'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Odstrániť'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final currentSettings = ref.read(settingsProvider).asData?.value;
    if (currentSettings != null) {
      final updatedSettings = currentSettings.copyWith(companyLogoUrl: null);
      await ref
          .read(settingsControllerProvider.notifier)
          .updateSettings(updatedSettings);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider).asData?.value;
    final logoUrl = settings?.companyLogoUrl;
    final hasLogo = logoUrl != null && logoUrl.isNotEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.business, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Firemné logo',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                // Logo preview
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withValues(alpha: 0.3),
                    ),
                  ),
                  child: hasLogo
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            logoUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.broken_image, size: 32),
                          ),
                        )
                      : const Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 32,
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasLogo ? 'Logo nahrané' : 'Žiadne logo',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Odporúčaná veľkosť: 512x512 px',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                      if (_isUploading) ...[
                        const SizedBox(height: 8),
                        LinearProgressIndicator(value: _uploadProgress),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isUploading ? null : _pickAndUploadLogo,
                    icon: const Icon(Icons.upload),
                    label: Text(hasLogo ? 'Zmeniť' : 'Nahrať'),
                  ),
                ),
                if (hasLogo) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _isUploading ? null : _removeLogo,
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Odstrániť logo',
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
