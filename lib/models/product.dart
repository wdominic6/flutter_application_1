class Product {
  final int? id;
  final int? userId;
  final String name;
  final String? description;
  final double price;
  final String? imagePath;
  final double? latitude;
  final double? longitude;
  final bool canEdit;

  Product({
    this.id,
    this.userId,
    required this.name,
    this.description,
    required this.price,
    this.imagePath,
    this.latitude,
    this.longitude,
    this.canEdit = false,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: _parseInt(json['id']),
      userId: _parseInt(
        json['user_id'] ??
            json['userId'] ??
            json['owner_id'] ??
            json['ownerId'] ??
            json['seller_id'] ??
            json['creator_id'] ??
            json['created_by'] ??
            json['created_by_id'] ??
            (json['user'] is Map ? json['user']['id'] : null),
      ),
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      price: _parseDouble(json['price']) ?? 0,
      imagePath: json['image_path']?.toString(),
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      canEdit: _parseBool(
        json['can_edit'] ??
            json['can_update'] ??
            json['is_owner'] ??
            json['isOwner'],
      ),
    );
  }

  bool canBeManagedBy(int? currentUserId) {
    if (canEdit) return true;
    return currentUserId != null && userId != null && currentUserId == userId;
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is num) return value != 0;

    final normalized = value.toString().toLowerCase().trim();
    return normalized == 'true' || normalized == '1' || normalized == 'yes';
  }
}
