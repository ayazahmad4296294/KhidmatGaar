import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ur.dart';

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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ur')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Khidmat'**
  String get appTitle;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @myPackages.
  ///
  /// In en, this message translates to:
  /// **'My Packages'**
  String get myPackages;

  /// No description provided for @loyaltyPoints.
  ///
  /// In en, this message translates to:
  /// **'Loyalty Points'**
  String get loyaltyPoints;

  /// No description provided for @referral.
  ///
  /// In en, this message translates to:
  /// **'Referral'**
  String get referral;

  /// No description provided for @myConversations.
  ///
  /// In en, this message translates to:
  /// **'My Conversations'**
  String get myConversations;

  /// No description provided for @aboutUs.
  ///
  /// In en, this message translates to:
  /// **'About Us'**
  String get aboutUs;

  /// No description provided for @termsAndConditions.
  ///
  /// In en, this message translates to:
  /// **'Terms and Conditions'**
  String get termsAndConditions;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @switchToWorkerMode.
  ///
  /// In en, this message translates to:
  /// **'Switch to Worker Mode'**
  String get switchToWorkerMode;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @urdu.
  ///
  /// In en, this message translates to:
  /// **'Urdu'**
  String get urdu;

  /// No description provided for @confirmLogout.
  ///
  /// In en, this message translates to:
  /// **'Confirm Logout'**
  String get confirmLogout;

  /// No description provided for @areYouSureLogout.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get areYouSureLogout;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @errorFetchingUserData.
  ///
  /// In en, this message translates to:
  /// **'Error fetching user data'**
  String get errorFetchingUserData;

  /// No description provided for @userDataNotFound.
  ///
  /// In en, this message translates to:
  /// **'User data not found'**
  String get userDataNotFound;

  /// No description provided for @noName.
  ///
  /// In en, this message translates to:
  /// **'No Name'**
  String get noName;

  /// No description provided for @noEmail.
  ///
  /// In en, this message translates to:
  /// **'No Email'**
  String get noEmail;

  /// No description provided for @pleaseEnterValidPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid password'**
  String get pleaseEnterValidPassword;

  /// No description provided for @enterAdminPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter Admin Password'**
  String get enterAdminPassword;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @editName.
  ///
  /// In en, this message translates to:
  /// **'Edit Name'**
  String get editName;

  /// No description provided for @editPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Edit Phone Number'**
  String get editPhoneNumber;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @cancelBooking.
  ///
  /// In en, this message translates to:
  /// **'Cancel Booking'**
  String get cancelBooking;

  /// No description provided for @areYouSureCancelBooking.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this booking? This action cannot be undone.'**
  String get areYouSureCancelBooking;

  /// No description provided for @bookingCancelledSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Booking cancelled successfully'**
  String get bookingCancelledSuccessfully;

  /// No description provided for @errorCancellingBooking.
  ///
  /// In en, this message translates to:
  /// **'Error cancelling booking: {error}'**
  String errorCancellingBooking(Object error);

  /// No description provided for @yesCancel.
  ///
  /// In en, this message translates to:
  /// **'Yes, Cancel'**
  String get yesCancel;

  /// No description provided for @noCancel.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get noCancel;

  /// No description provided for @applyLoyaltyPoints.
  ///
  /// In en, this message translates to:
  /// **'Apply Loyalty Points'**
  String get applyLoyaltyPoints;

  /// No description provided for @availablePoints.
  ///
  /// In en, this message translates to:
  /// **'Available Points: {points}'**
  String availablePoints(Object points);

  /// No description provided for @bookingTotal.
  ///
  /// In en, this message translates to:
  /// **'Booking Total: PKR {price}'**
  String bookingTotal(Object price);

  /// No description provided for @pointsToRedeem.
  ///
  /// In en, this message translates to:
  /// **'Points to Redeem'**
  String get pointsToRedeem;

  /// No description provided for @enterPointsHint.
  ///
  /// In en, this message translates to:
  /// **'Enter points (500 minimum)'**
  String get enterPointsHint;

  /// No description provided for @pleaseEnterPoints.
  ///
  /// In en, this message translates to:
  /// **'Please enter points to redeem'**
  String get pleaseEnterPoints;

  /// No description provided for @pleaseEnterValidNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid number'**
  String get pleaseEnterValidNumber;

  /// No description provided for @minimumPointsRequired.
  ///
  /// In en, this message translates to:
  /// **'Minimum 500 points required'**
  String get minimumPointsRequired;

  /// No description provided for @notEnoughPoints.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have enough points'**
  String get notEnoughPoints;

  /// No description provided for @pointsMustBeMultiple.
  ///
  /// In en, this message translates to:
  /// **'Points must be in multiples of 500'**
  String get pointsMustBeMultiple;

  /// No description provided for @reviewSubmittedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Review submitted successfully'**
  String get reviewSubmittedSuccessfully;

  /// No description provided for @writeAReview.
  ///
  /// In en, this message translates to:
  /// **'Write a Review'**
  String get writeAReview;

  /// No description provided for @yourReview.
  ///
  /// In en, this message translates to:
  /// **'Your Review'**
  String get yourReview;

  /// No description provided for @errorSubmittingReview.
  ///
  /// In en, this message translates to:
  /// **'Error submitting review: {error}'**
  String errorSubmittingReview(Object error);

  /// No description provided for @sendPromotionalNotification.
  ///
  /// In en, this message translates to:
  /// **'Send Promotional Notification'**
  String get sendPromotionalNotification;

  /// No description provided for @notificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Notification Title'**
  String get notificationTitle;

  /// No description provided for @notificationMessage.
  ///
  /// In en, this message translates to:
  /// **'Notification Message'**
  String get notificationMessage;

  /// No description provided for @pleaseEnterTitle.
  ///
  /// In en, this message translates to:
  /// **'Please enter a title'**
  String get pleaseEnterTitle;

  /// No description provided for @pleaseEnterMessage.
  ///
  /// In en, this message translates to:
  /// **'Please enter a message'**
  String get pleaseEnterMessage;

  /// No description provided for @errorSendingNotifications.
  ///
  /// In en, this message translates to:
  /// **'Error sending notifications: {error}'**
  String errorSendingNotifications(Object error);

  /// No description provided for @redeemPoints.
  ///
  /// In en, this message translates to:
  /// **'Redeem Points'**
  String get redeemPoints;

  /// No description provided for @pointsToRedeemLabel.
  ///
  /// In en, this message translates to:
  /// **'Points to Redeem'**
  String get pointsToRedeemLabel;

  /// No description provided for @pointsToRedeemHint.
  ///
  /// In en, this message translates to:
  /// **'Enter points (500 minimum)'**
  String get pointsToRedeemHint;

  /// No description provided for @pleaseEnterPointsToRedeem.
  ///
  /// In en, this message translates to:
  /// **'Please enter points to redeem'**
  String get pleaseEnterPointsToRedeem;

  /// No description provided for @minimum500PointsRequired.
  ///
  /// In en, this message translates to:
  /// **'Minimum 500 points required'**
  String get minimum500PointsRequired;

  /// No description provided for @dontHaveEnoughPoints.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have enough points'**
  String get dontHaveEnoughPoints;

  /// No description provided for @noScheduledServices.
  ///
  /// In en, this message translates to:
  /// **'No scheduled services'**
  String get noScheduledServices;

  /// No description provided for @startService.
  ///
  /// In en, this message translates to:
  /// **'Start Service'**
  String get startService;

  /// No description provided for @markComplete.
  ///
  /// In en, this message translates to:
  /// **'Mark Complete'**
  String get markComplete;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @negotiate.
  ///
  /// In en, this message translates to:
  /// **'Negotiate'**
  String get negotiate;

  /// No description provided for @confirmAcceptance.
  ///
  /// In en, this message translates to:
  /// **'Confirm Acceptance'**
  String get confirmAcceptance;

  /// No description provided for @service.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get service;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @filterBookings.
  ///
  /// In en, this message translates to:
  /// **'Filter Bookings'**
  String get filterBookings;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @scheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get scheduled;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'ur'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'ur': return AppLocalizationsUr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
