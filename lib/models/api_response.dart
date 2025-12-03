class ApiResponse {
  final bool status;
  final String message;
  final int statusCode;
  final dynamic response;

  ApiResponse({
    required this.status,
    required this.message,
    required this.statusCode,
    required this.response,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    return ApiResponse(
      status: json["status"] ?? false,
      message: json["message"] ?? "",
      statusCode: json["statusCode"] ?? 500,
      response: json["response"],
    );
  }
}
