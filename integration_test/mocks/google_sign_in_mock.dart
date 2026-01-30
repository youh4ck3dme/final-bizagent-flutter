import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockGoogleSignIn extends Fake with MockPlatformInterfaceMixin implements GoogleSignInPlatform {
  @override
  Future<void> init({
    List<String> scopes = const <String>[],
    SignInOption signInOption = SignInOption.standard,
    String? hostedDomain,
    String? clientId,
  }) async {}

  @override
  Future<void> initWithParams(SignInInitParameters params) async {}

  @override
  Future<GoogleSignInUserData?> signIn() async {
    return GoogleSignInUserData(
      email: 'test@example.com',
      id: 'test-user-id',
      displayName: 'Test User',
      photoUrl: 'https://via.placeholder.com/50',
      idToken: 'fake-id-token',
      serverAuthCode: 'fake-auth-code',
    );
  }

  @override
  Future<GoogleSignInUserData?> signInSilently() async {
    // Return null to simulate not signed in initially, or return user if testing persistency
    return null;
  }

  @override
  Future<GoogleSignInTokenData> getTokens({
    required String email,
    bool? shouldRecoverAuth = true,
  }) async {
    return GoogleSignInTokenData(
      idToken: 'fake-id-token',
      accessToken: 'fake-access-token',
    );
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<void> disconnect() async {}

  @override
  Future<bool> isSignedIn() async => false;

  @override
  Future<void> clearAuthCache({required String token}) async {}

  @override
  Future<bool> requestScopes(List<String> scopes) async => true;

  @override
  Stream<GoogleSignInUserData?>? get userDataEvents => const Stream.empty();

  @override
  bool get isMock => true;

  @override
  Future<bool> canAccessScopes(List<String> scopes, {String? accessToken}) async => true;

}
