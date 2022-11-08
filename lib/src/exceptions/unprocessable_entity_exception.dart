import 'package:dio/dio.dart';
import 'package:dio_service/dio_service.dart';

class UnprocessableEntityException<T>
    extends AppNetworkResponseException<DioError, T> {
  UnprocessableEntityException({
    required super.message,
    required super.exception,
  });
}
