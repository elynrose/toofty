/// A reward that parents can configure and kids can claim with points.
class Reward {
  final String id;
  final String name;
  final String? photoPath;
  final int pointsRequired;
  final double price;

  const Reward({
    required this.id,
    required this.name,
    this.photoPath,
    required this.pointsRequired,
    required this.price,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'photoPath': photoPath,
      'pointsRequired': pointsRequired,
      'price': price,
    };
  }

  factory Reward.fromJson(Map<String, dynamic> json) {
    return Reward(
      id: json['id'] as String,
      name: json['name'] as String,
      photoPath: json['photoPath'] as String?,
      pointsRequired: json['pointsRequired'] as int,
      price: (json['price'] as num).toDouble(),
    );
  }

  Reward copyWith({
    String? id,
    String? name,
    String? photoPath,
    int? pointsRequired,
    double? price,
  }) {
    return Reward(
      id: id ?? this.id,
      name: name ?? this.name,
      photoPath: photoPath ?? this.photoPath,
      pointsRequired: pointsRequired ?? this.pointsRequired,
      price: price ?? this.price,
    );
  }
}
