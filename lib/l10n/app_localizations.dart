import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_am.dart';
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
/// import 'l10n/app_localizations.dart';
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
  static const List<Locale> supportedLocales = <Locale>[
    Locale('am'),
    Locale('en'),
  ];

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get profileTitle;

  /// No description provided for @accountSettings.
  ///
  /// In en, this message translates to:
  /// **'ACCOUNT SETTINGS'**
  String get accountSettings;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @changePasswordDesc.
  ///
  /// In en, this message translates to:
  /// **'Update your login password'**
  String get changePasswordDesc;

  /// No description provided for @appLanguage.
  ///
  /// In en, this message translates to:
  /// **'App Language'**
  String get appLanguage;

  /// No description provided for @aboutSystem.
  ///
  /// In en, this message translates to:
  /// **'About System'**
  String get aboutSystem;

  /// No description provided for @aboutSystemDesc.
  ///
  /// In en, this message translates to:
  /// **'Version 2.4.1 (Production)'**
  String get aboutSystemDesc;

  /// No description provided for @activityToday.
  ///
  /// In en, this message translates to:
  /// **'YOUR ACTIVITY TODAY'**
  String get activityToday;

  /// No description provided for @statIssued.
  ///
  /// In en, this message translates to:
  /// **'Issued'**
  String get statIssued;

  /// No description provided for @statReturned.
  ///
  /// In en, this message translates to:
  /// **'Returned'**
  String get statReturned;

  /// No description provided for @statBoxMoves.
  ///
  /// In en, this message translates to:
  /// **'Box Moves'**
  String get statBoxMoves;

  /// No description provided for @metaRole.
  ///
  /// In en, this message translates to:
  /// **'ROLE'**
  String get metaRole;

  /// No description provided for @metaStatus.
  ///
  /// In en, this message translates to:
  /// **'STATUS'**
  String get metaStatus;

  /// No description provided for @metaMemberSince.
  ///
  /// In en, this message translates to:
  /// **'MEMBER SINCE'**
  String get metaMemberSince;

  /// No description provided for @statusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get statusActive;

  /// No description provided for @statusInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get statusInactive;

  /// No description provided for @orgFooter.
  ///
  /// In en, this message translates to:
  /// **'Designed and developed by Melfan Tech'**
  String get orgFooter;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @signOutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out of the Passport Custody & Tracking system?'**
  String get signOutConfirm;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @aboutInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'App Information'**
  String get aboutInfoTitle;

  /// No description provided for @aboutInfoBody.
  ///
  /// In en, this message translates to:
  /// **'Passport Custody & Tracking Mobile Client\nBuild: 2026.07.13.1\nDesigned and developed by Melfan Tech'**
  String get aboutInfoBody;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get currentPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPassword;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get confirmNewPassword;

  /// No description provided for @updatePassword.
  ///
  /// In en, this message translates to:
  /// **'Update Password'**
  String get updatePassword;

  /// No description provided for @passwordUpdated.
  ///
  /// In en, this message translates to:
  /// **'Password updated successfully'**
  String get passwordUpdated;

  /// No description provided for @passwordRule.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters with upper, lower, number & special character.'**
  String get passwordRule;

  /// No description provided for @passwordsNoMatch.
  ///
  /// In en, this message translates to:
  /// **'New passwords do not match'**
  String get passwordsNoMatch;

  /// No description provided for @fillAllFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all fields'**
  String get fillAllFields;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageAmharic.
  ///
  /// In en, this message translates to:
  /// **'Amharic'**
  String get languageAmharic;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get languageSystem;

  /// No description provided for @loginWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get loginWelcome;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue'**
  String get loginSubtitle;

  /// No description provided for @loginUsername.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get loginUsername;

  /// No description provided for @loginUsernameRequired.
  ///
  /// In en, this message translates to:
  /// **'Username is required'**
  String get loginUsernameRequired;

  /// No description provided for @loginPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get loginPassword;

  /// No description provided for @loginPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get loginPasswordRequired;

  /// No description provided for @loginPasswordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get loginPasswordMinLength;

  /// No description provided for @loginRememberMe.
  ///
  /// In en, this message translates to:
  /// **'Remember me'**
  String get loginRememberMe;

  /// No description provided for @loginForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get loginForgotPassword;

  /// No description provided for @loginForgotPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Contact your administrator to reset password'**
  String get loginForgotPasswordHint;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginButton;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed'**
  String get loginFailed;

  /// No description provided for @dashOrganisedStorage.
  ///
  /// In en, this message translates to:
  /// **'ORGANISED STORAGE'**
  String get dashOrganisedStorage;

  /// No description provided for @dashPassportsInCustody.
  ///
  /// In en, this message translates to:
  /// **'passports in custody'**
  String get dashPassportsInCustody;

  /// No description provided for @dashInUse.
  ///
  /// In en, this message translates to:
  /// **'in use'**
  String get dashInUse;

  /// No description provided for @dashInVault.
  ///
  /// In en, this message translates to:
  /// **'In vault'**
  String get dashInVault;

  /// No description provided for @dashIssued.
  ///
  /// In en, this message translates to:
  /// **'Issued'**
  String get dashIssued;

  /// No description provided for @dashBoxes.
  ///
  /// In en, this message translates to:
  /// **'Boxes'**
  String get dashBoxes;

  /// No description provided for @dashOverviewUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Overview unavailable'**
  String get dashOverviewUnavailable;

  /// No description provided for @dashOverviewFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load overview'**
  String get dashOverviewFailed;

  /// No description provided for @qaIssue.
  ///
  /// In en, this message translates to:
  /// **'Issue'**
  String get qaIssue;

  /// No description provided for @qaIssueSub.
  ///
  /// In en, this message translates to:
  /// **'New passport'**
  String get qaIssueSub;

  /// No description provided for @qaReturn.
  ///
  /// In en, this message translates to:
  /// **'Return'**
  String get qaReturn;

  /// No description provided for @qaReturnSub.
  ///
  /// In en, this message translates to:
  /// **'Return passport'**
  String get qaReturnSub;

  /// No description provided for @qaAssign.
  ///
  /// In en, this message translates to:
  /// **'Assign'**
  String get qaAssign;

  /// No description provided for @qaAssignSub.
  ///
  /// In en, this message translates to:
  /// **'Assign to user'**
  String get qaAssignSub;

  /// No description provided for @qaVerify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get qaVerify;

  /// No description provided for @qaVerifySub.
  ///
  /// In en, this message translates to:
  /// **'Verify passport'**
  String get qaVerifySub;

  /// No description provided for @dashActivity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get dashActivity;

  /// No description provided for @dashLast7Days.
  ///
  /// In en, this message translates to:
  /// **'last 7 days'**
  String get dashLast7Days;

  /// No description provided for @dashMovements.
  ///
  /// In en, this message translates to:
  /// **'movements'**
  String get dashMovements;

  /// No description provided for @dashCouldNotLoadActivity.
  ///
  /// In en, this message translates to:
  /// **'Could not load activity'**
  String get dashCouldNotLoadActivity;

  /// No description provided for @dashPassportStatus.
  ///
  /// In en, this message translates to:
  /// **'Passport status'**
  String get dashPassportStatus;

  /// No description provided for @dashTotal.
  ///
  /// In en, this message translates to:
  /// **'total'**
  String get dashTotal;

  /// No description provided for @dashStorageByRoom.
  ///
  /// In en, this message translates to:
  /// **'Storage by room'**
  String get dashStorageByRoom;

  /// No description provided for @dashRoom.
  ///
  /// In en, this message translates to:
  /// **'room'**
  String get dashRoom;

  /// No description provided for @dashRooms.
  ///
  /// In en, this message translates to:
  /// **'rooms'**
  String get dashRooms;

  /// No description provided for @dashCouldNotLoadRooms.
  ///
  /// In en, this message translates to:
  /// **'Could not load rooms'**
  String get dashCouldNotLoadRooms;

  /// No description provided for @dashRecentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent activity'**
  String get dashRecentActivity;

  /// No description provided for @dashNoRecentActivity.
  ///
  /// In en, this message translates to:
  /// **'No recent activity'**
  String get dashNoRecentActivity;

  /// No description provided for @actBatchAssignment.
  ///
  /// In en, this message translates to:
  /// **'Batch Assignment'**
  String get actBatchAssignment;

  /// No description provided for @actCustodyReturned.
  ///
  /// In en, this message translates to:
  /// **'Custody Returned'**
  String get actCustodyReturned;

  /// No description provided for @actPassportIssued.
  ///
  /// In en, this message translates to:
  /// **'Passport Issued'**
  String get actPassportIssued;

  /// No description provided for @actBoxRelocated.
  ///
  /// In en, this message translates to:
  /// **'Box Relocated'**
  String get actBoxRelocated;

  /// No description provided for @dashBoxPrefix.
  ///
  /// In en, this message translates to:
  /// **'Box'**
  String get dashBoxPrefix;

  /// No description provided for @dashNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get dashNotifications;

  /// No description provided for @notifCapacityTitle.
  ///
  /// In en, this message translates to:
  /// **'Box Capacity Alert'**
  String get notifCapacityTitle;

  /// No description provided for @notifCapacityBody.
  ///
  /// In en, this message translates to:
  /// **'Box MB-002 is at 100% capacity. Assign a new target.'**
  String get notifCapacityBody;

  /// No description provided for @notifBatchTitle.
  ///
  /// In en, this message translates to:
  /// **'New Batch Pending'**
  String get notifBatchTitle;

  /// No description provided for @notifBatchBody.
  ///
  /// In en, this message translates to:
  /// **'12 ePassports scanned at Reception A awaiting assignment.'**
  String get notifBatchBody;

  /// No description provided for @greetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get greetingMorning;

  /// No description provided for @greetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get greetingEvening;

  /// No description provided for @officer.
  ///
  /// In en, this message translates to:
  /// **'Officer'**
  String get officer;

  /// No description provided for @chartNoActivity.
  ///
  /// In en, this message translates to:
  /// **'No activity in this period'**
  String get chartNoActivity;

  /// No description provided for @chartNoRooms.
  ///
  /// In en, this message translates to:
  /// **'No rooms configured yet'**
  String get chartNoRooms;

  /// No description provided for @roomUnnamed.
  ///
  /// In en, this message translates to:
  /// **'Unnamed room'**
  String get roomUnnamed;

  /// No description provided for @roomBoxSingular.
  ///
  /// In en, this message translates to:
  /// **'box'**
  String get roomBoxSingular;

  /// No description provided for @roomBoxPlural.
  ///
  /// In en, this message translates to:
  /// **'boxes'**
  String get roomBoxPlural;

  /// No description provided for @roomSlotsFree.
  ///
  /// In en, this message translates to:
  /// **'slots free'**
  String get roomSlotsFree;

  /// No description provided for @boxesTitle.
  ///
  /// In en, this message translates to:
  /// **'Box Inventory'**
  String get boxesTitle;

  /// No description provided for @boxesListView.
  ///
  /// In en, this message translates to:
  /// **'List view'**
  String get boxesListView;

  /// No description provided for @boxesGridView.
  ///
  /// In en, this message translates to:
  /// **'Grid view'**
  String get boxesGridView;

  /// No description provided for @boxesScanToSearch.
  ///
  /// In en, this message translates to:
  /// **'Scan a box QR to search'**
  String get boxesScanToSearch;

  /// No description provided for @boxesSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Enter Box QR Code (e.g. BOX-0001)...'**
  String get boxesSearchHint;

  /// No description provided for @boxesFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All Boxes'**
  String get boxesFilterAll;

  /// No description provided for @boxesFilterActive.
  ///
  /// In en, this message translates to:
  /// **'Active (Space available)'**
  String get boxesFilterActive;

  /// No description provided for @boxStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get boxStatusActive;

  /// No description provided for @boxStatusFull.
  ///
  /// In en, this message translates to:
  /// **'Full'**
  String get boxStatusFull;

  /// No description provided for @boxStatusInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get boxStatusInactive;

  /// No description provided for @boxesLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load boxes. Check your connection.'**
  String get boxesLoadFailed;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @boxesNoneFound.
  ///
  /// In en, this message translates to:
  /// **'No Boxes Found'**
  String get boxesNoneFound;

  /// No description provided for @boxesNoneHint.
  ///
  /// In en, this message translates to:
  /// **'Try a different filter or search term'**
  String get boxesNoneHint;

  /// No description provided for @boxesUnallocatedSlot.
  ///
  /// In en, this message translates to:
  /// **'Unallocated slot'**
  String get boxesUnallocatedSlot;

  /// No description provided for @boxesUnallocated.
  ///
  /// In en, this message translates to:
  /// **'Unallocated'**
  String get boxesUnallocated;

  /// No description provided for @boxesViewPassports.
  ///
  /// In en, this message translates to:
  /// **'View Passports'**
  String get boxesViewPassports;

  /// No description provided for @boxesSlots.
  ///
  /// In en, this message translates to:
  /// **'slots'**
  String get boxesSlots;

  /// No description provided for @boxesLocationLabel.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get boxesLocationLabel;

  /// No description provided for @boxesDefaultLocation.
  ///
  /// In en, this message translates to:
  /// **'HQ Storage'**
  String get boxesDefaultLocation;

  /// No description provided for @boxesPassportsInside.
  ///
  /// In en, this message translates to:
  /// **'PASSPORTS INSIDE'**
  String get boxesPassportsInside;

  /// No description provided for @boxesNoPassports.
  ///
  /// In en, this message translates to:
  /// **'No passports are currently assigned to this box.'**
  String get boxesNoPassports;

  /// No description provided for @boxesIdNo.
  ///
  /// In en, this message translates to:
  /// **'ID No'**
  String get boxesIdNo;

  /// No description provided for @scanModeAssign.
  ///
  /// In en, this message translates to:
  /// **'Assign Box'**
  String get scanModeAssign;

  /// No description provided for @scanModeReturn.
  ///
  /// In en, this message translates to:
  /// **'Return Custody'**
  String get scanModeReturn;

  /// No description provided for @scanModeIssue.
  ///
  /// In en, this message translates to:
  /// **'Issue Owner'**
  String get scanModeIssue;

  /// No description provided for @scanModeMove.
  ///
  /// In en, this message translates to:
  /// **'Move Box'**
  String get scanModeMove;

  /// No description provided for @scanModeVerify.
  ///
  /// In en, this message translates to:
  /// **'Quick Verify'**
  String get scanModeVerify;

  /// No description provided for @scanReadyToScan.
  ///
  /// In en, this message translates to:
  /// **'Ready to Scan'**
  String get scanReadyToScan;

  /// No description provided for @scanTargetBoxPrompt.
  ///
  /// In en, this message translates to:
  /// **'Scan TARGET BOX QR Code'**
  String get scanTargetBoxPrompt;

  /// No description provided for @scanBoxLockedPassports.
  ///
  /// In en, this message translates to:
  /// **'Box Locked. Scan Passport QR Codes.'**
  String get scanBoxLockedPassports;

  /// No description provided for @scanReturnBoxPrompt.
  ///
  /// In en, this message translates to:
  /// **'Scan RETURN BOX QR Code'**
  String get scanReturnBoxPrompt;

  /// No description provided for @scanBoxLockedReturned.
  ///
  /// In en, this message translates to:
  /// **'Box Locked. Scan Returned Passports.'**
  String get scanBoxLockedReturned;

  /// No description provided for @scanBoxToMovePrompt.
  ///
  /// In en, this message translates to:
  /// **'Scan BOX QR Code to Move'**
  String get scanBoxToMovePrompt;

  /// No description provided for @scanDestSlotPrompt.
  ///
  /// In en, this message translates to:
  /// **'Scan DESTINATION SLOT QR Code'**
  String get scanDestSlotPrompt;

  /// No description provided for @scanSlotLockedConfirm.
  ///
  /// In en, this message translates to:
  /// **'Slot Locked. Confirm movement.'**
  String get scanSlotLockedConfirm;

  /// No description provided for @scanPassportToIssuePrompt.
  ///
  /// In en, this message translates to:
  /// **'Scan Passport QR Code to Issue'**
  String get scanPassportToIssuePrompt;

  /// No description provided for @scanAnyToVerifyPrompt.
  ///
  /// In en, this message translates to:
  /// **'Scan Any QR Code to Quick Verify'**
  String get scanAnyToVerifyPrompt;

  /// No description provided for @scanEnterCodeManually.
  ///
  /// In en, this message translates to:
  /// **'Enter code manually...'**
  String get scanEnterCodeManually;

  /// No description provided for @scanAssignHint.
  ///
  /// In en, this message translates to:
  /// **'Scan a Box QR code or input its label manually to begin storage.'**
  String get scanAssignHint;

  /// No description provided for @scanUnassignedSlot.
  ///
  /// In en, this message translates to:
  /// **'Unassigned Slot'**
  String get scanUnassignedSlot;

  /// No description provided for @scanClearList.
  ///
  /// In en, this message translates to:
  /// **'Clear list'**
  String get scanClearList;

  /// No description provided for @scanAppendHint.
  ///
  /// In en, this message translates to:
  /// **'Scan passport QR codes to append...'**
  String get scanAppendHint;

  /// No description provided for @scanConfirmReturn.
  ///
  /// In en, this message translates to:
  /// **'Confirm Return Custody'**
  String get scanConfirmReturn;

  /// No description provided for @scanConfirmAssign.
  ///
  /// In en, this message translates to:
  /// **'Confirm Box Assignment'**
  String get scanConfirmAssign;

  /// No description provided for @scanMoveHint.
  ///
  /// In en, this message translates to:
  /// **'Scan a Box QR code to initiate movement.'**
  String get scanMoveHint;

  /// No description provided for @scanBoxToMove.
  ///
  /// In en, this message translates to:
  /// **'BOX TO MOVE'**
  String get scanBoxToMove;

  /// No description provided for @scanDestSlot.
  ///
  /// In en, this message translates to:
  /// **'DESTINATION SLOT'**
  String get scanDestSlot;

  /// No description provided for @scanScanDestNext.
  ///
  /// In en, this message translates to:
  /// **'Scan destination Slot QR code next...'**
  String get scanScanDestNext;

  /// No description provided for @scanUnknownSlot.
  ///
  /// In en, this message translates to:
  /// **'Unknown Slot'**
  String get scanUnknownSlot;

  /// No description provided for @scanConfirmMove.
  ///
  /// In en, this message translates to:
  /// **'Confirm Box Move'**
  String get scanConfirmMove;

  /// No description provided for @scanIssueHint.
  ///
  /// In en, this message translates to:
  /// **'Scan passport QR code to initiate owner hand-over.'**
  String get scanIssueHint;

  /// No description provided for @scanPassportReadyIssuance.
  ///
  /// In en, this message translates to:
  /// **'PASSPORT READY FOR ISSUANCE'**
  String get scanPassportReadyIssuance;

  /// No description provided for @scanCurrentCustody.
  ///
  /// In en, this message translates to:
  /// **'Current Custody: '**
  String get scanCurrentCustody;

  /// No description provided for @scanConfirmIssuance.
  ///
  /// In en, this message translates to:
  /// **'Confirm Issuance'**
  String get scanConfirmIssuance;

  /// No description provided for @scanRecentHistory.
  ///
  /// In en, this message translates to:
  /// **'Recent Scans History'**
  String get scanRecentHistory;

  /// No description provided for @scanNoScans.
  ///
  /// In en, this message translates to:
  /// **'No scans recorded in this session'**
  String get scanNoScans;

  /// No description provided for @scanPassportAlreadyInBatch.
  ///
  /// In en, this message translates to:
  /// **'Passport already in current batch'**
  String get scanPassportAlreadyInBatch;

  /// No description provided for @scanBatchFailed.
  ///
  /// In en, this message translates to:
  /// **'Batch operation failed'**
  String get scanBatchFailed;

  /// No description provided for @scanIssueFailed.
  ///
  /// In en, this message translates to:
  /// **'Issuance failed'**
  String get scanIssueFailed;

  /// No description provided for @scanBoxMoveFailed.
  ///
  /// In en, this message translates to:
  /// **'Box move failed'**
  String get scanBoxMoveFailed;

  /// No description provided for @scanGalleryUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Gallery import not supported on this device simulator'**
  String get scanGalleryUnsupported;

  /// No description provided for @scanHistBoxScanned.
  ///
  /// In en, this message translates to:
  /// **'Box Scanned'**
  String get scanHistBoxScanned;

  /// No description provided for @scanHistPassportScanned.
  ///
  /// In en, this message translates to:
  /// **'Passport Scanned'**
  String get scanHistPassportScanned;

  /// No description provided for @scanHistIssuePassport.
  ///
  /// In en, this message translates to:
  /// **'Issue Passport'**
  String get scanHistIssuePassport;

  /// No description provided for @scanHistSlotScanned.
  ///
  /// In en, this message translates to:
  /// **'Slot Scanned'**
  String get scanHistSlotScanned;

  /// No description provided for @scanHistVerificationSuccess.
  ///
  /// In en, this message translates to:
  /// **'Verification Success'**
  String get scanHistVerificationSuccess;

  /// No description provided for @scanHistBoxVerified.
  ///
  /// In en, this message translates to:
  /// **'Box Verified'**
  String get scanHistBoxVerified;

  /// No description provided for @scanJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get scanJustNow;

  /// No description provided for @scanPassportVerified.
  ///
  /// In en, this message translates to:
  /// **'Passport Verified'**
  String get scanPassportVerified;

  /// No description provided for @scanStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status: '**
  String get scanStatusLabel;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @scanNotAssigned.
  ///
  /// In en, this message translates to:
  /// **'Not assigned'**
  String get scanNotAssigned;

  /// No description provided for @scanPassportsStoredInside.
  ///
  /// In en, this message translates to:
  /// **'Passports stored inside:'**
  String get scanPassportsStoredInside;

  /// No description provided for @scanBoxEmpty.
  ///
  /// In en, this message translates to:
  /// **'Box is empty'**
  String get scanBoxEmpty;

  /// No description provided for @psIssued.
  ///
  /// In en, this message translates to:
  /// **'ISSUED'**
  String get psIssued;

  /// No description provided for @psInBox.
  ///
  /// In en, this message translates to:
  /// **'IN BOX'**
  String get psInBox;

  /// No description provided for @psReturned.
  ///
  /// In en, this message translates to:
  /// **'RETURNED'**
  String get psReturned;

  /// No description provided for @scanBoxNotFound.
  ///
  /// In en, this message translates to:
  /// **'Box not found: {code}'**
  String scanBoxNotFound(Object code);

  /// No description provided for @scanBoxRegistered.
  ///
  /// In en, this message translates to:
  /// **'Box {label} registered.'**
  String scanBoxRegistered(Object label);

  /// No description provided for @scanPassportNotFound.
  ///
  /// In en, this message translates to:
  /// **'Passport not found: {code}'**
  String scanPassportNotFound(Object code);

  /// No description provided for @scanOnlyIssuedCanAssign.
  ///
  /// In en, this message translates to:
  /// **'{name} is {status} — only ISSUED passports can be assigned'**
  String scanOnlyIssuedCanAssign(Object name, Object status);

  /// No description provided for @scanPassportAdded.
  ///
  /// In en, this message translates to:
  /// **'Passport: {name} added.'**
  String scanPassportAdded(Object name);

  /// No description provided for @scanOnlyInBoxCanIssue.
  ///
  /// In en, this message translates to:
  /// **'{name} is {status} — only IN_BOX passports can be issued'**
  String scanOnlyInBoxCanIssue(Object name, Object status);

  /// No description provided for @scanPassportIdentified.
  ///
  /// In en, this message translates to:
  /// **'Passport identified: {name}'**
  String scanPassportIdentified(Object name);

  /// No description provided for @scanBoxScanned.
  ///
  /// In en, this message translates to:
  /// **'Box {label} scanned.'**
  String scanBoxScanned(Object label);

  /// No description provided for @scanSlotNotFound.
  ///
  /// In en, this message translates to:
  /// **'Slot not found: {code}'**
  String scanSlotNotFound(Object code);

  /// No description provided for @scanSlotScanned.
  ///
  /// In en, this message translates to:
  /// **'Slot {name} scanned.'**
  String scanSlotScanned(Object name);

  /// No description provided for @scanQrNotRegistered.
  ///
  /// In en, this message translates to:
  /// **'QR code not registered in system: {code}'**
  String scanQrNotRegistered(Object code);

  /// No description provided for @scanLookupFailed.
  ///
  /// In en, this message translates to:
  /// **'Lookup failed: {error}'**
  String scanLookupFailed(Object error);

  /// No description provided for @scanBatchStored.
  ///
  /// In en, this message translates to:
  /// **'Successfully stored {count} passports in {label}'**
  String scanBatchStored(Object count, Object label);

  /// No description provided for @scanBatchError.
  ///
  /// In en, this message translates to:
  /// **'Error submitting batch: {error}'**
  String scanBatchError(Object error);

  /// No description provided for @scanIssueSuccess.
  ///
  /// In en, this message translates to:
  /// **'Passport successfully issued to {name}'**
  String scanIssueSuccess(Object name);

  /// No description provided for @scanGenericError.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String scanGenericError(Object error);

  /// No description provided for @scanBoxMoveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Box successfully moved to slot {name}'**
  String scanBoxMoveSuccess(Object name);

  /// No description provided for @scanBoxMoveError.
  ///
  /// In en, this message translates to:
  /// **'Error moving box: {error}'**
  String scanBoxMoveError(Object error);

  /// No description provided for @scanHolder.
  ///
  /// In en, this message translates to:
  /// **'Holder: {name}'**
  String scanHolder(Object name);

  /// No description provided for @scanIdNumber.
  ///
  /// In en, this message translates to:
  /// **'ID Number: {id}'**
  String scanIdNumber(Object id);

  /// No description provided for @scanQrCodeValue.
  ///
  /// In en, this message translates to:
  /// **'QR Code: {qr}'**
  String scanQrCodeValue(Object qr);

  /// No description provided for @scanLocationBox.
  ///
  /// In en, this message translates to:
  /// **'Location: Box {label}'**
  String scanLocationBox(Object label);

  /// No description provided for @scanShelf.
  ///
  /// In en, this message translates to:
  /// **'Shelf: {location}'**
  String scanShelf(Object location);

  /// No description provided for @scanCapacity.
  ///
  /// In en, this message translates to:
  /// **'Capacity: {occupied} / {capacity} occupied'**
  String scanCapacity(Object occupied, Object capacity);

  /// No description provided for @scanLocationValue.
  ///
  /// In en, this message translates to:
  /// **'Location: {location}'**
  String scanLocationValue(Object location);

  /// No description provided for @scanPassportBullet.
  ///
  /// In en, this message translates to:
  /// **'• {name} ({qr})'**
  String scanPassportBullet(Object name, Object qr);

  /// No description provided for @scanTargetBox.
  ///
  /// In en, this message translates to:
  /// **'Target Box: {label}'**
  String scanTargetBox(Object label);

  /// No description provided for @scanScannedPassportsCount.
  ///
  /// In en, this message translates to:
  /// **'Scanned Passports ({count})'**
  String scanScannedPassportsCount(Object count);

  /// No description provided for @scanCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Current Location: {location}'**
  String scanCurrentLocation(Object location);

  /// No description provided for @issuePageTitle.
  ///
  /// In en, this message translates to:
  /// **'Passport Issuance'**
  String get issuePageTitle;

  /// No description provided for @issueSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Name, ID number, or QR code…'**
  String get issueSearchHint;

  /// No description provided for @issueFilterInBox.
  ///
  /// In en, this message translates to:
  /// **'In Box'**
  String get issueFilterInBox;

  /// No description provided for @issueFilterIssued.
  ///
  /// In en, this message translates to:
  /// **'Issued'**
  String get issueFilterIssued;

  /// No description provided for @issueFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get issueFilterAll;

  /// No description provided for @issueConfirmIdentity.
  ///
  /// In en, this message translates to:
  /// **'Confirm Identity & Issue'**
  String get issueConfirmIdentity;

  /// No description provided for @issueLoadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get issueLoadMore;

  /// No description provided for @issueEndOfList.
  ///
  /// In en, this message translates to:
  /// **'— End of list —'**
  String get issueEndOfList;

  /// No description provided for @issueEmptySearch.
  ///
  /// In en, this message translates to:
  /// **'No passports match your search.'**
  String get issueEmptySearch;

  /// No description provided for @issueEmptyInBox.
  ///
  /// In en, this message translates to:
  /// **'All passports have been issued.'**
  String get issueEmptyInBox;

  /// No description provided for @issueEmptyIssued.
  ///
  /// In en, this message translates to:
  /// **'No issued passports at the moment.'**
  String get issueEmptyIssued;

  /// No description provided for @issueEmptyDefault.
  ///
  /// In en, this message translates to:
  /// **'No passports found.'**
  String get issueEmptyDefault;

  /// No description provided for @issueLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load passports. Tap to retry.'**
  String get issueLoadFailed;

  /// No description provided for @issueFailed.
  ///
  /// In en, this message translates to:
  /// **'Issue failed — please try again.'**
  String get issueFailed;

  /// No description provided for @issueScanToConfirm.
  ///
  /// In en, this message translates to:
  /// **'Scan to Confirm'**
  String get issueScanToConfirm;

  /// No description provided for @issuePointCamera.
  ///
  /// In en, this message translates to:
  /// **'Point the camera at the passport QR code to confirm identity.'**
  String get issuePointCamera;

  /// No description provided for @issueLoaded.
  ///
  /// In en, this message translates to:
  /// **'{count} loaded'**
  String issueLoaded(Object count);

  /// No description provided for @issueIdLabel.
  ///
  /// In en, this message translates to:
  /// **'ID: {id}'**
  String issueIdLabel(Object id);

  /// No description provided for @issueIssuedTo.
  ///
  /// In en, this message translates to:
  /// **'Issued to {name}'**
  String issueIssuedTo(Object name);

  /// No description provided for @issueWrongQr.
  ///
  /// In en, this message translates to:
  /// **'Wrong QR — expected {qr}'**
  String issueWrongQr(Object qr);

  /// No description provided for @returnFlowTitle.
  ///
  /// In en, this message translates to:
  /// **'Return Custody Flow'**
  String get returnFlowTitle;

  /// No description provided for @returnStepScan.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get returnStepScan;

  /// No description provided for @returnStepSelectBox.
  ///
  /// In en, this message translates to:
  /// **'Select Box'**
  String get returnStepSelectBox;

  /// No description provided for @returnStepScanBox.
  ///
  /// In en, this message translates to:
  /// **'Scan Box'**
  String get returnStepScanBox;

  /// No description provided for @returnFailedLoadRooms.
  ///
  /// In en, this message translates to:
  /// **'Failed to load rooms'**
  String get returnFailedLoadRooms;

  /// No description provided for @returnFailedLoadBoxes.
  ///
  /// In en, this message translates to:
  /// **'Failed to load available boxes'**
  String get returnFailedLoadBoxes;

  /// No description provided for @returnBoxQrVerified.
  ///
  /// In en, this message translates to:
  /// **'Box QR verified'**
  String get returnBoxQrVerified;

  /// No description provided for @returnMismatchTitle.
  ///
  /// In en, this message translates to:
  /// **'Physical Box Mismatch'**
  String get returnMismatchTitle;

  /// No description provided for @returnMismatchNoCapacity.
  ///
  /// In en, this message translates to:
  /// **'Note: The physically scanned box does not have enough capacity for your stack.'**
  String get returnMismatchNoCapacity;

  /// No description provided for @returnFindCorrectBox.
  ///
  /// In en, this message translates to:
  /// **'Find Correct Box'**
  String get returnFindCorrectBox;

  /// No description provided for @returnCancelRescan.
  ///
  /// In en, this message translates to:
  /// **'Cancel & Rescan'**
  String get returnCancelRescan;

  /// No description provided for @returnNetworkError.
  ///
  /// In en, this message translates to:
  /// **'Network error'**
  String get returnNetworkError;

  /// No description provided for @returnBackToDashboard.
  ///
  /// In en, this message translates to:
  /// **'Back to Dashboard'**
  String get returnBackToDashboard;

  /// No description provided for @returnAnotherBatch.
  ///
  /// In en, this message translates to:
  /// **'Return Another Batch'**
  String get returnAnotherBatch;

  /// No description provided for @returnScannedLabel.
  ///
  /// In en, this message translates to:
  /// **'scanned'**
  String get returnScannedLabel;

  /// No description provided for @returnScanPassportHint.
  ///
  /// In en, this message translates to:
  /// **'Point camera at a passport QR code'**
  String get returnScanPassportHint;

  /// No description provided for @returnClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get returnClearAll;

  /// No description provided for @returnNoPassportsYet.
  ///
  /// In en, this message translates to:
  /// **'No passports scanned yet'**
  String get returnNoPassportsYet;

  /// No description provided for @returnFindStorageBox.
  ///
  /// In en, this message translates to:
  /// **'Find Storage Box'**
  String get returnFindStorageBox;

  /// No description provided for @returnSelectTargetBox.
  ///
  /// In en, this message translates to:
  /// **'Select Target Storage Box'**
  String get returnSelectTargetBox;

  /// No description provided for @returnAllRooms.
  ///
  /// In en, this message translates to:
  /// **'All rooms'**
  String get returnAllRooms;

  /// No description provided for @returnSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by box label or QR code...'**
  String get returnSearchHint;

  /// No description provided for @returnNoSuitableBoxes.
  ///
  /// In en, this message translates to:
  /// **'No suitable boxes found.\nTry changing your filters.'**
  String get returnNoSuitableBoxes;

  /// No description provided for @returnPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get returnPrevious;

  /// No description provided for @returnNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get returnNext;

  /// No description provided for @returnConfirmReturn.
  ///
  /// In en, this message translates to:
  /// **'Confirm Return'**
  String get returnConfirmReturn;

  /// No description provided for @returnVerifyPhysicalBox.
  ///
  /// In en, this message translates to:
  /// **'Verify Physical Box'**
  String get returnVerifyPhysicalBox;

  /// No description provided for @returnBoxVerifiedDesc.
  ///
  /// In en, this message translates to:
  /// **'Box verified. Review the details and complete the return.'**
  String get returnBoxVerifiedDesc;

  /// No description provided for @returnScanBoxDesc.
  ///
  /// In en, this message translates to:
  /// **'Scan the QR code on the physical box to verify box custody identity.'**
  String get returnScanBoxDesc;

  /// No description provided for @returnScanBoxHint.
  ///
  /// In en, this message translates to:
  /// **'Point camera at Box QR code'**
  String get returnScanBoxHint;

  /// No description provided for @returnRescanBox.
  ///
  /// In en, this message translates to:
  /// **'Rescan Box'**
  String get returnRescanBox;

  /// No description provided for @returnCompleteAssign.
  ///
  /// In en, this message translates to:
  /// **'Complete Return & Assign'**
  String get returnCompleteAssign;

  /// No description provided for @returnUnassigned.
  ///
  /// In en, this message translates to:
  /// **'Unassigned'**
  String get returnUnassigned;

  /// No description provided for @returnUnassignedLocation.
  ///
  /// In en, this message translates to:
  /// **'Unassigned Location'**
  String get returnUnassignedLocation;

  /// No description provided for @returnPassportsReturned.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 Passport Returned} other{{count} Passports Returned}}'**
  String returnPassportsReturned(int count);

  /// No description provided for @returnOnlyIssued.
  ///
  /// In en, this message translates to:
  /// **'{name} is currently {status} — only ISSUED passports can be returned'**
  String returnOnlyIssued(Object name, Object status);

  /// No description provided for @returnAdded.
  ///
  /// In en, this message translates to:
  /// **'Added: {name}'**
  String returnAdded(Object name);

  /// No description provided for @returnErrLookupPassport.
  ///
  /// In en, this message translates to:
  /// **'Error looking up passport: {error}'**
  String returnErrLookupPassport(Object error);

  /// No description provided for @returnWrongBoxQr.
  ///
  /// In en, this message translates to:
  /// **'Wrong box QR scanned. Expected {label}, but scanned QR code is unrecognized in the system.'**
  String returnWrongBoxQr(Object label);

  /// No description provided for @returnErrLookupBox.
  ///
  /// In en, this message translates to:
  /// **'Error looking up scanned box: {error}'**
  String returnErrLookupBox(Object error);

  /// No description provided for @returnMismatchDetail.
  ///
  /// In en, this message translates to:
  /// **'Expected Box: {expected}\nScanned Box: {scanned} ({location})'**
  String returnMismatchDetail(Object expected, Object scanned, Object location);

  /// No description provided for @returnMismatchFits.
  ///
  /// In en, this message translates to:
  /// **'The physically scanned box has {vacant} vacant slots, which fits your {count} passports.'**
  String returnMismatchFits(Object vacant, Object count);

  /// No description provided for @returnSwitchedBox.
  ///
  /// In en, this message translates to:
  /// **'Switched to physically scanned box: {label}'**
  String returnSwitchedBox(Object label);

  /// No description provided for @returnUseBox.
  ///
  /// In en, this message translates to:
  /// **'Use {label}'**
  String returnUseBox(Object label);

  /// No description provided for @returnFailed.
  ///
  /// In en, this message translates to:
  /// **'Return failed: {error}'**
  String returnFailed(Object error);

  /// No description provided for @returnStoredIn.
  ///
  /// In en, this message translates to:
  /// **'Stored in {label}'**
  String returnStoredIn(Object label);

  /// No description provided for @returnScannedStack.
  ///
  /// In en, this message translates to:
  /// **'Scanned Stack ({count})'**
  String returnScannedStack(Object count);

  /// No description provided for @returnPassportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{qr} • ID: {id}'**
  String returnPassportSubtitle(Object qr, Object id);

  /// No description provided for @returnShowingBoxes.
  ///
  /// In en, this message translates to:
  /// **'Showing boxes with at least {count} available slots'**
  String returnShowingBoxes(Object count);

  /// No description provided for @returnFoundBoxes.
  ///
  /// In en, this message translates to:
  /// **'Found {total} boxes • Page {page} of {pages}'**
  String returnFoundBoxes(Object total, Object page, Object pages);

  /// No description provided for @returnLoadMoreRemaining.
  ///
  /// In en, this message translates to:
  /// **'Load More ({remaining} remaining)'**
  String returnLoadMoreRemaining(Object remaining);

  /// No description provided for @returnVacant.
  ///
  /// In en, this message translates to:
  /// **'{count} vacant'**
  String returnVacant(Object count);

  /// No description provided for @returnPageOf.
  ///
  /// In en, this message translates to:
  /// **'Page {page} of {pages}'**
  String returnPageOf(Object page, Object pages);

  /// No description provided for @returnCapacity.
  ///
  /// In en, this message translates to:
  /// **'Capacity: {occupied}/{capacity} occupied'**
  String returnCapacity(Object occupied, Object capacity);

  /// No description provided for @returnExpectedQr.
  ///
  /// In en, this message translates to:
  /// **'Expected QR Code: {qr}'**
  String returnExpectedQr(Object qr);

  /// No description provided for @returnExpectedLocation.
  ///
  /// In en, this message translates to:
  /// **'Expected Location: {location}'**
  String returnExpectedLocation(Object location);

  /// No description provided for @returnVerifiedBox.
  ///
  /// In en, this message translates to:
  /// **'Verified Box: {label}'**
  String returnVerifiedBox(Object label);

  /// No description provided for @returnReturningCount.
  ///
  /// In en, this message translates to:
  /// **'Returning {count} passports'**
  String returnReturningCount(Object count);

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navExplorer.
  ///
  /// In en, this message translates to:
  /// **'Explorer'**
  String get navExplorer;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @vaultTitle.
  ///
  /// In en, this message translates to:
  /// **'Vault Explorer'**
  String get vaultTitle;

  /// No description provided for @vaultSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Browse rooms, shelves & slot inventory'**
  String get vaultSubtitle;

  /// No description provided for @vaultRooms.
  ///
  /// In en, this message translates to:
  /// **'Rooms'**
  String get vaultRooms;

  /// No description provided for @vaultNoRooms.
  ///
  /// In en, this message translates to:
  /// **'No Rooms Configured'**
  String get vaultNoRooms;

  /// No description provided for @vaultNoShelves.
  ///
  /// In en, this message translates to:
  /// **'No Shelves Configured'**
  String get vaultNoShelves;

  /// No description provided for @vaultNoRows.
  ///
  /// In en, this message translates to:
  /// **'No Rows Configured'**
  String get vaultNoRows;

  /// No description provided for @vaultNoSlots.
  ///
  /// In en, this message translates to:
  /// **'No Slots Configured'**
  String get vaultNoSlots;

  /// No description provided for @vaultOccupied.
  ///
  /// In en, this message translates to:
  /// **'Occupied:'**
  String get vaultOccupied;

  /// No description provided for @vaultEmptySlot.
  ///
  /// In en, this message translates to:
  /// **'EMPTY SLOT'**
  String get vaultEmptySlot;

  /// No description provided for @vaultContainedPassports.
  ///
  /// In en, this message translates to:
  /// **'Contained Passports'**
  String get vaultContainedPassports;

  /// No description provided for @vaultNoPassportsInside.
  ///
  /// In en, this message translates to:
  /// **'No passports inside this box'**
  String get vaultNoPassportsInside;

  /// No description provided for @vaultShelvesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Shelves'**
  String vaultShelvesCount(Object count);

  /// No description provided for @vaultRowsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Rows'**
  String vaultRowsCount(Object count);

  /// No description provided for @vaultSlotsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Slots'**
  String vaultSlotsCount(Object count);

  /// No description provided for @vaultPosition.
  ///
  /// In en, this message translates to:
  /// **'Position {position}'**
  String vaultPosition(Object position);

  /// No description provided for @vaultQrLabel.
  ///
  /// In en, this message translates to:
  /// **'QR: {qr}'**
  String vaultQrLabel(Object qr);

  /// No description provided for @biometricSecurity.
  ///
  /// In en, this message translates to:
  /// **'Biometric Security'**
  String get biometricSecurity;

  /// No description provided for @biometricSecurityDesc.
  ///
  /// In en, this message translates to:
  /// **'Protect your active session using fingerprint or Face ID'**
  String get biometricSecurityDesc;

  /// No description provided for @biometricNotSupported.
  ///
  /// In en, this message translates to:
  /// **'Biometrics not supported or enrolled on this device'**
  String get biometricNotSupported;

  /// No description provided for @pressBackAgainToExit.
  ///
  /// In en, this message translates to:
  /// **'Press back again to exit'**
  String get pressBackAgainToExit;

  /// No description provided for @appTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get appTheme;

  /// No description provided for @selectTheme.
  ///
  /// In en, this message translates to:
  /// **'Select Theme'**
  String get selectTheme;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;
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
      <String>['am', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'am':
      return AppLocalizationsAm();
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
