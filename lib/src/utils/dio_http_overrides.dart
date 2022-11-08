import 'dart:io';

class DioHttpOverrides extends HttpOverrides {
  DioHttpOverrides({
    required this.baseUrl,
  });

  final String baseUrl;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final baseUrlParsed =
        baseUrl.replaceAll('https://', '').replaceAll('/', '');

    return super.createHttpClient(context)
      ..badCertificateCallback =
          ((X509Certificate cert, String host, int port) {
        final isValidHost = [baseUrlParsed].contains(host);

        return isValidHost;
      });
  }
}
