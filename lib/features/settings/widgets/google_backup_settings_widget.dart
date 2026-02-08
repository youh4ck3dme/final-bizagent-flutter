import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../shared/utils/biz_snackbar.dart';
import '../../backup/services/backup_service.dart';
import '../../backup/services/google_drive_service.dart';

class GoogleBackupSettingsWidget extends ConsumerStatefulWidget {
  const GoogleBackupSettingsWidget({super.key});

  @override
  ConsumerState<GoogleBackupSettingsWidget> createState() =>
      _GoogleBackupSettingsWidgetState();
}

class _GoogleBackupSettingsWidgetState
    extends ConsumerState<GoogleBackupSettingsWidget> {
  bool _isConnected = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initial check (silent sign in or provider state)
    _checkConnection();
  }

  Future<void> _checkConnection() async {
    // This is a simple check, in a real app might want a stream or provider for auth state
    // Here we try to replicate what GoogleDriveService does on connect(), but we just check google_sign_in
    // Ideally GoogleDriveService should expose a 'currentUser' stream or property.
    // For now, we just rely on interactive connect to set state.
  }

  Future<void> _handleConnect() async {
    setState(() => _isLoading = true);
    final driveService = ref.read(googleDriveServiceProvider);

    final success = await driveService.connect();

    if (success) {
      if (mounted) {
        BizSnackbar.showSuccess(context, 'Úspešne pripojené k Google Drive');
      }
      setState(() => _isConnected = true);
    } else {
      if (mounted) {
        BizSnackbar.showError(context, 'Pripojenie zlyhalo');
      }
      setState(() => _isConnected = false);
    }
    setState(() => _isLoading = false);
  }

  Future<void> _handleBackup() async {
    if (!_isConnected) {
      await _handleConnect();
      if (!_isConnected) {
        return;
      }
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(backupServiceProvider).backupNow();
      if (mounted) {
        BizSnackbar.showSuccess(context, 'Záloha úspešne vytvorená!');
      }
    } catch (e) {
      if (mounted) {
        BizSnackbar.showError(context, 'Chyba zálohovania: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleRestore() async {
    if (!_isConnected) {
      await _handleConnect();
      if (!_isConnected) {
        return;
      }
    }

    setState(() => _isLoading = true);
    try {
      final driveService = ref.read(googleDriveServiceProvider);
      final backups = await driveService.listBackups();

      if (mounted) {
        setState(() => _isLoading = false);
        _showRestoreDialog(backups);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        BizSnackbar.showError(context, 'Chyba pri načítaní záloh: $e');
      }
    }
  }

  void _showRestoreDialog(List<dynamic> backups) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Obnoviť zo zálohy'),
        content: SizedBox(
          width: double.maxFinite,
          child: backups.isEmpty
              ? const Text('Nenašli sa žiadne zálohy.')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: backups.length,
                  itemBuilder: (ctx, index) {
                    final file = backups[index];
                    final date = file.createdTime != null
                        ? DateFormat(
                            'dd.MM.yyyy HH:mm',
                          ).format(file.createdTime!)
                        : 'Neznámy dátum';
                    return ListTile(
                      title: Text(file.name ?? 'Záloha'),
                      subtitle: Text(date),
                      leading: const Icon(Icons.restore),
                      onTap: () async {
                        Navigator.pop(ctx);
                        _performRestore(file.id);
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Zrušiť'),
          ),
        ],
      ),
    );
  }

  Future<void> _performRestore(String fileId) async {
    setState(() => _isLoading = true);
    try {
      await ref.read(backupServiceProvider).restore(fileId);
      if (mounted) {
        BizSnackbar.showSuccess(
          context,
          'Dáta úspešne obnovené! Reštartujte aplikáciu.',
        );
      }
    } catch (e) {
      if (mounted) {
        BizSnackbar.showError(context, 'Chyba obnovy: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.cloud_sync_outlined),
          title: const Text('Google Drive Záloha'),
          subtitle: Text(_isConnected ? 'Pripojené' : 'Odpojené'),
          trailing: _isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Switch(
                  value: _isConnected,
                  onChanged: (val) {
                    if (val) {
                      _handleConnect();
                    }
                    // Disconnect logic not fully implemented in UI but service has disconnect()
                  },
                ),
        ),
        if (_isConnected) ...[
          Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _handleBackup,
                  icon: const Icon(Icons.cloud_upload, size: 18),
                  label: const Text('Zálohovať'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _handleRestore,
                  icon: const Icon(Icons.cloud_download, size: 18),
                  label: const Text('Obnoviť'),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
