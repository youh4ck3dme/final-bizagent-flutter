class UserModel {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final bool isSuperAdmin;
  final bool isAnonymous;

  const UserModel({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.isSuperAdmin = false,
    this.isAnonymous = false,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'],
      photoUrl: map['photoUrl'],
      isSuperAdmin: map['isSuperAdmin'] ?? false,
      isAnonymous: map['isAnonymous'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'isSuperAdmin': isSuperAdmin,
      'isAnonymous': isAnonymous,
    };
  }
}
