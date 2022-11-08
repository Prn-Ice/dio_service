# dio_service

[![style: very good analysis][very_good_analysis_badge]][very_good_analysis_link]
[![License: MIT][license_badge]][license_link]

<!-- FIXME(Prn-Ice): Adapt readme from https://github.com/definitelyokay/app_http_client -->

## The Error Handling Mechanism

The real meat-and-potatoes of our wrapper is hiding in the private method `_mapException()`. It takes one parameter named `method` which is a callback (that should call a Dio method).

The `_mapException` proceeds to return the awaited callback's result via `return await method();`, catching any errors in the process. If no errors occur, it just returns whatever the callback returned (which in this case will be the response object returned by the Dio method that the callback called).

If an error occurs, things get much more interesting. The error handling that takes place inside the wrapper is dependent on your http library of choice. Since we're using Dio, we know that Dio already wraps all of its errors into `DioError` objects.

Dio's errors are perfectly decent, but we don't want the error handling our app's codebase to be directly tied to any particular http library. If you need to change the http library you're using, it's much easier to write another wrapper class which satisfies a similar interface than it is to hunt for http-library-specific error handling throughout the app's code.

_Note: There is one caveat—because our methods directly wrap Dio's methods, the parameters have types which are only found inside the Dio library, such as `Options`, `CancelToken`, `ProgressCallback`, etc. Our app's service code which calls our wrapper will still be tied to Dio when it passes in these objects, but changing such details strictly within the service layer should be fairly straightforward in the event of swapping over to another wrapper and http library._

_We could have stopped and written a platform-agnostic http request interface library, but the payoff for doing so would be minimal compared to the enormous effort required. While it would spare you from having to touch any service code at all if you suddenly switched http libraries, swapping dependencies like that just doesn't seem like a frequent enough occurrence to merit an entire library of carefully constructed interfaces. You'd also have to create and maintain the mappings from the platform-agnostic classes to the platform specific ones for every http library you intended to support..._

The rest of `_mapException` proceeds to map each type of Dio error into one of the 3 types of errors we care about. Everything is fairly straightforward, with the exception of response errors.

Our wrapper would not be very useful if that was all it did. The main reason we created the wrapper is to allow the code using the wrapper to provide custom response error handling. The `_mapException` method uses some optional chaining and null coalescing operators to delegate any Dio response error containing a valid response object (with the expected response type) to an optional mapping function—if such a callback is provided in the wrapper's constructor: `ResponseExceptionMapper? exceptionMapper`.

The `exceptionMapper` function receives two arguments: the first is the Dio response object of type `Response<T>` (where `T` is the type of data passed into the wrapper, usually `Map<String, dynamic>` for JSON) and the second is the original exception which was caught.

In case you weren't sure, you can specify the type of the type of the data you expect Dio to return by passing in the expected type when you call our wrapper's generic delegate methods:

```dart
// Perform a GET request with a JSON return type: Map<String, dynamic>
final response = appHttpClient.get<Map<String, dynamic>>('url');
```

The following are some of the response types Dio supports:

```dart
client.get<Map<String, dynamic>>() // JSON data
client.get<String>()               // Plain text data
client.get<ResponseBody>()         // Response stream
client.get<List<int>>()            // Raw binary data (as list of bytes)
```

You can implement the `exceptionMapper` function however you like. If you don't know what to do with the Dio response, simply return `null` to let `AppHttpClient` wrap the response error using the default error handling logic. If your `exceptionMapper` function is able to recognize a certain kind of response, it is welcome to return an instance or subclass of `AppNetworkResponseException` which better represents the error.

In the next section, we will construct an example `exceptionMapper` which unwraps a certain kind of backend error it receives.

### Handling the Errors

Imagine you've defined the following service which calls your internet-of-things-enabled teapot and tells it to brew `coffee` erroneously:

```dart
import 'package:dio/dio.dart';

class TeaService {
  TeaService({required this.client});

  final AppHttpClient client;

  Future<Map<String, dynamic>?> brewTea() async {
    final response = await client.post<Map<String, dynamic>>(
      '/tea',
      data: {
        'brew': 'coffee',
      },
    );
    return response.data;
  }
}
```

Because you've made the wrong request, the teapot should respond back with a [418 I'm a Teapot][teapot-error] error. Perhaps it even replies with json data in its response body:

```json
{
  "message": "I can't brew 'coffee'"
}
```

Let's pretend, while we're at it, that you want to catch these specific errors and wrap them in an error class, preserving the server's error message so that you can show it to the user of your remote tea-brewing app.

This is all you have to do:

```dart
class TeapotResponseException extends AppNetworkResponseException {
  TeapotResponseException({
    required String message,
  }) : super(exception: Exception(message));
}

final client = AppHttpClient(
  client: Dio(),
  exceptionMapper: <T>(Response<T> response) {
    final data = response.data;
    if (data != null && data is Map<String, dynamic>) {
      // We only map responses containing data with a status code of 418:
      return TeapotResponseException(
        message: data['message'] ?? 'I\'m a teapot',
      );
    }
    return null;
  },
);
```

_Note: Because [Dart generic types are reified][reified-types], you can check the type of the response data inside the `exceptionMapper` function._

To use your service and consume teapot errors, this is all you need to do:

```dart
final teaService = TeaService(client: client);

try {
  await teaService.brewTea();
} on TeapotResponseException catch (teapot) {
  print(teapot.exception.toString());
} catch (e) {
  print('Some other error');
}
```

Note that you can access the error's data since you created a custom `TeapotResponseException` class. On top of that, it integrates seamlessly with [Dart's try/catch clauses][catch-error]. The `try`/`catch` clauses Dart provides out of the box are incredibly useful for catching specific types of errors—exactly what our wrapper helps us with!

So that's pretty much it—I like to think it's worth the hassle of creating a custom http client wrapper. 😜

[license_badge]: https://img.shields.io/badge/license-MIT-blue.svg
[license_link]: https://opensource.org/licenses/MIT
[very_good_analysis_badge]: https://img.shields.io/badge/style-very_good_analysis-B22C89.svg
[very_good_analysis_link]: https://pub.dev/packages/very_good_analysis
