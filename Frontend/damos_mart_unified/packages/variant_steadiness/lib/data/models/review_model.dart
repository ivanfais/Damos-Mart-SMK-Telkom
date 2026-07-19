import 'package:equatable/equatable.dart';

class ReviewModel extends Equatable {
  final String id;
  final String userId;
  final String productId;
  final String orderId;
  final int rating;
  final String? comment;
  final List<String> photos;
  final DateTime createdAt;

  const ReviewModel({
    required this.id,
    required this.userId,
    required this.productId,
    required this.orderId,
    required this.rating,
    this.comment,
    required this.photos,
    required this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    var photoList = json['photos'] as List? ?? [];
    List<String> parsedPhotos = [];
    for (var photo in photoList) {
      if (photo is Map && photo.containsKey('photoUrl')) {
        parsedPhotos.add(photo['photoUrl'] as String);
      } else if (photo is String) {
        parsedPhotos.add(photo);
      }
    }

    return ReviewModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      productId: json['productId'] as String,
      orderId: json['orderId'] as String,
      rating: json['rating'] as int? ?? 5,
      comment: json['comment'] as String?,
      photos: parsedPhotos,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'productId': productId,
      'orderId': orderId,
      'rating': rating,
      'comment': comment,
      'photos': photos,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, userId, productId, orderId, rating, comment, photos, createdAt];
}
