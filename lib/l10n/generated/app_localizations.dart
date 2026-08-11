import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Jellyfin Picker'**
  String get appTitle;

  /// No description provided for @homeHeadline.
  ///
  /// In en, this message translates to:
  /// **'Pick something great'**
  String get homeHeadline;

  /// No description provided for @homeDescription.
  ///
  /// In en, this message translates to:
  /// **'A playful way to discover your Jellyfin library.'**
  String get homeDescription;

  /// No description provided for @connectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Connect your Jellyfin'**
  String get connectionTitle;

  /// No description provided for @connectionServerUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Server address'**
  String get connectionServerUrlLabel;

  /// No description provided for @connectionUsernameLabel.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get connectionUsernameLabel;

  /// No description provided for @connectionPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get connectionPasswordLabel;

  /// No description provided for @connectionSubmitLabel.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connectionSubmitLabel;

  /// No description provided for @connectionPrivateHttpWarning.
  ///
  /// In en, this message translates to:
  /// **'This local HTTP connection is unencrypted. Continue only if you trust this private network.'**
  String get connectionPrivateHttpWarning;

  /// No description provided for @connectionContinuePrivateHttpLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue on local network'**
  String get connectionContinuePrivateHttpLabel;

  /// No description provided for @connectionConnectingLabel.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get connectionConnectingLabel;

  /// No description provided for @connectionConnectedLabel.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connectionConnectedLabel;

  /// No description provided for @connectionNeedsReauthenticationLabel.
  ///
  /// In en, this message translates to:
  /// **'Your session expired. Please connect again.'**
  String get connectionNeedsReauthenticationLabel;

  /// No description provided for @connectionUnreachableError.
  ///
  /// In en, this message translates to:
  /// **'We could not reach that server. Check the address and network.'**
  String get connectionUnreachableError;

  /// No description provided for @connectionServerError.
  ///
  /// In en, this message translates to:
  /// **'The Jellyfin server is temporarily unavailable. Try again shortly.'**
  String get connectionServerError;

  /// No description provided for @connectionInvalidCertificateError.
  ///
  /// In en, this message translates to:
  /// **'The server certificate is not trusted. Use a valid HTTPS certificate.'**
  String get connectionInvalidCertificateError;

  /// No description provided for @connectionIncompatibleError.
  ///
  /// In en, this message translates to:
  /// **'That server is not a compatible Jellyfin server.'**
  String get connectionIncompatibleError;

  /// No description provided for @connectionUnsafeRedirectError.
  ///
  /// In en, this message translates to:
  /// **'The server redirected the request unsafely. Check the address and try again.'**
  String get connectionUnsafeRedirectError;

  /// No description provided for @connectionInvalidCredentialsError.
  ///
  /// In en, this message translates to:
  /// **'Those credentials were not accepted.'**
  String get connectionInvalidCredentialsError;

  /// No description provided for @connectionExpiredSessionError.
  ///
  /// In en, this message translates to:
  /// **'Your session expired. Please connect again.'**
  String get connectionExpiredSessionError;

  /// No description provided for @connectionInvalidUrlError.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid Jellyfin server address.'**
  String get connectionInvalidUrlError;

  /// No description provided for @connectionPublicHttpError.
  ///
  /// In en, this message translates to:
  /// **'Public HTTP connections are not allowed. Use HTTPS.'**
  String get connectionPublicHttpError;

  /// No description provided for @connectionStorageError.
  ///
  /// In en, this message translates to:
  /// **'Secure session storage is unavailable on this device.'**
  String get connectionStorageError;

  /// No description provided for @connectionUnknownError.
  ///
  /// In en, this message translates to:
  /// **'We could not complete the connection. Try again.'**
  String get connectionUnknownError;

  /// No description provided for @connectionSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Connected to Jellyfin'**
  String get connectionSummaryTitle;

  /// No description provided for @connectionSummaryServerLabel.
  ///
  /// In en, this message translates to:
  /// **'Server'**
  String get connectionSummaryServerLabel;

  /// No description provided for @connectionSummaryUserLabel.
  ///
  /// In en, this message translates to:
  /// **'Signed in as'**
  String get connectionSummaryUserLabel;

  /// No description provided for @connectionLogoutLabel.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get connectionLogoutLabel;

  /// No description provided for @connectionExploreLabel.
  ///
  /// In en, this message translates to:
  /// **'Explore library'**
  String get connectionExploreLabel;

  /// No description provided for @discoveryTitle.
  ///
  /// In en, this message translates to:
  /// **'Pick something great'**
  String get discoveryTitle;

  /// No description provided for @discoveryGridLabel.
  ///
  /// In en, this message translates to:
  /// **'Grid'**
  String get discoveryGridLabel;

  /// No description provided for @discoverySwipeLabel.
  ///
  /// In en, this message translates to:
  /// **'Swipe'**
  String get discoverySwipeLabel;

  /// No description provided for @discoveryShuffleLabel.
  ///
  /// In en, this message translates to:
  /// **'Shuffle'**
  String get discoveryShuffleLabel;

  /// No description provided for @discoveryLikeLabel.
  ///
  /// In en, this message translates to:
  /// **'Like'**
  String get discoveryLikeLabel;

  /// No description provided for @discoveryRejectLabel.
  ///
  /// In en, this message translates to:
  /// **'Not this one'**
  String get discoveryRejectLabel;

  /// No description provided for @discoveryRevealLabel.
  ///
  /// In en, this message translates to:
  /// **'Reveal a pick'**
  String get discoveryRevealLabel;

  /// No description provided for @discoveryFavoriteAddLabel.
  ///
  /// In en, this message translates to:
  /// **'Add to Jellyfin favorites'**
  String get discoveryFavoriteAddLabel;

  /// No description provided for @discoveryFavoriteRemoveLabel.
  ///
  /// In en, this message translates to:
  /// **'Remove from Jellyfin favorites'**
  String get discoveryFavoriteRemoveLabel;

  /// No description provided for @discoveryFavoriteError.
  ///
  /// In en, this message translates to:
  /// **'Jellyfin could not update that favorite. Try again.'**
  String get discoveryFavoriteError;

  /// No description provided for @catalogLoadingLabel.
  ///
  /// In en, this message translates to:
  /// **'Loading your Jellyfin library…'**
  String get catalogLoadingLabel;

  /// No description provided for @catalogErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Your library is unavailable'**
  String get catalogErrorTitle;

  /// No description provided for @catalogErrorDescription.
  ///
  /// In en, this message translates to:
  /// **'Check the Jellyfin connection, then reconnect to refresh current results.'**
  String get catalogErrorDescription;

  /// No description provided for @catalogReconnectLabel.
  ///
  /// In en, this message translates to:
  /// **'Reconnect'**
  String get catalogReconnectLabel;

  /// No description provided for @discoveryDetailsLabel.
  ///
  /// In en, this message translates to:
  /// **'Open details for {title}'**
  String discoveryDetailsLabel(String title);

  /// No description provided for @discoveryNoCandidatesTitle.
  ///
  /// In en, this message translates to:
  /// **'No titles fit yet'**
  String get discoveryNoCandidatesTitle;

  /// No description provided for @discoveryNoCandidatesDescription.
  ///
  /// In en, this message translates to:
  /// **'Adjust your filters or clear dismissed titles to keep exploring.'**
  String get discoveryNoCandidatesDescription;

  /// No description provided for @discoveryClearLabel.
  ///
  /// In en, this message translates to:
  /// **'Clear discovery data'**
  String get discoveryClearLabel;

  /// No description provided for @discoveryFiltersLabel.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get discoveryFiltersLabel;

  /// No description provided for @discoveryApplyFiltersLabel.
  ///
  /// In en, this message translates to:
  /// **'Show matches'**
  String get discoveryApplyFiltersLabel;

  /// No description provided for @discoveryMediaTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Media type'**
  String get discoveryMediaTypeLabel;

  /// No description provided for @discoveryMoviesLabel.
  ///
  /// In en, this message translates to:
  /// **'Movies'**
  String get discoveryMoviesLabel;

  /// No description provided for @discoverySeriesLabel.
  ///
  /// In en, this message translates to:
  /// **'TV series'**
  String get discoverySeriesLabel;

  /// No description provided for @discoveryRuntimeFilterLabel.
  ///
  /// In en, this message translates to:
  /// **'Runtime: {minimum}–{maximum} minutes'**
  String discoveryRuntimeFilterLabel(int minimum, int maximum);

  /// No description provided for @discoveryCommunityFilterLabel.
  ///
  /// In en, this message translates to:
  /// **'Minimum community rating: {value}'**
  String discoveryCommunityFilterLabel(String value);

  /// No description provided for @discoveryCriticFilterLabel.
  ///
  /// In en, this message translates to:
  /// **'Minimum critic rating: {value}'**
  String discoveryCriticFilterLabel(String value);

  /// No description provided for @discoveryGenresFilterLabel.
  ///
  /// In en, this message translates to:
  /// **'Genres (comma separated)'**
  String get discoveryGenresFilterLabel;

  /// No description provided for @discoveryDecadeFilterLabel.
  ///
  /// In en, this message translates to:
  /// **'Decade'**
  String get discoveryDecadeFilterLabel;

  /// No description provided for @discoveryWatchedFilterLabel.
  ///
  /// In en, this message translates to:
  /// **'Watched state'**
  String get discoveryWatchedFilterLabel;

  /// No description provided for @discoveryFavoriteFilterLabel.
  ///
  /// In en, this message translates to:
  /// **'Favorite state'**
  String get discoveryFavoriteFilterLabel;

  /// No description provided for @discoveryAnyLabel.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get discoveryAnyLabel;

  /// No description provided for @discoveryYesLabel.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get discoveryYesLabel;

  /// No description provided for @discoveryNoLabel.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get discoveryNoLabel;

  /// No description provided for @discoveryPresetsLabel.
  ///
  /// In en, this message translates to:
  /// **'Filter presets'**
  String get discoveryPresetsLabel;

  /// No description provided for @discoveryPresetNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Preset name'**
  String get discoveryPresetNameLabel;

  /// No description provided for @discoverySavePresetLabel.
  ///
  /// In en, this message translates to:
  /// **'Save current filters'**
  String get discoverySavePresetLabel;

  /// No description provided for @discoveryClearConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Clear filters, presets, recent picks, likes, and dismissals on this device? Your Jellyfin login stays connected.'**
  String get discoveryClearConfirmation;

  /// No description provided for @discoveryCancelLabel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get discoveryCancelLabel;

  /// No description provided for @discoveryConfirmClearLabel.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get discoveryConfirmClearLabel;

  /// No description provided for @discoveryUnknownValue.
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get discoveryUnknownValue;

  /// No description provided for @discoverySynopsisLabel.
  ///
  /// In en, this message translates to:
  /// **'Synopsis'**
  String get discoverySynopsisLabel;

  /// No description provided for @discoveryYearLabel.
  ///
  /// In en, this message translates to:
  /// **'Year: {value}'**
  String discoveryYearLabel(String value);

  /// No description provided for @discoveryRuntimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Runtime: {value}'**
  String discoveryRuntimeLabel(String value);

  /// No description provided for @discoveryRuntimeMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String discoveryRuntimeMinutes(int minutes);

  /// No description provided for @discoveryGenresLabel.
  ///
  /// In en, this message translates to:
  /// **'Genres: {value}'**
  String discoveryGenresLabel(String value);

  /// No description provided for @discoveryCommunityRatingLabel.
  ///
  /// In en, this message translates to:
  /// **'Community rating: {value}'**
  String discoveryCommunityRatingLabel(String value);

  /// No description provided for @discoveryCriticRatingLabel.
  ///
  /// In en, this message translates to:
  /// **'Critic rating: {value}'**
  String discoveryCriticRatingLabel(String value);

  /// No description provided for @discoveryContentRatingLabel.
  ///
  /// In en, this message translates to:
  /// **'Content rating: {value}'**
  String discoveryContentRatingLabel(String value);

  /// No description provided for @discoveryStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status: {value}'**
  String discoveryStatusLabel(String value);

  /// No description provided for @discoveryCastLabel.
  ///
  /// In en, this message translates to:
  /// **'Featured cast: {value}'**
  String discoveryCastLabel(String value);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
