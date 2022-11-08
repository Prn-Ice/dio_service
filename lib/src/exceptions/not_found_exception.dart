import 'package:dio/dio.dart';
import 'package:dio_service/dio_service.dart';

class NotFoundException<T> extends AppNetworkResponseException<DioError, T> {
  NotFoundException({
    required super.message,
    required super.exception,
  });
}
