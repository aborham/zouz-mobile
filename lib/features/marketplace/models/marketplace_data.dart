class MarketplacePackage {
  final String id;
  final String name;
  final String description;
  final num price;
  final num? originalPrice;
  final String? imageUrl;
  final String type;
  final double rating;
  final String? badgeText;
  final String businessName;
  final String? businessLogo;
  final String category;

  MarketplacePackage({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.originalPrice,
    this.imageUrl,
    required this.type,
    required this.rating,
    this.badgeText,
    required this.businessName,
    this.businessLogo,
    required this.category,
  });

  factory MarketplacePackage.fromJson(Map<String, dynamic> json) {
    num parseNum(dynamic value, [num defaultValue = 0]) {
      if (value == null) return defaultValue;
      if (value is num) return value;
      if (value is String) return num.tryParse(value) ?? defaultValue;
      return defaultValue;
    }

    return MarketplacePackage(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: parseNum(json['price']),
      originalPrice: json['originalPrice'] != null
          ? parseNum(json['originalPrice'])
          : null,
      imageUrl: json['imageUrl'],
      type: json['type'] ?? 'QUANTITY',
      rating: parseNum(json['rating'] ?? 4.5).toDouble(),
      badgeText: json['badgeText'],
      businessName: json['businessName'] ?? '',
      businessLogo: json['businessLogo'],
      category: json['category'] ?? '',
    );
  }
}

class MarketplacePromo {
  final String title;
  final String subtitle;
  final String cta;

  MarketplacePromo({
    required this.title,
    required this.subtitle,
    required this.cta,
  });

  factory MarketplacePromo.fromJson(Map<String, dynamic> json) {
    return MarketplacePromo(
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      cta: json['cta'] ?? '',
    );
  }
}

class MarketplaceData {
  final List<MarketplacePackage> featured;
  final List<MarketplacePackage> trending;
  final List<String> categories;
  final MarketplacePromo promo;

  MarketplaceData({
    required this.featured,
    required this.trending,
    required this.categories,
    required this.promo,
  });

  factory MarketplaceData.fromJson(Map<String, dynamic> json) {
    return MarketplaceData(
      featured:
          (json['featured'] as List?)
              ?.map((e) => MarketplacePackage.fromJson(e))
              .toList() ??
          [],
      trending:
          (json['trending'] as List?)
              ?.map((e) => MarketplacePackage.fromJson(e))
              .toList() ??
          [],
      categories: (json['categories'] as List?)?.cast<String>() ?? [],
      promo: MarketplacePromo.fromJson(json['promo'] ?? {}),
    );
  }
}
