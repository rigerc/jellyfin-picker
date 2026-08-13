import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:jellyfin_picker/core/navigation/app_router.dart';
import 'package:jellyfin_picker/core/theme/candy_theme.dart';
import 'package:jellyfin_picker/features/connection/domain/repositories/connection_repository.dart';
import 'package:jellyfin_picker/features/connection/domain/entities/stored_session.dart';
import 'package:jellyfin_picker/features/connection/presentation/connection_cubit.dart';
import 'package:jellyfin_picker/features/connection/presentation/connection_page.dart';
import 'package:jellyfin_picker/l10n/generated/app_localizations.dart';
import 'package:jellyfin_picker/presentation/home_page.dart';

/// Builds the concrete app router at the composition boundary.
typedef AuthenticatedBuilder =
    Widget Function(BuildContext context, StoredSession session);

GoRouter buildAppRouter({
  ConnectionRepository? connectionRepository,
  AuthenticatedBuilder? authenticatedBuilder,
}) {
  final routes = <RouteBase>[
    GoRoute(
      path: AppRoutePaths.home,
      builder: (context, state) => const HomePage(),
    ),
  ];
  if (connectionRepository != null) {
    routes.add(
      GoRoute(
        path: AppRoutePaths.connection,
        builder: (context, state) => BlocProvider(
          create: (_) => ConnectionCubit(connectionRepository),
          child: ConnectionPage(
            onExplore: (session) =>
                context.go(AppRoutePaths.catalog, extra: session),
          ),
        ),
      ),
    );
    routes.add(
      GoRoute(
        path: AppRoutePaths.catalog,
        builder: (context, state) {
          final session = state.extra;
          if (session is! StoredSession || authenticatedBuilder == null) {
            return const HomePage();
          }
          return authenticatedBuilder(context, session);
        },
      ),
    );
  }
  return GoRouter(
    initialLocation: connectionRepository == null
        ? AppRoutePaths.home
        : AppRoutePaths.connection,
    routes: routes,
  );
}

/// Root widget for the Jellyfilter application.
final class JellyfilterApp extends StatefulWidget {
  const JellyfilterApp({required this.router, this.onDispose, super.key});

  final GoRouter router;
  final FutureOr<void> Function()? onDispose;

  @override
  State<JellyfilterApp> createState() => _JellyfilterAppState();
}

final class _JellyfilterAppState extends State<JellyfilterApp> {
  @override
  void dispose() {
    widget.onDispose?.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      routerConfig: widget.router,
      theme: buildCandyLightTheme(),
      darkTheme: buildCandyDarkTheme(),
      themeMode: ThemeMode.system,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
