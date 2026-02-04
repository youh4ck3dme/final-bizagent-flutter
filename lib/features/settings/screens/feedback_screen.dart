import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../../core/ui/biz_theme.dart';
import '../../../shared/utils/biz_snackbar.dart';
import '../../auth/providers/auth_repository.dart';
import 'package:package_info_plus/package_info_plus.dart';

class FeedbackScreen extends ConsumerStatefulWidget {
  const FeedbackScreen({super.key});

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  final _commentController = TextEditingController();
  int _rating = 0; // 0 means unselected
  bool _isLoading = false;

  Future<void> _submitfeedback() async {
    if (_rating == 0) {
      BizSnackbar.showInfo(context, 'Prosím, vyberte hodnotenie (hviezdičky).');
      return;
    }

    final platform = Theme.of(context).platform.toString();

    try {
      final user = ref.read(authStateProvider).asData?.value;
      final packageInfo = await PackageInfo.fromPlatform();

      await FirebaseFirestore.instance.collection('user_feedback').add({
        'userId': user?.id ?? 'anonymous',
        'userEmail': user?.email ?? 'anonymous',
        'rating': _rating,
        'comment': _commentController.text.trim(),
        'appVersion': packageInfo.version,
        'buildNumber': packageInfo.buildNumber,
        'platform': platform,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        BizSnackbar.showSuccess(context, 'Ďakujeme za váš názor! 💙');
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        BizSnackbar.showError(context, 'Chyba pri odosielaní: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildStar(int index) {
    final isSelected = index <= _rating;
    return IconButton(
      icon: Icon(
        isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
        color: isSelected ? BizTheme.warningAmber : Colors.grey[400],
        size: 40,
      ),
      onPressed: () => setState(() => _rating = index),
      padding: EdgeInsets.zero,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Spätná väzba')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Ako ste spokojný s BizAgentom?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) => _buildStar(i + 1)),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _commentController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Váš názor alebo nápad na vylepšenie (nepovinné)',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _submitfeedback,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Odoslať spätnú väzbu'),
            ),
          ],
        ),
      ),
    );
  }
}
