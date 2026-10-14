enum AuthProviderKind { google, apple }

class AuthUser {
  const AuthUser({
    required this.uid,
    this.email,
    this.displayName,
    this.photoUrl,
    this.provider = AuthProviderKind.google,
  });

  final String uid;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final AuthProviderKind provider;
}
