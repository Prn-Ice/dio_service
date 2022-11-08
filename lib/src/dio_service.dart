import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

class DioService {
  DioService({required this.dio}) {
    _init();
  }

  final Dio dio;

  void _init() {
    dio.options.connectTimeout = 20000; //20s
    dio.options.receiveTimeout = 30000; //30s

    dio.interceptors.add(
      PrettyDioLogger(
        responseBody: false,
        logPrint: (_) => log(_.toString()),
      ),
    );
  }
}
