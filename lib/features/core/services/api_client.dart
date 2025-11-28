import 'package:dio/dio.dart';

class ApiClient {
  ApiClient({
    Dio? dio,
    this.baseUrl = 'http://localhost:8000/api',
  }) : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl,
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 30),
                headers: {
                  'Content-Type': 'application/json',
                },
                validateStatus: (_) => true,
              ),
            );

  final Dio _dio;
  final String baseUrl;

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, String>? query,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      _normalizePath(path),
      queryParameters: query,
    );
    _throwIfError(response);
    return response.data ?? <String, dynamic>{};
  }

  Future<dynamic> getDynamic(
    String path, {
    Map<String, String>? query,
  }) async {
    final response = await _dio.get<dynamic>(
      _normalizePath(path),
      queryParameters: query,
    );
    _throwIfError(response);
    return response.data;
  }

  Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      _normalizePath(path),
      data: body,
    );
    _throwIfError(response);
    return response.data ?? <String, dynamic>{};
  }

  String _normalizePath(String path) {
    final cleanedBase = baseUrl.replaceAll(RegExp(r'/+$'), '');
    final cleanedPath = path.replaceFirst(RegExp(r'^/'), '');
    return '$cleanedBase/$cleanedPath';
  }

  void _throwIfError(Response<dynamic> response) {
    final status = response.statusCode ?? 0;
    if (status >= 400) {
      final detail = response.data is Map<String, dynamic>
          ? (response.data['detail']?.toString() ?? '')
          : response.data?.toString() ?? '';
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'HTTP $status: $detail',
        type: DioExceptionType.badResponse,
      );
    }
  }
}
