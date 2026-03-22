class MarketplacePackage {
  final String id;
  final Map<String, String> name;
  final Map<String, String>? description;
  final num price;
  final num? originalPrice;
  final String? imageUrl;
  final String type;
  final double rating;
  final String? badgeText;
  final String businessName;
  final String? businessLogo;
  final String? category;

  MarketplacePackage({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.originalPrice,
    this.imageUrl,
    required this.type,
    required this.rating,
    this.badgeText,
    required this.businessName,
    this.businessLogo,
    this.category,
  });

  factory MarketplacePackage.fromJson(Map<String, dynamic> json) {
    num parseNum(dynamic value, [num defaultValue = 0]) {
      if (value == null) return defaultValue;
      if (value is num) return value;
      if (value is String) return num.tryParse(value) ?? defaultValue;
      return defaultValue;
    }

    Map<String, String> parseLocalized(dynamic value) {
      if (value == null) return {'en': ''};
      if (value is String) return {'en': value};
      if (value is Map) return Map<String, String>.from(value);
      return {'en': ''};
    }

    return MarketplacePackage(
      id: json['id'],
      name: parseLocalized(json['name']),
      description: json['description'] != null ? parseLocalized(json['description']) : null,
      price: parseNum(json['price']),
      originalPrice: json['originalPrice'] != null ? parseNum(json['originalPrice']) : null,
      imageUrl: json['imageUrl'],
      type: json['type'] ?? 'QUANTITY',
      rating: parseNum(json['rating'] ?? 4.5).toDouble(),
      badgeText: json['badgeText'],
      businessName: json['businessName'] ?? '',
      businessLogo: json['businessLogo'],
      category: json['category'] is String ? json['category'] : (json['category'] is Map ? (json['category']['en'] ?? '') : ''),
    );
  }
}

class MarketplaceData {
  final List<MarketplacePackage> featured;
  final List<MarketplacePackage> trending;

  MarketplaceData({required this.featured, required this.trending});

  factory MarketplaceData.fromJson(Map<String, dynamic> json) {
    return MarketplaceData(
      featured: (json['featured'] as List?)
              ?.map((e) => MarketplacePackage.fromJson(e))
              .toList() ??
          [],
      trending: (json['trending'] as List?)
              ?.map((e) => MarketplacePackage.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class ExploreCategory {
  final String id;
  final Map<String, String> name;

  ExploreCategory({required this.id, required this.name});

  factory ExploreCategory.fromJson(Map<String, dynamic> json) {
    return ExploreCategory(
      id: json['id'],
      name: Map<String, String>.from(json['name']),
    );
  }
}

class MarketplaceBusiness {
  final String id;
  final String slug;
  final Map<String, String> name;
  final String? logoUrl;
  final String? coverImageUrl;
  final Map<String, String>? category;
  final Map<String, String>? description;
  final double rating;

  MarketplaceBusiness({
    required this.id,
    required this.slug,
    required this.name,
    this.logoUrl,
    this.coverImageUrl,
    this.category,
    this.description,
    required this.rating,
  });

  factory MarketplaceBusiness.fromJson(Map<String, dynamic> json) {
    Map<String, String> parseLocalized(dynamic value) {
      if (value == null) return {};
      if (value is String) return {'en': value};
      if (value is Map) return Map<String, String>.from(value);
      return {};
    }

    return MarketplaceBusiness(
      id: json['id'],
      slug: json['slug'] ?? '',
      name: parseLocalized(json['name']),
      logoUrl: json['logoUrl'],
      coverImageUrl: json['coverImageUrl'],
      category: json['category'] != null ? parseLocalized(json['category']) : null,
      description: json['description'] != null ? parseLocalized(json['description']) : null,
      rating: (json['rating'] ?? 4.5).toDouble(),
    );
  }
}

class MarketplaceExploreData {
  final List<ExploreCategory> categories;
  final List<MarketplaceBusiness> businesses;

  MarketplaceExploreData({required this.categories, required this.businesses});

  factory MarketplaceExploreData.fromJson(Map<String, dynamic> json) {
    return MarketplaceExploreData(
      categories: (json['categories'] as List?)
              ?.map((e) => ExploreCategory.fromJson(e))
              .toList() ??
          [],
      businesses: (json['businesses'] as List?)
              ?.map((e) => MarketplaceBusiness.fromJson(e))
              .toList() ??
          [],
    );
  }
}
