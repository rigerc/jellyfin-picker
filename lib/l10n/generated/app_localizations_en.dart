// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Jellyfilter';

  @override
  String get homeHeadline => 'Pick something great';

  @override
  String get homeDescription =>
      'A playful way to discover your Jellyfin library.';

  @override
  String get connectionTitle => 'Connect your Jellyfin';

  @override
  String get connectionServerUrlLabel => 'Server address';

  @override
  String get connectionUsernameLabel => 'Username';

  @override
  String get connectionPasswordLabel => 'Password';

  @override
  String get connectionSubmitLabel => 'Connect';

  @override
  String get connectionPrivateHttpWarning =>
      'This local HTTP connection is unencrypted. Continue only if you trust this private network.';

  @override
  String get connectionContinuePrivateHttpLabel => 'Continue on local network';

  @override
  String get connectionConnectingLabel => 'Connecting…';

  @override
  String get connectionConnectedLabel => 'Connected';

  @override
  String get connectionNeedsReauthenticationLabel =>
      'Your session expired. Please connect again.';

  @override
  String get connectionUnreachableError =>
      'We could not reach that server. Check the address and network.';

  @override
  String get connectionServerError =>
      'The Jellyfin server is temporarily unavailable. Try again shortly.';

  @override
  String get connectionInvalidCertificateError =>
      'The server certificate is not trusted. Use a valid HTTPS certificate.';

  @override
  String get connectionIncompatibleError =>
      'That server is not a compatible Jellyfin server.';

  @override
  String get connectionUnsafeRedirectError =>
      'The server redirected the request unsafely. Check the address and try again.';

  @override
  String get connectionInvalidCredentialsError =>
      'Those credentials were not accepted.';

  @override
  String get connectionExpiredSessionError =>
      'Your session expired. Please connect again.';

  @override
  String get connectionInvalidUrlError =>
      'Enter a valid Jellyfin server address.';

  @override
  String get connectionPublicHttpError =>
      'Public HTTP connections are not allowed. Use HTTPS.';

  @override
  String get connectionStorageError =>
      'Secure session storage is unavailable on this device.';

  @override
  String get connectionUnknownError =>
      'We could not complete the connection. Try again.';

  @override
  String get connectionSummaryTitle => 'Connected to Jellyfin';

  @override
  String get connectionSummaryServerLabel => 'Server';

  @override
  String get connectionSummaryUserLabel => 'Signed in as';

  @override
  String get connectionLogoutLabel => 'Log out';

  @override
  String get connectionExploreLabel => 'Explore library';

  @override
  String get discoveryTitle => 'Movie night starts here';

  @override
  String discoveryHeaderSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count titles ready to explore.',
      one: '1 title ready to explore.',
    );
    return '$_temp0';
  }

  @override
  String get discoveryGridLabel => 'Grid';

  @override
  String get discoverySwipeLabel => 'Swipe';

  @override
  String get discoveryShuffleLabel => 'Shuffle';

  @override
  String get discoveryLikeLabel => 'Like';

  @override
  String get discoveryRejectLabel => 'Not this one';

  @override
  String get discoveryRevealLabel => 'Reveal a pick';

  @override
  String get discoveryFavoriteAddLabel => 'Add to Jellyfin favorites';

  @override
  String get discoveryFavoriteRemoveLabel => 'Remove from Jellyfin favorites';

  @override
  String get discoveryFavoriteError =>
      'Jellyfin could not update that favorite. Try again.';

  @override
  String get catalogLoadingLabel => 'Loading your Jellyfin library…';

  @override
  String get catalogErrorTitle => 'Your library is unavailable';

  @override
  String get catalogErrorDescription =>
      'Check the Jellyfin connection, then reconnect to refresh current results.';

  @override
  String get catalogReconnectLabel => 'Reconnect';

  @override
  String discoveryDetailsLabel(String title) {
    return 'Open details for $title';
  }

  @override
  String get discoveryNoCandidatesTitle => 'No titles fit yet';

  @override
  String get discoveryNoCandidatesDescription =>
      'Adjust your filters or clear dismissed titles to keep exploring.';

  @override
  String get discoveryClearLabel => 'Clear discovery data';

  @override
  String get discoveryFiltersLabel => 'Filters';

  @override
  String get discoveryQuickRecentLabel => 'Added in last 30 days';

  @override
  String get discoveryQuickUnwatchedLabel => 'Unwatched';

  @override
  String get discoveryQuickFavoritesLabel => 'Favorites';

  @override
  String get discoveryActiveFilterLabel => 'Filters active';

  @override
  String get discoveryFilterSheetTitle => 'Shape tonight\'s lineup';

  @override
  String get discoverySearchTitleLabel => 'Search titles';

  @override
  String get discoverySortLabel => 'Sort by';

  @override
  String get discoverySortDefaultLabel => 'Recommended';

  @override
  String get discoverySortRecentlyAddedLabel => 'Recently added';

  @override
  String get discoverySortTitleLabel => 'Title';

  @override
  String get discoverySortReleaseYearLabel => 'Release year';

  @override
  String get discoverySortCommunityRatingLabel => 'Community rating';

  @override
  String get discoverySortRuntimeLabel => 'Runtime';

  @override
  String get discoveryAddedWithinLabel => 'Added within';

  @override
  String get discoveryAddedWithinAnyLabel => 'Any time';

  @override
  String get discoveryAddedWithinWeekLabel => '7 days';

  @override
  String get discoveryAddedWithinMonthLabel => '30 days';

  @override
  String get discoveryAddedWithinQuarterLabel => '90 days';

  @override
  String get discoveryAddedWithinYearLabel => '365 days';

  @override
  String get discoveryResetFiltersLabel => 'Reset filters';

  @override
  String get discoveryOfficialRatingsFilterLabel => 'Content ratings';

  @override
  String get discoverySeriesStatusesFilterLabel => 'Series status';

  @override
  String get discoverySeriesContinuingLabel => 'Continuing';

  @override
  String get discoverySeriesEndedLabel => 'Ended';

  @override
  String get discoveryFineTuneFiltersLabel => 'Fine-tune your picks';

  @override
  String get discoveryLibraryDetailsLabel => 'Library details';

  @override
  String get discoveryApplyFiltersLabel => 'Show matches';

  @override
  String get discoveryMediaTypeLabel => 'Media type';

  @override
  String get discoveryMoviesLabel => 'Movies';

  @override
  String get discoverySeriesLabel => 'TV series';

  @override
  String discoveryRuntimeFilterLabel(int minimum, int maximum) {
    return 'Runtime: $minimum–$maximum minutes';
  }

  @override
  String discoveryCommunityFilterLabel(String value) {
    return 'Minimum community rating: $value';
  }

  @override
  String discoveryCriticFilterLabel(String value) {
    return 'Minimum critic rating: $value';
  }

  @override
  String get discoveryGenresFilterLabel => 'Genres (comma separated)';

  @override
  String get discoveryDecadeFilterLabel => 'Decade';

  @override
  String get discoveryWatchedFilterLabel => 'Watched state';

  @override
  String get discoveryFavoriteFilterLabel => 'Favorite state';

  @override
  String get discoveryAnyLabel => 'Any';

  @override
  String get discoveryYesLabel => 'Yes';

  @override
  String get discoveryNoLabel => 'No';

  @override
  String get discoveryPresetsLabel => 'Filter presets';

  @override
  String get discoveryPresetNameLabel => 'Preset name';

  @override
  String get discoverySavePresetLabel => 'Save current filters';

  @override
  String get discoveryClearConfirmation =>
      'Clear filters, presets, recent picks, likes, and dismissals on this device? Your Jellyfin login stays connected.';

  @override
  String get discoveryCancelLabel => 'Cancel';

  @override
  String get discoveryConfirmClearLabel => 'Clear';

  @override
  String get discoveryUnknownValue => 'Not available';

  @override
  String get discoverySynopsisLabel => 'Synopsis';

  @override
  String discoveryYearLabel(String value) {
    return 'Year: $value';
  }

  @override
  String discoveryRuntimeLabel(String value) {
    return 'Runtime: $value';
  }

  @override
  String discoveryRuntimeMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String discoveryGenresLabel(String value) {
    return 'Genres: $value';
  }

  @override
  String discoveryCommunityRatingLabel(String value) {
    return 'Community rating: $value';
  }

  @override
  String discoveryCriticRatingLabel(String value) {
    return 'Critic rating: $value';
  }

  @override
  String discoveryContentRatingLabel(String value) {
    return 'Content rating: $value';
  }

  @override
  String discoveryStatusLabel(String value) {
    return 'Status: $value';
  }

  @override
  String discoveryCastLabel(String value) {
    return 'Featured cast: $value';
  }
}
