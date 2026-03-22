import 'dart:convert';

class HomeData {
  final HomeUser user;
  final List<ActivePackage> activePackages;
  final List<TrendingPackage> trendingPackages;
  final List<TrendingProvider> trendingProviders;

  HomeData({
    required this.user,
    required this.activePackages,
    required this.trendingPackages,
    required this.trendingProviders,
  });

  factory HomeData.fromJson(Map<String, dynamic> json) {
    return HomeData(
      user: HomeUser.fromJson(json['user'] ?? {}),
      activePackages: json['activePackages'] != null 
          ? (json['activePackages'] as List).map((i) => ActivePackage.fromJson(i)).toList()
          : [],
      trendingPackages: json['trendingPackages'] != null 
          ? (json['trendingPackages'] as List).map((i) => TrendingPackage.fromJson(i)).toList()
          : [],
      trendingProviders: json['trendingProviders'] != null 
          ? (json['trendingProviders'] as List).map((i) => TrendingProvider.fromJson(i)).toList()
          : [],
    );
  }
}

class HomeUser {
  final String? name;
  final String? avatarUrl;
  final double walletBalance;

  HomeUser({
    this.name,
    this.avatarUrl,
    required this.walletBalance,
  });

  factory HomeUser.fromJson(Map<String, dynamic> json) {
    return HomeUser(
      name: json['name'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      walletBalance: _parseDouble(json['walletBalance']),
    );
  }
}

double _parseDouble(dynamic value, {double defaultValue = 0.0}) {
  if (value == null) return defaultValue;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? defaultValue;
  return defaultValue;
}

Map<String, dynamic> _parseLocalized(dynamic value) {
  if (value == null) return {'en': '', 'ar': ''};
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  if (value is String) {
    if (value.startsWith('{')) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map<String, dynamic>) return decoded;
      } catch (_) {}
    }
    return {'en': value, 'ar': value};
  }
  return {'en': '', 'ar': ''};
}

class ActivePackage {
  final String id;
  final dynamic packageName; // Json from backend
  final dynamic providerName; // Json from backend
  final String? providerLogo;
  final int remainingQuantity;
  final int? initialQuantity;
  final DateTime? expiresAt;
  final DateTime? createdAt;
  final String? orderNumber;
  final dynamic packageDescription;
  final String type;

  ActivePackage({
    required this.id,
    required this.packageName,
    required this.providerName,
    this.providerLogo,
    required this.remainingQuantity,
    this.initialQuantity,
    this.expiresAt,
    this.createdAt,
    this.orderNumber,
    this.packageDescription,
    required this.type,
  });

  factory ActivePackage.fromJson(Map<String, dynamic> json) {
    return ActivePackage(
      id: json['id'] ?? '',
      packageName: _parseLocalized(json['packageName']),
      providerName: _parseLocalized(json['providerName']),
      providerLogo: json['providerLogo'],
      remainingQuantity: json['remainingQuantity'] ?? 0,
      initialQuantity: json['initialQuantity'] ?? 0,
      expiresAt: json['expiresAt'] != null ? DateTime.parse(json['expiresAt']) : null,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      orderNumber: json['orderNumber'],
      packageDescription: _parseLocalized(json['packageDescription']),
      type: json['type'] ?? 'Items',
    );
  }

  double get progress {
    if (initialQuantity == null || initialQuantity == 0) return 0;
    return (initialQuantity! - remainingQuantity) / initialQuantity!;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'packageName': packageName['en'],
      'packageNameAr': packageName['ar'],
      'businessName': providerName['en'],
      'businessNameAr': providerName['ar'],
      'businessLogo': providerLogo,
      'remainingQuantity': remainingQuantity,
      'initialQuantity': initialQuantity,
      'expiresAt': expiresAt?.toIso8601String(),
      'purchaseDate': createdAt?.toIso8601String(),
      'orderNumber': orderNumber,
      'description': packageDescription['en'],
      'descriptionAr': packageDescription['ar'],
      'packageType': type.toUpperCase(),
      'status': 'ACTIVE',
    };
  }
}

class TrendingPackage {
  final String id;
  final dynamic name;
  final double price;
  final String? imageUrl;
  final dynamic providerName;
  final double? rating;

  TrendingPackage({
    required this.id,
    required this.name,
    required this.price,
    this.imageUrl,
    required this.providerName,
    this.rating,
  });

  factory TrendingPackage.fromJson(Map<String, dynamic> json) {
    return TrendingPackage(
      id: json['id'] ?? '',
      name: _parseLocalized(json['name']),
      price: _parseDouble(json['price']),
      imageUrl: json['imageUrl'] as String?,
      providerName: _parseLocalized(json['providerName']),
      rating: _parseDouble(json['rating'], defaultValue: 4.5),
    );
  }
}

class TrendingProvider {
  final String id;
  final String slug;
  final dynamic name;
  final String? logoUrl;
  final String? coverImageUrl;

  TrendingProvider({
    required this.id,
    required this.slug,
    required this.name,
    this.logoUrl,
    this.coverImageUrl,
  });

  factory TrendingProvider.fromJson(Map<String, dynamic> json) {
    return TrendingProvider(
      id: json['id'] ?? '',
      slug: json['slug'] ?? '',
      name: _parseLocalized(json['name']),
      logoUrl: json['logoUrl'],
      coverImageUrl: json['coverImageUrl'],
    );
  }
}
