import 'dart:async';
import 'package:flutter/material.dart';
import '../models/notification.dart';
import '../services/notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/user_mode.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<AppNotification> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  bool _isInitialized = false;
  StreamSubscription? _notificationSubscription;
  StreamSubscription? _authSubscription;

  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;

  NotificationProvider() {
    print('NotificationProvider initialized');
    _initAuthListener();
  }

  // Public method to manually refresh notifications
  Future<void> refreshNotifications() async {
    print('Manually refreshing notifications');
    await _loadNotifications();
  }

  // Separate method for initializing the auth listener
  void _initAuthListener() {
    // Check if already initialized to prevent double initialization
    if (_authSubscription != null) return;

    try {
      // Listen for auth state changes
      _authSubscription = _auth.authStateChanges().listen((User? user) {
        if (user != null) {
          print('User logged in: ${user.uid}');
          // User logged in
          if (!_isInitialized) {
            _initialize();
          } else {
            // Refresh notifications if user changed
            _loadNotifications();
          }
        } else {
          print('User logged out');
          // User logged out
          _clearNotifications();
        }
      }, onError: (error) {
        print('Auth state listener error: $error');
      });
    } catch (e) {
      print('Error setting up auth listener: $e');
    }
  }

  Future<void> _initialize() async {
    if (_isInitialized) return; // Prevent multiple initializations

    try {
      _isLoading = true;
      if (mounted) notifyListeners();

      await _notificationService.init();
      await _loadNotifications();
      await _refreshUnreadCount();

      _isInitialized = true;
      _isLoading = false;
      if (mounted) notifyListeners();
    } catch (e) {
      _isLoading = false;
      print('Error initializing notifications: $e');
      if (mounted) notifyListeners();
    }
  }

  // Helper to check if provider is still attached to the widget tree
  bool get mounted => !_disposed;
  bool _disposed = false;

  Future<void> _loadNotifications() async {
    if (_auth.currentUser == null) return;

    _isLoading = true;
    if (mounted) notifyListeners();

    // Cancel any existing subscription to prevent memory leaks
    _notificationSubscription?.cancel();

    try {
      // Check current user's role to fetch appropriate notifications
      final isWorker = await UserMode.isWorkerMode();
      final targetRole = isWorker ? UserRole.worker : UserRole.customer;

      print(
          'Loading notifications for user role: ${targetRole == UserRole.worker ? "Worker" : "Customer"}');

      _notificationSubscription = _notificationService
          .getUserNotifications(targetRole: targetRole)
          .listen((notifications) {
        _notifications = notifications;
        _unreadCount = notifications.where((n) => !n.isRead).length;
        _isLoading = false;
        print(
            'Loaded ${notifications.length} notifications, unread: $_unreadCount');
        if (mounted) notifyListeners();
      }, onError: (error) {
        print('Error loading notifications: $error');
        _isLoading = false;
        if (mounted) notifyListeners();
      });
    } catch (e) {
      _isLoading = false;
      print('Error setting up notifications stream: $e');
      if (mounted) notifyListeners();
    }
  }

  void _clearNotifications() {
    _notifications = [];
    _unreadCount = 0;
    _isLoading = false;
    _notificationSubscription?.cancel();
    if (mounted) notifyListeners();
  }

  Future<void> _refreshUnreadCount() async {
    if (_auth.currentUser == null) return;

    try {
      _unreadCount = await _notificationService.getUnreadNotificationCount();
      if (mounted) notifyListeners();
    } catch (e) {
      print('Error refreshing unread count: $e');
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationService.markNotificationAsRead(notificationId);

      // Update local state
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
        if (mounted) notifyListeners();
      }
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _notificationService.markAllNotificationsAsRead();

      // Update local state
      _notifications =
          _notifications.map((n) => n.copyWith(isRead: true)).toList();
      _unreadCount = 0;
      if (mounted) notifyListeners();
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  List<AppNotification> getFilteredNotifications(NotificationType type) {
    return _notifications.where((n) => n.type == type).toList();
  }

  // For testing - create a test notification
  Future<void> createTestNotification() async {
    try {
      await _notificationService.sendTestNotification(
        title: 'Test Notification',
        body: 'This is a test notification created at ${DateTime.now()}',
        type: NotificationType.promotional,
        targetUserRole: UserRole.customer,
      );
    } catch (e) {
      print('Error creating test notification: $e');
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _notificationSubscription?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }
}
