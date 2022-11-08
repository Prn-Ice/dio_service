import 'package:dio/dio.dart';
import 'package:dio_service/dio_service.dart';

class UnauthorizedException<T>
    extends AppNetworkResponseException<DioError, T> {
  UnauthorizedException({
    required super.message,
    required super.exception,
  });
}
