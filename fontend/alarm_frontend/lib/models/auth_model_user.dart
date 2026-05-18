class AuthUserModel {
  final String fullName;
  final String email;
  final String password;
  final String confirmPassword;
  final String profileImage;

  const AuthUserModel({
    this.fullName = '',
    this.email = '',
    this.password = '',
    this.confirmPassword = '',
    this.profileImage= '',
  });

  factory AuthUserModel.fromJson(Map<String, dynamic> json) {
    return AuthUserModel(
      fullName: json['fullName'],
      email: json['email'],
      password: json['password'],
      confirmPassword: json['confirmPassword'],
      profileImage: json['profileImage'],
    );
  }

    Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'email': email,
      'password': password,
      'confirmPassword': confirmPassword,
      'profileImage': profileImage,
    };
  }

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
