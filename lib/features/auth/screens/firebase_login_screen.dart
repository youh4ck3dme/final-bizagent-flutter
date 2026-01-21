import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/ui/biz_theme.dart';

class FirebaseLoginScreen extends ConsumerWidget {
  const FirebaseLoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SignInScreen(
      providers: [
        EmailAuthProvider(),
        GoogleProvider(clientId: '542280140779-c5m14rqpih1j9tmf9km52aq1684l9qjd.apps.googleusercontent.com'),
      ],
      headerBuilder: (context, constraints, shrinkOffset) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Icon(
              Icons.lock_person_rounded,
              size: 80,
              color: BizTheme.slovakBlue,
            ),
          ),
        );
      },
      subtitleBuilder: (context, action) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: action == AuthAction.signIn
              ? const Text('Vitajte v BizAgent. Prihláste sa pre pokračovanie.')
              : const Text('Vytvorte si účet a začnite spravovať svoje podnikanie.'),
        );
      },
      footerBuilder: (context, action) {
        return const Padding(
          padding: EdgeInsets.only(top: 16),
          child: Text(
            'Používaním aplikácie súhlasíte s našimi podmienkami.',
            style: TextStyle(color: Colors.grey),
          ),
        );
      },
    );
  }
}
