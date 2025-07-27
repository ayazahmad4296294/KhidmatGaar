import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class LocationProvider with ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Position? _currentPosition;
  String _currentAddress = 'Your location';
  String _fullAddress = '';
  List<String> _savedAddresses = [];

  Position? get currentPosition => _currentPosition;
  String get currentAddress => _currentAddress;
  String get fullAddress => _fullAddress;
  List<String> get savedAddresses => _savedAddresses;

  LocationProvider() {
    _loadSavedAddresses();
  }

  // Load saved addresses from shared preferences
  Future<void> _loadSavedAddresses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedAddressesList = prefs.getStringList('saved_addresses');
      if (savedAddressesList != null) {
        _savedAddresses = savedAddressesList;
      }

      // Load the last used address
      final lastAddress = prefs.getString('last_address');
      if (lastAddress != null) {
        _currentAddress = lastAddress;
      }

      final fullAddress = prefs.getString('full_address');
      if (fullAddress != null) {
        _fullAddress = fullAddress;
      }

      final positionJson = prefs.getString('last_position');
      if (positionJson != null) {
        final Map<String, dynamic> positionMap = json.decode(positionJson);
        _currentPosition = Position(
          latitude: positionMap['latitude'] ?? 0.0,
          longitude: positionMap['longitude'] ?? 0.0,
          timestamp: DateTime.fromMillisecondsSinceEpoch(
              positionMap['timestamp'] ?? 0),
          accuracy: positionMap['accuracy'] ?? 0.0,
          altitude: positionMap['altitude'] ?? 0.0,
          heading: positionMap['heading'] ?? 0.0,
          speed: positionMap['speed'] ?? 0.0,
          speedAccuracy: positionMap['speedAccuracy'] ?? 0.0,
          altitudeAccuracy: positionMap['altitudeAccuracy'] ?? 0.0,
          headingAccuracy: positionMap['headingAccuracy'] ?? 0.0,
        );
      }

      notifyListeners();
    } catch (e) {
      print('Error loading saved addresses: $e');
    }
  }

  // Save address to shared preferences
  Future<void> _saveAddress(String address,
      {bool isFullAddress = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save current address
      await prefs.setString('last_address', _currentAddress);

      // Save full address if provided
      if (isFullAddress) {
        await prefs.setString('full_address', address);
      }

      // Save position
      if (_currentPosition != null) {
        final positionMap = {
          'latitude': _currentPosition!.latitude,
          'longitude': _currentPosition!.longitude,
          'timestamp': _currentPosition!.timestamp.millisecondsSinceEpoch,
          'accuracy': _currentPosition!.accuracy,
          'altitude': _currentPosition!.altitude,
          'heading': _currentPosition!.heading,
          'speed': _currentPosition!.speed,
          'speedAccuracy': _currentPosition!.speedAccuracy,
          'altitudeAccuracy': _currentPosition!.altitudeAccuracy,
          'headingAccuracy': _currentPosition!.headingAccuracy,
        };
        await prefs.setString('last_position', json.encode(positionMap));
      }

      // Add to saved addresses if not already in the list
      if (!_savedAddresses.contains(address)) {
        _savedAddresses.add(address);
        // Keep only the last 5 addresses
        if (_savedAddresses.length > 5) {
          _savedAddresses.removeAt(0);
        }
        await prefs.setStringList('saved_addresses', _savedAddresses);
      }
    } catch (e) {
      print('Error saving address: $e');
    }
  }

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  Future<void> getCurrentLocation() async {
    _isLoading = true;
    notifyListeners();

    try {
      final hasPermission = await _handleLocationPermission();
      if (!hasPermission) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      _currentPosition = position;

      // Get address from coordinates
      await getAddressFromLatLng(position);
    } catch (e) {
      print('Error getting current location: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> getAddressFromLatLng(Position position) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);
      Placemark place = placemarks[0];

      // Format the address in a readable way
      final shortAddress = '${place.street}, ${place.subLocality}';
      _currentAddress = shortAddress;

      // Full address for detailed use
      _fullAddress =
          '${place.street}, ${place.subLocality}, ${place.locality}, ${place.postalCode}, ${place.country}';

      // Save the address
      await _saveAddress(shortAddress, isFullAddress: true);

      notifyListeners();
    } catch (e) {
      print('Error getting address: $e');
    }
  }

  // Update the current address manually
  Future<void> updateAddress(String address, {String? fullAddress}) async {
    _currentAddress = address;
    if (fullAddress != null) {
      _fullAddress = fullAddress;
    }
    await _saveAddress(address, isFullAddress: fullAddress != null);
    notifyListeners();
  }
}
