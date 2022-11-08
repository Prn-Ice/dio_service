import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio_service/src/exceptions/exceptions.dart';
import 'package:fpdart/fpdart.dart';
import 'package:humanizer/humanizer.dart';

/// Function which takes a Dio response object and an exception and returns
/// an optional [AppHttpClientException], optionally mapping the response
/// to a custom exception.
typedef ResponseExceptionMapper
    = AppNetworkResponseException<DioError, Map<String, dynamic>>? Function(
  Response<dynamic>,
  DioError,
);

class ExceptionMapper {
  /// Map Dio exceptions (and any other exceptions) to an exception type
  /// supported by our application.
  static AppHttpClientException mapException({
    required Object exception,
    ResponseExceptionMapper? exceptionMapper,
  }) {
    final usableMapper = exceptionMapper ?? _defaultResponseExceptionMapper;

    if (exception is DioError) {
      switch (exception.type) {
        case DioErrorType.cancel:
          return AppNetworkException(
            reason: AppNetworkExceptionReason.canceled,
            exception: exception,
          );
        case DioErrorType.connectTimeout:
        case DioErrorType.receiveTimeout:
        case DioErrorType.sendTimeout:
          return AppNetworkException(
            reason: AppNetworkExceptionReason.timedOut,
            exception: exception,
          );
        case DioErrorType.response:
          // For DioErrorType.response, we are guaranteed to have a
          // response object present on the exception.
          final response = exception.response;
          if (response == null) {
            // This should never happen, judging by the current source code
            // for Dio.
            return AppNetworkResponseException<DioError, Map<String, dynamic>>(
              exception: exception,
            );
          }
          return usableMapper?.call(response, exception) ??
              AppNetworkResponseException(
                exception: exception,
                statusCode: response.statusCode,
                data: response.data,
              );
        case DioErrorType.other:
          return AppHttpClientException(exception: exception);
      }
    } else {
      if (exception is SocketException) {
        return AppHttpClientException(
          exception: exception,
          message: 'Please check your internet connection',
        );
      }

      return AppHttpClientException(
        exception: exception is Exception
            ? exception
            : Exception('Unknown exception ocurred'),
      );
    }
  }

  static ResponseExceptionMapper? get _defaultResponseExceptionMapper {
    return (response, e) {
      return Option<Map<String, dynamic>>.tryCatch(
        () => response.data as Map<String, dynamic>,
      ).match(
        () => null,
        (t) {
          if (response.statusCode == 500) {
            return InternalServerException(
              message: 'Unexpected error occurred',
              exception: e,
            );
          } else if (response.statusCode == 422) {
            final message = (t['message'] ?? 'Please verify submitted details')
                .toString()
                .toSentenceCase();

            return UnprocessableEntityException(message: message, exception: e);
          } else if (response.statusCode == 400) {
            final message = (t['message'] ?? 'Please verify submitted details')
                .toString()
                .toSentenceCase();

            return BadRequestException(message: message, exception: e);
          } else if (response.statusCode == 401) {
            return UnauthorizedException(
              message: 'You are not authorized to perform this request, '
                  'please login again',
              exception: e,
            );
          } else if (response.statusCode == 404) {
            return NotFoundException(
              message: 'The requested resource could not be found',
              exception: e,
            );
          } else if (response.statusCode == 403) {
            final message =
                (t['message'] ?? 'You are not permitted to make this request')
                    .toString()
                    .toSentenceCase();

            return ForbiddenException(message: message, exception: e);
          }

          return null;
        },
      );
    };
  }
}
