class SavedPaymentMethod {
  final String id;
  final String type; // CARD, WALLET
  final String provider; // TAP
  final String? cardId;
  final String? last4;
  final String? brand;
  final int? expiryMonth;
  final int? expiryYear;
  final bool isDefault;

  SavedPaymentMethod({
    required this.id,
    required this.type,
    required this.provider,
    this.cardId,
    this.last4,
    this.brand,
    this.expiryMonth,
    this.expiryYear,
    this.isDefault = false,
  });

  factory SavedPaymentMethod.fromJson(Map<String, dynamic> json) {
    return SavedPaymentMethod(
      id: json['id'],
      type: json['type'] ?? 'CARD',
      provider: json['provider'] ?? 'TAP',
      cardId: json['cardId'],
      last4: json['last4'],
      brand: json['brand'],
      expiryMonth: json['expiryMonth'],
      expiryYear: json['expiryYear'],
      isDefault: json['isDefault'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'provider': provider,
      'cardId': cardId,
      'last4': last4,
      'brand': brand,
      'expiryMonth': expiryMonth,
      'expiryYear': expiryYear,
      'isDefault': isDefault,
    };
  }
}
