// ignore_for_file: invalid_use_of_protected_member
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'drawer/mydrawer.dart';
import 'home_content.dart';
import '../user_module/account_management.dart';
import 'package:location/location.dart' as loc;
//import 'package:permission_handler/permission_handler.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:async';
import '../services_for_users/active_negotiations_screen.dart';
import 'user_bookings_screen.dart';
import '../providers/notification_provider.dart';
//import 'package:flutter/foundation.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  // Static method to handle navigation to bookings tab from other screens
  static void navigateToBookingsTab(BuildContext context) {
    // Find the closest HomePage state
    final homeState = context.findAncestorStateOfType<_HomePageState>();

    if (homeState != null) {
      // If found on the same stack, just set the tab index
      homeState.setState(() {
        homeState._selectedIndex = 1; // Bookings tab index
      });
    } else {
      // Otherwise navigate to HomePage with bookings tab selected
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const HomePage(),
          settings: const RouteSettings(name: 'HomePage'),
        ),
        (route) => false,
      ).then((_) {
        // After building the HomePage, select the bookings tab
        final homeState = context.findAncestorStateOfType<_HomePageState>();
        if (homeState != null) {
          homeState.setState(() {
            homeState._selectedIndex = 1;
          });
        }
      });
    }
  }

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final loc.Location _location = loc.Location();
  String _locationText = 'Getting location...';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkAndRequestPermission();

    // Check if we need to navigate to a specific tab
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null &&
          args is Map<String, dynamic> &&
          args.containsKey('tab')) {
        final tab = args['tab'] as String;
        if (tab == 'bookings') {
          setState(() {
            _selectedIndex = 1; // Bookings tab
          });
        }
      }
    });
  }

  Future<void> _checkAndRequestPermission() async {
    try {
      setState(() {
        _isLoading = true;
      });

      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) {
          setState(() {
            _locationText = 'Please enable location services';
            _isLoading = false;
          });
          return;
        }
      }

      loc.PermissionStatus permissionStatus = await _location.hasPermission();
      if (permissionStatus == loc.PermissionStatus.denied) {
        permissionStatus = await _location.requestPermission();
        if (permissionStatus != loc.PermissionStatus.granted) {
          setState(() {
            _locationText = 'Location permission denied';
            _isLoading = false;
          });
          return;
        }
      }

      if (permissionStatus == loc.PermissionStatus.granted) {
        await _getLocation();
      }
    } catch (e) {
      setState(() {
        _locationText = 'Error checking permissions: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _getLocation() async {
    try {
      setState(() {
        _isLoading = true;
        _locationText = 'Getting location...';
      });

      final locationData = await _location.getLocation().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Location request timed out');
        },
      );

      if (locationData.latitude == null || locationData.longitude == null) {
        setState(() {
          _locationText = 'Location coordinates are unavailable';
          _isLoading = false;
        });
        return;
      }

      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          locationData.latitude!,
          locationData.longitude!,
        ).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw TimeoutException('Address lookup timed out');
          },
        );

        if (placemarks.isEmpty) {
          setState(() {
            _locationText = 'Could not determine address';
            _isLoading = false;
          });
          return;
        }

        Placemark place = placemarks[0];
        String address = '';

        // Format address similar to the screenshot
        if (place.subThoroughfare?.isNotEmpty ?? false) {
          address += 'Plot ${place.subThoroughfare}, ';
        }
        if (place.thoroughfare?.isNotEmpty ?? false) {
          address += '${place.thoroughfare}, ';
        }
        if (place.subLocality?.isNotEmpty ?? false) {
          address += '${place.subLocality}, ';
        }
        if (place.locality?.isNotEmpty ?? false) {
          address += '${place.locality}, ';
        }
        if (place.administrativeArea?.isNotEmpty ?? false) {
          address += '${place.administrativeArea}, ';
        }
        if (place.country?.isNotEmpty ?? false) {
          address += place.country!;
        }

        setState(() {
          _locationText = address;
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _locationText =
              'Location: ${locationData.latitude}, ${locationData.longitude}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _locationText = 'Error getting location: $e';
        _isLoading = false;
      });
    }
  }

  final List<Widget> _pages = [
    const HomeContent(),
    const UserBookingsScreen(),
    const UserProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.purple,
        title: Row(
          children: [
            const Icon(Icons.location_on, size: 20, color: Colors.red),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Current Location',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    _locationText,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              color: Colors.white,
              onPressed: _isLoading ? null : _getLocation,
            ),
            Consumer<NotificationProvider>(
              builder: (context, notificationProvider, child) {
                return Stack(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.notifications,
                        color: Colors.yellow,
                      ),
                      onPressed: () {
                        Navigator.pushNamed(context, '/notifications');
                      },
                    ),
                    if (notificationProvider.unreadCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            notificationProvider.unreadCount > 9
                                ? '9+'
                                : notificationProvider.unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
      drawer: const MyDrawer(),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag),
            label: 'Bookings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}
