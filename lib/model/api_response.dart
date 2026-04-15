class ApiResponse {
  final bool success;
  final String message;
  final List errors;
  final int? statusCode;

  ApiResponse({
    required this.success,
    required this.message,
    required this.errors,
    this.statusCode,
  });
}
