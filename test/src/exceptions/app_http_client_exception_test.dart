import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio_service/dio_service.dart';
import 'package:test/test.dart';

void main() {
  group('AppHttpClientException', () {
    group('parseException', () {
      test(
        'returns unknown exception occurred '
        'when error object is not a DioError',
        () {
          final e = Exception();

          expect(
            AppHttpClientException.parseException(e),
            'Unknown exception occurred',
          );
        },
      );

      test(
        'returns unknown exception occurred '
        'when error object is a DioError '
        'but e.error is not an AppHttpClientException',
        () {
          final e = DioError(requestOptions: RequestOptions(path: '/'));

          expect(
            AppHttpClientException.parseException(e),
            'Unknown exception occurred',
          );
        },
      );

      test(
        'returns check internet connection '
        'when error object is a DioError '
        'and e.error is a AppHttpClientException '
        'and e.error.exception.error is a SocketException ',
        () {
          final e = DioError(
            requestOptions: RequestOptions(path: '/'),
            error: AppHttpClientException<Exception>(
              exception: DioError(
                requestOptions: RequestOptions(path: '/'),
                error: const SocketException('error'),
              ),
            ),
          );

          expect(
            AppHttpClientException.parseException(e),
            'Pleach check your internet connection!',
          );
        },
      );

      test(
        'returns exception.toString() '
        'when error object is a DioError '
        'and e.error is a AppHttpClientException '
        'and e.error.exception.error is not a SocketException ',
        () {
          final e = DioError(
            requestOptions: RequestOptions(path: '/'),
            error: AppHttpClientException<Exception>(exception: Exception()),
          );

          expect(
            AppHttpClientException.parseException(e),
            (e.error as AppHttpClientException).exception.toString(),
          );
        },
      );
    });
  });
}
