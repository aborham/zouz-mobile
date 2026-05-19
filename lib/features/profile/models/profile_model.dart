class UserProfile {
  final String? id;
  final String? name;
  final String? email;
  final String? phoneNumber;
  final String? avatarUrl;
  final String? gender;
  final DateTime? dateOfBirth;
  final int activePackagesCount;

  UserProfile({
    this.id,
    this.name,
    this.email,
    this.phoneNumber,
    this.avatarUrl,
    this.gender,
    this.dateOfBirth,
    required this.activePackagesCount,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id']?.toString(), // Safely convert to string if exists
      name: json['name'],
      email: json['email'],
      phoneNumber: json['phoneNumber'],
      avatarUrl: json['avatarUrl'],
      gender: json['gender'],
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.parse(json['dateOfBirth'])
          : null,
      activePackagesCount: json['activePackagesCount'] ?? 0,
    );
  }
}
