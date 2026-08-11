import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jellyfin_picker/core/keys/widget_keys.dart';
import 'package:jellyfin_picker/core/theme/candy_theme.dart';
import 'package:jellyfin_picker/features/connection/domain/entities/connection_request.dart';
import 'package:jellyfin_picker/features/connection/domain/entities/session_summary.dart';
import 'package:jellyfin_picker/features/connection/domain/entities/stored_session.dart';
import 'package:jellyfin_picker/features/connection/domain/failures/connection_failure.dart';
import 'package:jellyfin_picker/features/connection/presentation/connection_cubit.dart';
import 'package:jellyfin_picker/l10n/generated/app_localizations.dart';

/// Connection form with an injected [ConnectionCubit].
final class ConnectionPage extends StatelessWidget {
  const ConnectionPage({this.cubit, this.onExplore, super.key});

  final ConnectionCubit? cubit;
  final ValueChanged<StoredSession>? onExplore;

  @override
  Widget build(BuildContext context) {
    final injectedCubit = cubit;
    if (injectedCubit == null) {
      return _ConnectionForm(onExplore: onExplore);
    }
    return BlocProvider.value(
      value: injectedCubit,
      child: _ConnectionForm(onExplore: onExplore),
    );
  }
}

final class _ConnectionForm extends StatefulWidget {
  const _ConnectionForm({this.onExplore});

  final ValueChanged<StoredSession>? onExplore;

  @override
  State<_ConnectionForm> createState() => _ConnectionFormState();
}

