class AuthUserModel {
  final String fullName;
  final String email;
  final String password;
  final String confirmPassword;
  final String? profileImage;

  const AuthUserModel({
    this.fullName = '',
    this.email = '',
    this.password = '',
    this.confirmPassword = '',
    this.profileImage= '',
  });

  AuthUserModel copyWith({
    String? fullName,
    String? email,
    String? password,
    String? confirmPassword,
    String? profileImage,
  }) {
    return AuthUserModel(
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      profileImage: profileImage ?? this.profileImage,
    );
  }
}
