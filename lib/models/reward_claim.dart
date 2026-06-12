/// Record of a child claiming a reward with their points.
class RewardClaim {
  final String id;
  final String childId;
  final String childName;
  final String rewardId;
  final String rewardName;
  final int pointsSpent;
  final double price;
  final DateTime claimedAt;

  const RewardClaim({
    required this.id,
    required this.childId,
    required this.childName,
    required this.rewardId,
    required this.rewardName,
    required this.pointsSpent,
    required this.price,
    required this.claimedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'childId': childId,
      'childName': childName,
      'rewardId': rewardId,
      'rewardName': rewardName,
      'pointsSpent': pointsSpent,
      'price': price,
      'claimedAt': claimedAt.toIso8601String(),
    };
  }

  factory RewardClaim.fromJson(Map<String, dynamic> json) {
    return RewardClaim(
      id: json['id'] as String,
      childId: json['childId'] as String,
      childName: json['childName'] as String? ?? '',
      rewardId: json['rewardId'] as String,
      rewardName: json['rewardName'] as String,
      pointsSpent: json['pointsSpent'] as int,
      price: (json['price'] as num).toDouble(),
      claimedAt: DateTime.parse(json['claimedAt'] as String),
    );
  }
}
