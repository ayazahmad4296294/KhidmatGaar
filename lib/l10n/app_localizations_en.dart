// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Khidmat';

  @override
  String get home => 'Home';

  @override
  String get myPackages => 'My Packages';

  @override
  String get loyaltyPoints => 'Loyalty Points';

  @override
  String get referral => 'Referral';

  @override
  String get myConversations => 'My Conversations';

  @override
  String get aboutUs => 'About Us';

  @override
  String get termsAndConditions => 'Terms and Conditions';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get logout => 'Logout';

  @override
  String get switchToWorkerMode => 'Switch to Worker Mode';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get urdu => 'Urdu';

  @override
  String get confirmLogout => 'Confirm Logout';

  @override
  String get areYouSureLogout => 'Are you sure you want to logout?';

  @override
  String get cancel => 'Cancel';

  @override
  String get errorFetchingUserData => 'Error fetching user data';

  @override
  String get userDataNotFound => 'User data not found';

  @override
  String get noName => 'No Name';

  @override
  String get noEmail => 'No Email';

  @override
  String get pleaseEnterValidPassword => 'Please enter a valid password';

  @override
  String get enterAdminPassword => 'Enter Admin Password';

  @override
  String get password => 'Password';

  @override
  String get submit => 'Submit';

  @override
  String get ok => 'OK';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get confirm => 'Confirm';

  @override
  String get save => 'Save';

  @override
  String get editName => 'Edit Name';

  @override
  String get editPhoneNumber => 'Edit Phone Number';

  @override
  String get fullName => 'Full Name';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get cancelBooking => 'Cancel Booking';

  @override
  String get areYouSureCancelBooking => 'Are you sure you want to cancel this booking? This action cannot be undone.';

  @override
  String get bookingCancelledSuccessfully => 'Booking cancelled successfully';

  @override
  String errorCancellingBooking(Object error) {
    return 'Error cancelling booking: $error';
  }

  @override
  String get yesCancel => 'Yes, Cancel';

  @override
  String get noCancel => 'No';

  @override
  String get applyLoyaltyPoints => 'Apply Loyalty Points';

  @override
  String availablePoints(Object points) {
    return 'Available Points: $points';
  }

  @override
  String bookingTotal(Object price) {
    return 'Booking Total: PKR $price';
  }

  @override
  String get pointsToRedeem => 'Points to Redeem';

  @override
  String get enterPointsHint => 'Enter points (500 minimum)';

  @override
  String get pleaseEnterPoints => 'Please enter points to redeem';

  @override
  String get pleaseEnterValidNumber => 'Please enter a valid number';

  @override
  String get minimumPointsRequired => 'Minimum 500 points required';

  @override
  String get notEnoughPoints => 'You don\'t have enough points';

  @override
  String get pointsMustBeMultiple => 'Points must be in multiples of 500';

  @override
  String get reviewSubmittedSuccessfully => 'Review submitted successfully';

  @override
  String get writeAReview => 'Write a Review';

  @override
  String get yourReview => 'Your Review';

  @override
  String errorSubmittingReview(Object error) {
    return 'Error submitting review: $error';
  }

  @override
  String get sendPromotionalNotification => 'Send Promotional Notification';

  @override
  String get notificationTitle => 'Notification Title';

  @override
  String get notificationMessage => 'Notification Message';

  @override
  String get pleaseEnterTitle => 'Please enter a title';

  @override
  String get pleaseEnterMessage => 'Please enter a message';

  @override
  String errorSendingNotifications(Object error) {
    return 'Error sending notifications: $error';
  }

  @override
  String get redeemPoints => 'Redeem Points';

  @override
  String get pointsToRedeemLabel => 'Points to Redeem';

  @override
  String get pointsToRedeemHint => 'Enter points (500 minimum)';

  @override
  String get pleaseEnterPointsToRedeem => 'Please enter points to redeem';

  @override
  String get minimum500PointsRequired => 'Minimum 500 points required';

  @override
  String get dontHaveEnoughPoints => 'You don\'t have enough points';

  @override
  String get noScheduledServices => 'No scheduled services';

  @override
  String get startService => 'Start Service';

  @override
  String get markComplete => 'Mark Complete';

  @override
  String get accept => 'Accept';

  @override
  String get negotiate => 'Negotiate';

  @override
  String get confirmAcceptance => 'Confirm Acceptance';

  @override
  String get service => 'Service';

  @override
  String get date => 'Date';

  @override
  String get price => 'Price';

  @override
  String get pending => 'Pending';

  @override
  String get completed => 'Completed';

  @override
  String get all => 'All';

  @override
  String get filterBookings => 'Filter Bookings';

  @override
  String get somethingWentWrong => 'Something went wrong';

  @override
  String get status => 'Status';

  @override
  String get scheduled => 'Scheduled';
}
