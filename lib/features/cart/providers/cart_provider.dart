import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CartItem {
  final String packageId;
  final String packageName;
  final String? packageDescription;
  final double price;
  final int quantity;
  final String type;
  final String tenantId;
  final String? tenantName;
  final String? tenantLogoUrl;
  final String? standId;
  final String? imageUrl;

  CartItem({
    required this.packageId,
    required this.packageName,
    this.packageDescription,
    required this.price,
    required this.quantity,
    required this.type,
    required this.tenantId,
    this.tenantName,
    this.tenantLogoUrl,
    this.standId,
    this.imageUrl,
  });

  CartItem copyWith({
    int? quantity,
  }) {
    return CartItem(
      packageId: packageId,
      packageName: packageName,
      packageDescription: packageDescription,
      price: price,
      quantity: quantity ?? this.quantity,
      type: type,
      tenantId: tenantId,
      tenantName: tenantName,
      tenantLogoUrl: tenantLogoUrl,
      standId: standId,
      imageUrl: imageUrl,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'packageId': packageId,
      'packageName': packageName,
      'packageDescription': packageDescription,
      'price': price,
      'quantity': quantity,
      'type': type,
      'tenantId': tenantId,
      'tenantName': tenantName,
      'tenantLogoUrl': tenantLogoUrl,
      'standId': standId,
      'imageUrl': imageUrl,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      packageId: map['packageId'] ?? '',
      packageName: map['packageName'] ?? '',
      packageDescription: map['packageDescription'],
      price: double.tryParse(map['price']?.toString() ?? '0') ?? 0.0,
      quantity: map['quantity']?.toInt() ?? 0,
      type: map['type'] ?? '',
      tenantId: map['tenantId'] ?? '',
      tenantName: map['tenantName'],
      tenantLogoUrl: map['tenantLogoUrl'],
      standId: map['standId'],
      imageUrl: map['imageUrl'],
    );
  }

  String toJson() => json.encode(toMap());

  factory CartItem.fromJson(String source) => CartItem.fromMap(json.decode(source));
}

class CartState {
  final List<CartItem> items;
  final bool isLoading;

  CartState({
    this.items = const [],
    this.isLoading = false,
  });

  double get totalPrice => items.fold(0, (sum, item) => sum + (item.price * item.quantity));
  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  CartState copyWith({
    List<CartItem>? items,
    bool? isLoading,
  }) {
    return CartState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class CartNotifier extends Notifier<CartState> {
  static const String _storageKey = 'zouz_cart';

  @override
  CartState build() {
    _loadCart();
    return CartState(isLoading: true);
  }

  Future<void> _loadCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? cartData = prefs.getString(_storageKey);
      
      if (cartData != null) {
        final List<dynamic> decoded = json.decode(cartData);
        final items = decoded.map((item) => CartItem.fromMap(item)).toList();
        state = state.copyWith(items: items, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> _saveCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encoded = json.encode(state.items.map((item) => item.toMap()).toList());
      await prefs.setString(_storageKey, encoded);
    } catch (_) {}
  }

  void addItem(CartItem item) {
    // Note: Zouz only allows cart items from the same tenant (business)
    if (state.items.isNotEmpty && state.items.first.tenantId != item.tenantId) {
      // For now, we clear the cart if adding from a different tenant
      // Or we could throw an error to be handled by the UI
      state = state.copyWith(items: [item]);
    } else {
      final index = state.items.indexWhere((i) => i.packageId == item.packageId);
      if (index >= 0) {
        final existingItem = state.items[index];
        final updatedItems = [...state.items];
        updatedItems[index] = existingItem.copyWith(quantity: existingItem.quantity + 1);
        state = state.copyWith(items: updatedItems);
      } else {
        state = state.copyWith(items: [...state.items, item]);
      }
    }
    _saveCart();
  }

  void updateQuantity(String packageId, int quantity) {
    if (quantity <= 0) {
      removeItem(packageId);
      return;
    }
    final updatedItems = state.items.map((item) {
      if (item.packageId == packageId) {
        return item.copyWith(quantity: quantity);
      }
      return item;
    }).toList();
    state = state.copyWith(items: updatedItems);
    _saveCart();
  }

  void removeItem(String packageId) {
    state = state.copyWith(
      items: state.items.where((item) => item.packageId != packageId).toList(),
    );
    _saveCart();
  }

  void clear() {
    state = state.copyWith(items: []);
    _saveCart();
  }
}

final cartProvider = NotifierProvider<CartNotifier, CartState>(CartNotifier.new);
