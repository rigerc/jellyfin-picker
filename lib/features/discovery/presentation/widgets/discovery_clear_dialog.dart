import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jellyfin_picker/features/discovery/application/discovery_cubit.dart';
import 'package:jellyfin_picker/l10n/generated/app_localizations.dart';

Future<void> confirmClearDiscovery(BuildContext context) async {
  final localization = AppLocalizations.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      content: Text(localization.discoveryClearConfirmation),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(localization.discoveryCancelLabel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(localization.discoveryConfirmClearLabel),
        ),
      ],
    ),
  );
  if (confirmed == true && context.mounted) {
    await context.read<DiscoveryCubit>().clearDiscovery();
  }
}
