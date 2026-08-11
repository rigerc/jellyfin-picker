import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jellyfin_picker/core/theme/candy_theme.dart';
import 'package:jellyfin_picker/features/connection/domain/entities/connection_request.dart';
import 'package:jellyfin_picker/features/connection/domain/entities/stored_session.dart';
import 'package:jellyfin_picker/features/connection/domain/failures/connection_failure.dart';
import 'package:jellyfin_picker/features/connection/domain/repositories/connection_repository.dart';
import 'package:jellyfin_picker/features/connection/presentation/connection_cubit.dart';
import 'package:jellyfin_picker/features/connection/presentation/connection_page.dart';
import 'package:jellyfin_picker/l10n/generated/app_localizations.dart';
import '../../../shared/connection_robot.dart';
import '../../../shared/fake_connection_repository.dart';

void main() {
  testWidgets('should render accessible connection fields when opened', (
    tester,
  ) async {
    final robot = ConnectionRobot(tester);
    final cubit = ConnectionCubit(FakeConnectionRepository());

    await tester.pumpWidget(
      MaterialApp(
        theme: buildCandyTheme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ConnectionPage(cubit: cubit),
      ),
    );

    robot.expectFormVisible();
    robot.expectAccessibleFieldsVisible();
    await cubit.close();
  });

  testWidgets(
    'should render recovery feedback when connection needs confirmation',
    (tester) async {
      final robot = ConnectionRobot(tester);
      final cubit = ConnectionCubit(
        FakeConnectionRepository(
          result: const PrivateHttpConfirmationResult(
            'http://192.168.1.20:8096',
          ),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: buildCandyTheme(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ConnectionPage(cubit: cubit),
        ),
      );
      await tester.pumpAndSettle();
      await cubit.submit(
        const ConnectionRequest(
          baseUrl: 'http://192.168.1.20:8096',
          username: 'alice',
          password: 'password',
        ),
      );
      await tester.pump();
      robot.expectPrivateHttpWarningVisible();

      final errorCubit = ConnectionCubit(
        FakeConnectionRepository(
          result: const ConnectionFailureResult(UnreachableFailure()),
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: buildCandyTheme(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ConnectionPage(cubit: errorCubit),
        ),
      );
      await tester.pumpAndSettle();
      await errorCubit.submit(
        const ConnectionRequest(
          baseUrl: 'https://example.test',
          username: 'alice',
          password: 'password',
        ),
      );
      await tester.pump();
      robot.expectErrorVisible();
      await cubit.close();
      await errorCubit.close();
    },
  );

  testWidgets('should clear the password after a connection result', (
    tester,
  ) async {
    final robot = ConnectionRobot(tester);
    final cubit = ConnectionCubit(
      FakeConnectionRepository(
        result: const ConnectionFailureResult(UnreachableFailure()),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: buildCandyTheme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ConnectionPage(cubit: cubit),
      ),
    );
    await tester.pumpAndSettle();
    await robot.submitCredentials();
    robot.expectPasswordCleared();
    await cubit.close();
  });

  testWidgets(
    'should confirm private HTTP and show the authenticated summary',
    (tester) async {
      final robot = ConnectionRobot(tester);
      final repository = ConfirmingConnectionRepository();
      final cubit = ConnectionCubit(repository);

      await tester.pumpWidget(
        MaterialApp(
          theme: buildCandyTheme(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ConnectionPage(cubit: cubit),
        ),
      );
      await tester.pumpAndSettle();

      await robot.submitPrivateHttpCredentials();
      robot.expectPrivateHttpWarningVisible();
      await robot.confirmPrivateHttpAndExpectPasswordCleared();

      robot.expectPrivateHttpWarningAbsent();
      robot.expectSummaryVisible();
      expect(repository.lastRequest?.allowPrivateHttp, isTrue);
      await cubit.close();
    },
  );
}

final class ConfirmingConnectionRepository implements ConnectionRepository {
  ConnectionRequest? lastRequest;

  @override
  Future<ConnectionResult> connect(ConnectionRequest request) async {
    lastRequest = request;
    if (!request.allowPrivateHttp) {
      return const PrivateHttpConfirmationResult('http://192.168.1.20:8096');
    }
    return const ConnectionSuccess(
      StoredSession(
        serverUrl: 'http://192.168.1.20:8096',
        accessToken: 'token',
        userId: 'user-id',
        username: 'alice',
        deviceId: 'device-id',
      ),
    );
  }

  @override
  Future<SessionRestoreResult> restoreSession() async =>
      const NoStoredSession();

  @override
  Future<LogoutResult> logout() async =>
      const LogoutCompleted(remoteSucceeded: true);
}
