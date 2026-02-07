class ReviewResponse {
  final bool? success;
  final String? message;
  final ReviewData? data;

  ReviewResponse({
    this.success,
    this.message,
    this.data,
  });

  factory ReviewResponse.fromJson(Map<String, dynamic> json) {
    return ReviewResponse(
      success: json['success'],
      message: json['message'],
      data: json['data'] != null ? ReviewData.fromJson(json['data']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data?.toJson(),
    };
  }
}

class ReviewData {
  final double? avgRating;
  final int? count;
  final List<Review>? reviews;

  ReviewData({
    this.avgRating,
    this.count,
    this.reviews,
  });

  factory ReviewData.fromJson(Map<String, dynamic> json) {
    return ReviewData(
      avgRating: (json['avgRating'] is num)
          ? (json['avgRating'] as num).toDouble()
          : null,
      count: json['count'],
      reviews: json['reviews'] != null
          ? List<Review>.from(
              json['reviews'].map((item) => Review.fromJson(item)))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'avgRating': avgRating,
      'count': count,
      'reviews': reviews != null
          ? List<dynamic>.from(reviews!.map((item) => item.toJson()))
          : null,
    };
  }
}

class Review {
  final String? id;
  final String? productId;
  final ReviewUser? user;
  final int? rating;
  final String? comment;
  final String? createdAt;

  Review({
    this.id,
    this.productId,
    this.user,
    this.rating,
    this.comment,
    this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    final dynamic userField = json['userId'];
    ReviewUser? user;
    if (userField is Map<String, dynamic>) {
      user = ReviewUser.fromJson(userField);
    } else if (userField is String) {
      user = ReviewUser(id: userField, fullName: null);
    }

    return Review(
      id: json['_id'],
      productId: json['productId'],
      user: user,
      rating: json['rating'],
      comment: json['comment'],
      createdAt: json['createdAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'productId': productId,
      'userId': user?.toJson(),
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt,
    };
  }
}

class ReviewUser {
  final String? id;
  final String? fullName;
  final String? email;

  ReviewUser({
    this.id,
    this.fullName,
    this.email,
  });

  factory ReviewUser.fromJson(Map<String, dynamic> json) {
    return ReviewUser(
      id: json['_id'],
      fullName: json['fullName'],
      email: json['email'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'fullName': fullName,
      'email': email,
    };
  }
}

class CreateReviewResponse {
  final bool? success;
  final String? message;
  final Review? data;

  CreateReviewResponse({
    this.success,
    this.message,
    this.data,
  });

  factory CreateReviewResponse.fromJson(Map<String, dynamic> json) {
    return CreateReviewResponse(
      success: json['success'],
      message: json['message'],
      data: json['data'] != null ? Review.fromJson(json['data']) : null,
    );
  }
}
