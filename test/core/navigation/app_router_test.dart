import 'package:flutter_test/flutter_test.dart';
import 'package:jellyfin_picker/app.dart';
import 'package:jellyfin_picker/core/navigation/app_router.dart';

void main() {
  test('should expose stable paths when route constants are read', () {
    expect(AppRoutePaths.home, '/');
    expect(AppRoutePaths.connection, '/connection');
    expect(AppRoutePaths.catalog, '/catalog');
  });

  test(
    'should construct the home route when app composition creates a router',
    () {
      final router = buildAppRouter();

      expect(router.routeInformationProvider.value.uri.path, '/');
      router.dispose();
    },
  );

  test(
    'should retain one router when the app receives an injected instance',
    () {
      final router = buildAppRouter();
      final app = JellyfinPickerApp(router: router);

      expect(app.router, same(router));
      router.dispose();
    },
  );
}
