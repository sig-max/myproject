class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final Map<String, dynamic> profile;
  final String? token;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.profile,
    this.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      role: (json['role'] ?? 'patient').toString(), 
      profile: json['profile'] is Map<String, dynamic> 
          ? Map<String, dynamic>.from(json['profile']) 
          : {},
      token: json['token']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
        'profile': profile,
        if (token != null) 'token': token,
      };
}
