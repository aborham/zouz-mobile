class UserSettings {
  final bool pushNotifications;
  final bool emailNotifications;
  final bool smsNotifications;
  final bool orderUpdates;
  final bool promotionalNotifications;

  UserSettings({
    this.pushNotifications = true,
    this.emailNotifications = false,
    this.smsNotifications = true,
    this.orderUpdates = true,
    this.promotionalNotifications = true,
  });

  factory UserSettings.fromJson(Map<String, dynamic>? json) {
    if (json == null) return UserSettings();
    return UserSettings(
      pushNotifications: json['pushNotifications'] ?? true,
      emailNotifications: json['emailNotifications'] ?? false,
      smsNotifications: json['smsNotifications'] ?? true,
      orderUpdates: json['orderUpdates'] ?? true,
      promotionalNotifications: json['promotionalNotifications'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pushNotifications': pushNotifications,
      'emailNotifications': emailNotifications,
      'smsNotifications': smsNotifications,
      'orderUpdates': orderUpdates,
      'promotionalNotifications': promotionalNotifications,
    };
  }
}

class UserProfile {
  final String? id;
  final String? name;
  final String? email;
  final String? phoneNumber;
  final String? avatarUrl;
  final String? gender;
  final DateTime? dateOfBirth;
  final int activePackagesCount;
  final UserSettings settings;

  UserProfile({
    this.id,
    this.name,
    this.email,
    this.phoneNumber,
    this.avatarUrl,
    this.gender,
    this.dateOfBirth,
    required this.activePackagesCount,
    required this.settings,
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
      settings: UserSettings.fromJson(json['settings']),
    );
  }
}
