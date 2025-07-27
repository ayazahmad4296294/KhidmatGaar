// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Urdu (`ur`).
class AppLocalizationsUr extends AppLocalizations {
  AppLocalizationsUr([String locale = 'ur']) : super(locale);

  @override
  String get appTitle => 'خدمت';

  @override
  String get home => 'ہوم';

  @override
  String get myPackages => 'میرے پیکجز';

  @override
  String get loyaltyPoints => 'وفاداری پوائنٹس';

  @override
  String get referral => 'ریفرل';

  @override
  String get myConversations => 'میری گفتگو';

  @override
  String get aboutUs => 'ہمارے بارے میں';

  @override
  String get termsAndConditions => 'شرائط و ضوابط';

  @override
  String get privacyPolicy => 'پرائیویسی پالیسی';

  @override
  String get logout => 'لاگ آؤٹ';

  @override
  String get switchToWorkerMode => 'ورکر موڈ پر جائیں';

  @override
  String get language => 'زبان';

  @override
  String get english => 'انگریزی';

  @override
  String get urdu => 'اردو';

  @override
  String get confirmLogout => 'لاگ آؤٹ کی تصدیق کریں';

  @override
  String get areYouSureLogout => 'کیا آپ واقعی لاگ آؤٹ کرنا چاہتے ہیں؟';

  @override
  String get cancel => 'منسوخ کریں';

  @override
  String get errorFetchingUserData => 'صارف کا ڈیٹا حاصل کرنے میں خرابی';

  @override
  String get userDataNotFound => 'صارف کا ڈیٹا نہیں ملا';

  @override
  String get noName => 'نام نہیں ہے';

  @override
  String get noEmail => 'ای میل نہیں ہے';

  @override
  String get pleaseEnterValidPassword => 'براہ کرم درست پاس ورڈ درج کریں';

  @override
  String get enterAdminPassword => 'ایڈمن پاس ورڈ درج کریں';

  @override
  String get password => 'پاس ورڈ';

  @override
  String get submit => 'جمع کریں';

  @override
  String get ok => 'ٹھیک ہے';

  @override
  String get yes => 'ہاں';

  @override
  String get no => 'نہیں';

  @override
  String get confirm => 'تصدیق کریں';

  @override
  String get save => 'محفوظ کریں';

  @override
  String get editName => 'نام میں ترمیم کریں';

  @override
  String get editPhoneNumber => 'فون نمبر میں ترمیم کریں';

  @override
  String get fullName => 'پورا نام';

  @override
  String get phoneNumber => 'فون نمبر';

  @override
  String get cancelBooking => 'بکنگ منسوخ کریں';

  @override
  String get areYouSureCancelBooking => 'کیا آپ واقعی اس بکنگ کو منسوخ کرنا چاہتے ہیں؟ اس عمل کو واپس نہیں کیا جا سکتا۔';

  @override
  String get bookingCancelledSuccessfully => 'بکنگ کامیابی سے منسوخ ہو گئی';

  @override
  String errorCancellingBooking(Object error) {
    return 'بکنگ منسوخ کرنے میں خرابی: $error';
  }

  @override
  String get yesCancel => 'ہاں، منسوخ کریں';

  @override
  String get noCancel => 'نہیں';

  @override
  String get applyLoyaltyPoints => 'وفاداری پوائنٹس لگائیں';

  @override
  String availablePoints(Object points) {
    return 'دستیاب پوائنٹس: $points';
  }

  @override
  String bookingTotal(Object price) {
    return 'کل بکنگ: PKR $price';
  }

  @override
  String get pointsToRedeem => 'ریڈیم کرنے کے پوائنٹس';

  @override
  String get enterPointsHint => 'پوائنٹس درج کریں (کم از کم 500)';

  @override
  String get pleaseEnterPoints => 'براہ کرم ریڈیم کرنے کے پوائنٹس درج کریں';

  @override
  String get pleaseEnterValidNumber => 'براہ کرم درست نمبر درج کریں';

  @override
  String get minimumPointsRequired => 'کم از کم 500 پوائنٹس درکار ہیں';

  @override
  String get notEnoughPoints => 'آپ کے پاس کافی پوائنٹس نہیں ہیں';

  @override
  String get pointsMustBeMultiple => 'پوائنٹس 500 کے مضاعف میں ہونے چاہئیں';

  @override
  String get reviewSubmittedSuccessfully => 'جائزہ کامیابی سے جمع ہو گیا';

  @override
  String get writeAReview => 'جائزہ لکھیں';

  @override
  String get yourReview => 'آپ کا جائزہ';

  @override
  String errorSubmittingReview(Object error) {
    return 'جائزہ جمع کرنے میں خرابی: $error';
  }

  @override
  String get sendPromotionalNotification => 'پروموشنل نوٹیفکیشن بھیجیں';

  @override
  String get notificationTitle => 'نوٹیفکیشن عنوان';

  @override
  String get notificationMessage => 'نوٹیفکیشن پیغام';

  @override
  String get pleaseEnterTitle => 'براہ کرم عنوان درج کریں';

  @override
  String get pleaseEnterMessage => 'براہ کرم پیغام درج کریں';

  @override
  String errorSendingNotifications(Object error) {
    return 'نوٹیفکیشن بھیجنے میں خرابی: $error';
  }

  @override
  String get redeemPoints => 'پوائنٹس ریڈیم کریں';

  @override
  String get pointsToRedeemLabel => 'ریڈیم کرنے کے پوائنٹس';

  @override
  String get pointsToRedeemHint => 'پوائنٹس درج کریں (کم از کم 500)';

  @override
  String get pleaseEnterPointsToRedeem => 'براہ کرم ریڈیم کرنے کے پوائنٹس درج کریں';

  @override
  String get minimum500PointsRequired => 'کم از کم 500 پوائنٹس درکار ہیں';

  @override
  String get dontHaveEnoughPoints => 'آپ کے پاس کافی پوائنٹس نہیں ہیں';

  @override
  String get noScheduledServices => 'کوئی شیڈول سروسز نہیں ہیں';

  @override
  String get startService => 'سروس شروع کریں';

  @override
  String get markComplete => 'مکمل کریں';

  @override
  String get accept => 'قبول کریں';

  @override
  String get negotiate => 'مذاکرات کریں';

  @override
  String get confirmAcceptance => 'قبولیت کی تصدیق کریں';

  @override
  String get service => 'سروس';

  @override
  String get date => 'تاریخ';

  @override
  String get price => 'قیمت';

  @override
  String get pending => 'زیر التواء';

  @override
  String get completed => 'مکمل';

  @override
  String get all => 'تمام';

  @override
  String get filterBookings => 'بکنگز کو فلٹر کریں';

  @override
  String get somethingWentWrong => 'کچھ غلط ہو گیا';

  @override
  String get status => 'حالت';

  @override
  String get scheduled => 'شیڈول شدہ';
}
