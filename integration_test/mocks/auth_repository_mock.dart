import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bizagent/features/auth/providers/auth_repository.dart';
import 'package:bizagent/features/auth/models/user_model.dart';

class MockAuthRepository implements AuthRepository {
  final _authStateController = StreamController<UserModel?>.broadcast();
  UserModel? _currentUser;

  @override
  late final Stream<UserModel?> authStateChanges;

  MockAuthRepository() {
    authStateChanges = _buildAuthStream().asBroadcastStream();
  }

  Stream<UserModel?> _buildAuthStream() async* {
    yield _currentUser;
    yield* _authStateController.stream;
  }

  @override
  UserModel? get currentUser => _currentUser;

  @override
  Future<String?> get currentUserToken async => 'fake-id-token';

  @override
  Future<UserModel?> signIn(String email, String password) async {
    _currentUser = UserModel(
      id: 'mock-user-id',
      email: email,
      displayName: 'Mock User',
    );
    _authStateController.add(_currentUser);
    return _currentUser;
  }

  @override
  Future<UserModel?> signUp(String email, String password) async {
    return signIn(email, password);
  }

  @override
  Future<UserModel?> signInWithGoogle() async {
    print('[MOCK] signInWithGoogle called');
    _currentUser = UserModel(
      id: 'mock-google-id',
      email: 'test@example.com',
      displayName: 'Google Mock User',
    );
    _authStateController.add(_currentUser);
    return _currentUser;
  }

  @override
  Future<UserModel?> signInAnonymously() async {
    _currentUser = UserModel(
      id: 'mock-anon-id',
      email: '',
      displayName: 'Anon Mock User',
      isAnonymous: true,
    );
    _authStateController.add(_currentUser);
    return _currentUser;
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _authStateController.add(null);
  }

  @override
  void dispose() {
    _authStateController.close();
  }
}
