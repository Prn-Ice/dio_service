import 'package:dio/dio.dart';
import 'package:dio_service/dio_service.dart';

class InternalServerException
    extends AppNetworkResponseException<DioError, Map<String, dynamic>> {
  InternalServerException({
    required super.message,
    required super.exception,
  });
}
