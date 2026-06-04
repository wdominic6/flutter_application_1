class Product {
  final int? id;
  final String name;
  final String? description;
  final double price;
  final String? imagePath;
  final double? latitude;
  final double? longitude;

  Product({
    this.id,
    required this.name,
    this.description,
    required this.price,
    this.imagePath,
    this.latitude,
    this.longitude,
  });

  // Convierte un JSON de Laravel en un Objeto Producto de Flutter
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      price: double.parse(json['price'].toString()),
      imagePath: json['image_path'],
      latitude: json['latitude'] != null
          ? double.parse(json['latitude'].toString())
          : null,
      longitude: json['longitude'] != null
          ? double.parse(json['longitude'].toString())
          : null,
    );
  }
}
