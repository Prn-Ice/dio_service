import 'package:dio/dio.dart';
import 'package:dio_service/dio_service.dart';

class BadRequestException<T> extends AppNetworkResponseException<DioError, T> {
  BadRequestException({
    required super.message,
    required super.exception,
  });
}
