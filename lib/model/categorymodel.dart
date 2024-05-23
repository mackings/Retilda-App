
class ApiCategoryResponse<T> {
  
  bool success;
  String message;
  T data;

  ApiCategoryResponse({required this.success, required this.message, required this.data});

  factory ApiCategoryResponse.fromJson(Map<String, dynamic> json, T Function(dynamic) create) {
    return ApiCategoryResponse<T>(
      success: json['success'],
      message: json['message'],
      data: create(json['data']),
    );
  }
}