final class _ConnectionFormState extends State<_ConnectionForm> {
  final _serverUrlController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    unawaited(context.read<ConnectionCubit>().restore());
  }

  @override
  void dispose() {
    _serverUrlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);
    final state = context.watch<ConnectionCubit>().state;
    final theme = Theme.of(context);
    final tokens = theme.extension<CandyThemeTokens>();
    final isSubmitting = state is ConnectionSubmitting;
    final needsPrivateHttpConfirmation =
        state is ConnectionNeedsPrivateHttpConfirmation;
    final connectionFailure = state is ConnectionFailureState
        ? state.failure
        : null;
    final needsReauthentication = state is ConnectionReauthenticationRequired;

    if (state case ConnectionAuthenticated(:final session, :final summary)) {
      return _AuthenticatedSummary(
        summary: summary,
        onExplore: widget.onExplore == null
            ? null
            : () => widget.onExplore?.call(session),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(CandySpacing.page),
          children: <Widget>[
            Text(
              localization.connectionTitle,
              style: theme.textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: CandySpacing.section),
            Card(
              key: WidgetKeys.connectionForm,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  tokens?.cardRadius ?? CandyShapes.card,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(CandySpacing.page),
                child: Column(
                  spacing: CandySpacing.compact,
                  children: <Widget>[
                    _ServerUrlField(controller: _serverUrlController),
                    _UsernameField(controller: _usernameController),
                    _PasswordField(controller: _passwordController),
                    _SubmitButton(
                      isSubmitting: isSubmitting,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
            ),
            if (needsPrivateHttpConfirmation)
              _PrivateHttpWarning(onConfirm: _confirmPrivateHttp),
            if (connectionFailure != null)
              _ConnectionError(
                message: _failureMessage(localization, connectionFailure),
              ),
            if (needsReauthentication)
              _ConnectionError(
                message: localization.connectionNeedsReauthenticationLabel,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    await context.read<ConnectionCubit>().submit(
      ConnectionRequest(
        baseUrl: _serverUrlController.text,
        username: _usernameController.text,
        password: _passwordController.text,
      ),
    );
    if (mounted) {
      _passwordController.clear();
    }
  }

  Future<void> _confirmPrivateHttp() async {
    await context.read<ConnectionCubit>().confirmPrivateHttp();
    if (mounted) {
      _passwordController.clear();
    }
  }

  String _failureMessage(
    AppLocalizations localization,
    ConnectionFailure failure,
  ) {
    return switch (failure) {
      InvalidServerUrlFailure() => localization.connectionInvalidUrlError,
      PublicHttpFailure() => localization.connectionPublicHttpError,
      PrivateHttpConfirmationRequiredFailure() =>
        localization.connectionPrivateHttpWarning,
      UnreachableFailure() => localization.connectionUnreachableError,
      ServerFailure() => localization.connectionServerError,
      InvalidCertificateFailure() =>
        localization.connectionInvalidCertificateError,
      IncompatibleServerFailure() => localization.connectionIncompatibleError,
      UnsafeRedirectFailure() => localization.connectionUnsafeRedirectError,
      InvalidCredentialsFailure() =>
        localization.connectionInvalidCredentialsError,
      ExpiredSessionFailure() => localization.connectionExpiredSessionError,
      StorageFailure() => localization.connectionStorageError,
    };
  }
}

final class _AuthenticatedSummary extends StatelessWidget {
  const _AuthenticatedSummary({required this.summary, this.onExplore});

  final SessionSummary summary;
  final VoidCallback? onExplore;

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Card(
            key: WidgetKeys.connectionSummary,
            margin: const EdgeInsets.all(CandySpacing.page),
            child: Padding(
              padding: const EdgeInsets.all(CandySpacing.page),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: CandySpacing.compact,
                children: <Widget>[
                  Text(
                    localization.connectionSummaryTitle,
                    style: theme.textTheme.headlineSmall,
                  ),
                  Text(
                    '${localization.connectionSummaryServerLabel}: ${summary.serverUrl}',
                  ),
                  Text(
                    '${localization.connectionSummaryUserLabel}: ${summary.username}',
                  ),
                  if (onExplore != null)
                    FilledButton.icon(
                      key: WidgetKeys.connectionExploreButton,
                      onPressed: onExplore,
                      icon: const Icon(Icons.explore_outlined),
                      label: Text(localization.connectionExploreLabel),
                    ),
                  FilledButton.tonal(
                    key: WidgetKeys.connectionLogoutButton,
                    onPressed: () => context.read<ConnectionCubit>().logout(),
                    child: Text(localization.connectionLogoutLabel),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class _ServerUrlField extends StatelessWidget {
  const _ServerUrlField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: WidgetKeys.connectionUrlField,
      controller: controller,
      keyboardType: TextInputType.url,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context).connectionServerUrlLabel,
      ),
    );
  }
}

final class _UsernameField extends StatelessWidget {
  const _UsernameField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: WidgetKeys.connectionUsernameField,
      controller: controller,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context).connectionUsernameLabel,
      ),
    );
  }
}

final class _PasswordField extends StatelessWidget {
  const _PasswordField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: WidgetKeys.connectionPasswordField,
      controller: controller,
      obscureText: true,
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context).connectionPasswordLabel,
      ),
    );
  }
}

final class _SubmitButton extends StatelessWidget {
  const _SubmitButton({required this.isSubmitting, required this.onPressed});

  final bool isSubmitting;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        key: WidgetKeys.connectionSubmitButton,
        onPressed: isSubmitting ? null : onPressed,
        child: Text(
          isSubmitting
              ? localization.connectionConnectingLabel
              : localization.connectionSubmitLabel,
        ),
      ),
    );
  }
}

final class _PrivateHttpWarning extends StatelessWidget {
  const _PrivateHttpWarning({required this.onConfirm});

  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(CandySpacing.page),
        child: Column(
          spacing: CandySpacing.compact,
          children: <Widget>[
            Text(localization.connectionPrivateHttpWarning),
            FilledButton.tonal(
              key: WidgetKeys.connectionConfirmPrivateHttpButton,
              onPressed: onConfirm,
              child: Text(localization.connectionContinuePrivateHttpLabel),
            ),
          ],
        ),
      ),
    );
  }
}

final class _ConnectionError extends StatelessWidget {
  const _ConnectionError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: WidgetKeys.connectionError,
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.only(top: CandySpacing.compact),
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }
}
