import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'app_screens/splash_screen.dart';
import 'app_screens/home_page.dart';
import 'app_screens/notifications_screen.dart';
import 'email_auth/login_page.dart';
import 'email_auth/signup_page.dart';
import 'providers/auth_provider.dart';
import 'providers/location_provider.dart';
import 'providers/notification_provider.dart';
import 'utils/user_mode.dart';
import 'services/firebase_service.dart';
import 'app_screens/booking_details_screen.dart';
import 'app_screens/user_bookings_screen.dart';
import 'worker/worker_dashboard.dart';
import 'service_provider/price_negotiation_worker_screen.dart';
import 'service_provider/registration/pending_approval_page.dart';
import 'utils/firebase_init.dart';
import 'package:flutter/foundation.dart';
import 'services/location_picker.dart';
import 'admin_module/admin_conversations_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Global key for navigator to use in notification service
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Background message handler must be defined at top level
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase using our centralized initialization service
  await FirebaseInit.ensureInitialized();

  print('Handling a background message: ${message.messageId}');
  // The notification will be saved to Firestore in the background handler
}

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');
  Locale get locale => _locale;

  void setLocale(Locale locale) {
    if (!AppLocalizations.supportedLocales.contains(locale)) return;
    _locale = locale;
    notifyListeners();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  // TODO: Add your Supabase URL and anon key here
  await Supabase.initialize(
    url: 'https://lbsbqaeqstrantpawtdk.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxic2JxYWVxc3RyYW50cGF3dGRrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTA4NDIzNzEsImV4cCI6MjA2NjQxODM3MX0.AAh_JKG4PvB0DtPT_s7IUzSRvofujjpwHqijSOxWyns',
  );

  // Add error handling for the entire app
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Flutter error caught: ${details.exception}');
    // You could also log errors to a service here
  };

  // Setup for uncaught asynchronous errors
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Uncaught asynchronous error: $error');
    // You could also log errors to a service here
    return true;
  };

  // Initialize Firebase using our centralized initialization service
  bool firebaseInitialized = await FirebaseInit.ensureInitialized();

  if (!firebaseInitialized) {
    debugPrint(
        'Warning: Firebase initialization failed. Some features may not work properly.');
  }

  try {
    // Initialize AwesomeNotifications
    await AwesomeNotifications().initialize(
      null, // No app icon needed as we'll create channels through notification service
      [
        NotificationChannel(
          channelKey: 'high_importance_channel',
          channelName: 'High Importance Notifications',
          channelDescription:
              'This channel is used for important notifications.',
          defaultColor: const Color(0xFF9D50DD),
          ledColor: Colors.white,
          importance: NotificationImportance.High,
          defaultPrivacy: NotificationPrivacy.Private,
        )
      ],
    );

    // Request notification permissions
    await AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });

    // Only set up FCM if Firebase was properly initialized
    if (firebaseInitialized) {
      // Set up Firebase Cloud Messaging background handler
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);

      // Request permission for notifications
      final fcm = FirebaseMessaging.instance;
      await fcm.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      // Get FCM token for this device
      String? token = await fcm.getToken();
      print('FCM Token: $token');

      // Initialize chat collections
      final firebaseService = FirebaseService();
      await firebaseService.setupChatCollections();

      // Setup admin account for development purposes
      await firebaseService.setupAdminAccount();
    }
  } catch (e) {
    debugPrint('Error during initialization: $e');
    // Continue with app startup even if some services failed
  }

  final isWorkerMode = await UserMode.isWorkerMode();
  runApp(
    ChangeNotifierProvider(
      create: (_) => LocaleProvider(),
      child: MyApp(isWorkerMode: isWorkerMode),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool isWorkerMode;

  const MyApp({super.key, required this.isWorkerMode});

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: MaterialApp(
        title: 'Khidmat',
        navigatorKey: navigatorKey, // Set the navigator key for notifications
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        debugShowCheckedModeBanner: false,
        locale: localeProvider.locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        initialRoute: '/splash',
        routes: {
          '/splash': (context) => SplashScreen(isWorkerMode: isWorkerMode),
          '/': (context) => const HomePage(),
          '/login': (context) => const LoginPage(),
          '/signup': (context) => const SignupPage(),
          '/notifications': (context) => const NotificationsScreen(),
          '/worker-dashboard': (context) => const WorkerDashboard(),
          '/bookings': (context) => const UserBookingsScreen(),
          '/pending-approval': (context) => const PendingApprovalPage(),
          '/admin-conversations': (context) => const AdminConversationsScreen(),
          '/price-negotiation': (context) {
            final args = ModalRoute.of(context)?.settings.arguments
                as Map<String, dynamic>?;
            if (args != null) {
              return PriceNegotiationWorkerScreen(
                negotiationId: args['negotiationId'] ?? '',
                customerName: args['customerName'] ?? 'Customer',
              );
            }
            // Fallback to dashboard if no args
            return const WorkerDashboard();
          },
          '/booking-details': (context) {
            final bookingId =
                ModalRoute.of(context)?.settings.arguments as String?;
            if (bookingId != null) {
              return BookingDetailsScreen(bookingId: bookingId);
            }
            // Fallback to user bookings page instead of BookingScreen
            return const UserBookingsScreen();
          },
          '/location_picker': (context) => LocationPicker(
                onLocationSelected: (latitude, longitude, address) {
                  // This will be overridden by the caller's implementation
                  // Just providing a default implementation for the route
                  Navigator.pop(context);
                },
              ),
          '/admin-conversations': (context) => const AdminConversationsScreen(),
        },
        // Add error handling for routes
        onUnknownRoute: (settings) {
          return MaterialPageRoute(
            builder: (context) => const HomePage(),
          );
        },
      ),
    );
  }
}
