import 'package:dio/dio.dart';

class ApiClient {
  ApiClient({
    Dio? dio,
    this.baseUrl = 'http://localhost:8000',
  }) : _dio = dio ?? Dio();

  final Dio _dio;
  final String baseUrl;

  String _buildUrl(String path) =>
      '${baseUrl.replaceAll(RegExp(r'/+$'), '')}/${path.replaceFirst(RegExp(r'^/'), '')}';

  Future<Response<T>> get<T>(String path) {
    return _dio.get<T>(_buildUrl(path));
  }

  Future<Response<T>> post<T>(String path, {Object? data}) {
    return _dio.post<T>(_buildUrl(path), data: data);
  }
}
