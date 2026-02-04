import 'package:flutter_riverpod/flutter_riverpod.dart' as fr;
import 'auth_repository.dart';

final authControllerProvider =
    fr.NotifierProvider<AuthController, fr.AsyncValue<void>>(() {
  return AuthController();
});

class AuthController extends fr.Notifier<fr.AsyncValue<void>> {
  AuthRepository get _authRepository => ref.read(authRepositoryProvider);

  @override
  fr.AsyncValue<void> build() {
    return const fr.AsyncValue.data(null);
  }

  Future<void> signIn(String email, String password) async {
    state = const fr.AsyncValue.loading();
    state = await fr.AsyncValue.guard(
      () => _authRepository.signIn(email, password),
    );
  }

  Future<void> signUp(String email, String password) async {
    state = const fr.AsyncValue.loading();
    state = await fr.AsyncValue.guard(
      () => _authRepository.signUp(email, password),
    );
  }

  Future<void> signInWithGoogle() async {
    state = const fr.AsyncValue.loading();
    state = await fr.AsyncValue.guard(() => _authRepository.signInWithGoogle());
  }

  Future<void> signOut() async {
    state = const fr.AsyncValue.loading();
    state = await fr.AsyncValue.guard(() => _authRepository.signOut());
  }

  void mockSuccessLogin() {
    state = const fr.AsyncValue.data(null);
  }
}
