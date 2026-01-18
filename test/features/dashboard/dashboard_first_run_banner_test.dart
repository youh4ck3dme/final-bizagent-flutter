import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bizagent/features/dashboard/screens/dashboard_screen.dart';
import 'package:bizagent/features/invoices/providers/invoices_provider.dart';
import 'package:bizagent/features/expenses/providers/expenses_provider.dart';
import 'package:bizagent/features/auth/providers/auth_repository.dart';
import 'package:bizagent/core/i18n/l10n.dart';

void main() {
  testWidgets(
      'Dashboard shows first-run banner when invoices & expenses are empty',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Avoid real Firebase/Auth calls in tests
          authStateProvider.overrideWith((ref) => Stream.value(null)),

          // Ensure first-run empty state
          invoicesProvider.overrideWith((ref) => Stream.value([])),
          expensesProvider.overrideWith((ref) => Stream.value([])),
        ],
        child: L10n(
          locale: AppLocale.sk,
          child: const MaterialApp(
            home: DashboardScreen(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Banner headline (unique to first-run banner)
    expect(find.textContaining('Začni'), findsOneWidget);

    // CTA buttons exist (may appear in banner + quick actions, so use findsAtLeast)
    expect(find.textContaining('Vytvoriť'), findsAtLeastNWidgets(1));
    expect(find.textContaining('Pridať'), findsAtLeastNWidgets(1));
  });
}
