class LoginResponseDto {
  final String token;
  final String refreshToken; // ✅ NEW
  final String role;
  final Map<String, dynamic> userOrAdmin; // ✅ NEW

  LoginResponseDto({
    required this.token,
    required this.refreshToken,
    required this.role,
    required this.userOrAdmin,
  });

  factory LoginResponseDto.fromJson(Map<String, dynamic> json) {
    final map = (json['admin'] ??
            json['manager'] ??
            json['owner'] ??
            json['user'] ??
            {}) as Map;

    return LoginResponseDto(
      token: (json['token'] ?? '').toString(),
      refreshToken: (json['refreshToken'] ?? '').toString(), // ✅ NEW
      role: (json['role'] ?? map['role'] ?? '').toString(),
      userOrAdmin: Map<String, dynamic>.from(map),
    );
  }
}