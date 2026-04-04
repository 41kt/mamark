class RatingEntity {
  final String id;
  final String productId;
  final String userId;
  final int rating;
  final String? comment;
  final DateTime createdAt;

  const RatingEntity({
    required this.id,
    required this.productId,
    required this.userId,
    required this.rating,
    this.comment,
    required this.createdAt,
  });
}
