import 'dart:io';

import 'package:dio_service/dio_service.dart';

/// Base exception for all exceptions thrown by AppHttpClient.
/// You can create instances of this to create "unknown" error exceptions.
///
/// ```
///   ┌──────────────────────────┐
///   │  AppHttpClientException  │
///   └──────────────────────────┘
///                 ▲
///                 │
///   ┌──────────────────────────┐
///   │   AppNetworkException    │
///   └──────────────────────────┘
///                 ▲
///                 │
/// ┌───────────────────────────────┐
/// │  AppNetworkResponseException  │
/// └───────────────────────────────┘
/// ```
class AppHttpClientException<OriginalException extends Exception>
    implements Exception {
  /// Create a new application http client exception with the specified
  /// underlying [exception].
  AppHttpClientException({required this.exception, this.message});

  /// Exception which was caught.
  final OriginalException exception;

  /// Optional message
  final String? message;

  /// Get proper exception string from `AppHttpClientException`.
  static String parseException(
    Object e, {
    StackTrace? s,
    ResponseExceptionMapper? responseExceptionMapper,
  }) {
    final parsedException = ExceptionMapper.mapException(
      exception: e,
      exceptionMapper: responseExceptionMapper,
    );

    if (parsedException is AppNetworkResponseException) {
      return parsedException.message ?? 'Unknown exception occurred';
    }

    if (parsedException is AppNetworkException) {
      switch (parsedException.reason) {
        case AppNetworkExceptionReason.canceled:
          return 'The request was cancelled';
        case AppNetworkExceptionReason.responseError:
          return 'The request completed with an error';
        case AppNetworkExceptionReason.timedOut:
          return 'The request timed out';
      }
    }

    if (parsedException.exception is SocketException) {
      return parsedException.message ?? 'Unknown exception occurred';
    }

    return 'Unknown exception occurred';
  }
}

/// Reason for a network exception.
enum AppNetworkExceptionReason {
  /// A request cancellation is responsible for the exception.
  canceled,

  /// A timeout error is responsible for the exception.
  timedOut,

  /// A response error is responsible for the exception.
  responseError,
}

/// Network error.
class AppNetworkException<OriginalException extends Exception>
    extends AppHttpClientException<OriginalException> {
  /// Create a network exception.
  AppNetworkException({
    required this.reason,
    required super.exception,
    super.message,
  });

  /// The reason the network exception ocurred.
  final AppNetworkExceptionReason reason;
}

/// Response exception.
class AppNetworkResponseException<OriginalException extends Exception, DataType>
    extends AppNetworkException<OriginalException> {
  /// Create a new response exception with the specified [statusCode],
  /// original [exception], and response [data].
  AppNetworkResponseException({
    required super.exception,
    super.message,
    this.statusCode,
    this.data,
  }) : super(reason: AppNetworkExceptionReason.responseError);

  /// Response data, if any.
  final DataType? data;

  /// HTTP status code, if any.
  final int? statusCode;

  /// True if the response contains data.
  bool get hasData => data != null;

  /// If the status code is null, returns false. Otherwise, allows the
  /// given closure [evaluator] to validate the given http integer status code.
  ///
  /// Usage:
  /// ```
  /// final isValid = responseException.validateStatusCode(
  ///   (statusCode) => statusCode >= 200 && statusCode < 300,
  /// );
  /// ```
  bool validateStatusCode(bool Function(int statusCode) evaluator) {
    final statusCode = this.statusCode;
    if (statusCode == null) return false;

    return evaluator(statusCode);
  }
}
