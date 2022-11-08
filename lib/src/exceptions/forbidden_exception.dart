import 'package:dio/dio.dart';
import 'package:dio_service/dio_service.dart';

class ForbiddenException<T> extends AppNetworkResponseException<DioError, T> {
  ForbiddenException({
    required super.message,
    required super.exception,
  });
}
