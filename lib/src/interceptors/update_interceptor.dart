import 'package:dio/dio.dart';

/// An [Interceptor] that intercepts responses. If [refreshCheck] is true,
/// [refreshFunction] is called.
abstract class UpdateInterceptor extends Interceptor {
  /// The paths that should be checked for refresh.
  /// If the path of the response is contained in this list,
  /// we probably want to execute [refreshFunction].
  List<String> get refreshLinks;

  /// The function that should be called if [refreshCheck] return true.
  Future<void> refreshFunction();

  /// The function that should be called to check if the [refreshFunction]
  /// should be called.
  ///
  /// This function allows for executing custom logic checks,
  /// if none are required, just return [pathContainsRefreshLink].
  bool refreshCheck(Response<dynamic> response);

  /// Returns true if path of the response is contained in [refreshLinks]
  bool pathContainsRefreshLink(Response<dynamic> response) {
    try {
      final path = response.requestOptions.path;

      return refreshLinks.contains(path);
    } catch (e) {
      return false;
    }
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    if (refreshCheck(response)) {
      refreshFunction();
    }

    return super.onResponse(response, handler);
  }
}
