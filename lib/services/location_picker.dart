import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LocationPicker extends StatefulWidget {
  final Function(double latitude, double longitude, String address)
      onLocationSelected;

  const LocationPicker({
    Key? key,
    required this.onLocationSelected,
  }) : super(key: key);

  // Fallback location picker method in case the map fails to load
  static Future<void> showFallbackLocationDialog(
      BuildContext context,
      Function(double latitude, double longitude, String address)
          onLocationSelected) async {
    final TextEditingController addressController = TextEditingController();

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter Your Location'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    hintText: 'Enter your complete address',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Note: Map service is unavailable. Please enter your address manually.',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Confirm'),
              onPressed: () {
                // Using default coordinates for Lahore as fallback
                if (addressController.text.isNotEmpty) {
                  onLocationSelected(
                    31.5204, // Default latitude
                    74.3587, // Default longitude
                    addressController.text,
                  );
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  final MapController _mapController = MapController();
  LocationData? _currentLocation;
  final Location _locationService = Location();
  final TextEditingController _searchController = TextEditingController();
  List<Marker> _markers = [];
  String _selectedAddress = "";
  LatLng? _selectedLocation;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    print('LocationPicker: initState called');
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    print('LocationPicker: _getUserLocation called');
    setState(() {
      _isLoading = true;
    });

    try {
      final hasPermission = await _locationService.requestPermission();
      print('LocationPicker: Permission status: $hasPermission');
      if (hasPermission != PermissionStatus.granted) {
        // Default to Lahore if permission not granted
        print('LocationPicker: Permission not granted, using default location');
        _setDefaultLocation();
        return;
      }

      print('LocationPicker: Getting current location');
      final loc = await _locationService.getLocation();
      print(
          'LocationPicker: Location received: ${loc.latitude}, ${loc.longitude}');
      if (mounted) {
        setState(() {
          _currentLocation = loc;
          _selectedLocation = LatLng(loc.latitude!, loc.longitude!);
          _markers = [
            Marker(
              point: _selectedLocation!,
              width: 60,
              height: 60,
              builder: (_) => const Icon(Icons.person_pin_circle,
                  color: Colors.blue, size: 40),
            )
          ];
          _getAddressFromCoordinates(_selectedLocation!);
        });
      }
    } catch (e) {
      print('LocationPicker: Error getting location: $e');
      _setDefaultLocation();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _setDefaultLocation() {
    // Default to Lahore
    setState(() {
      _selectedLocation = LatLng(31.5204, 74.3587);
      _markers = [
        Marker(
          point: _selectedLocation!,
          width: 60,
          height: 60,
          builder: (_) =>
              const Icon(Icons.location_pin, color: Colors.red, size: 40),
        )
      ];
      _isLoading = false;
    });
  }

  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final url = Uri.parse(
          "https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=1");
      final response =
          await http.get(url, headers: {'User-Agent': 'KhidmatApp'});

      final data = json.decode(response.body);
      if (data.isNotEmpty) {
        final lat = double.parse(data[0]['lat']);
        final lon = double.parse(data[0]['lon']);
        final address = data[0]['display_name'] ?? query;

        if (mounted) {
          setState(() {
            _selectedLocation = LatLng(lat, lon);
            _selectedAddress = address;
            _markers = [
              Marker(
                point: _selectedLocation!,
                width: 60,
                height: 60,
                builder: (_) =>
                    const Icon(Icons.location_pin, color: Colors.red, size: 40),
              )
            ];
            _mapController.move(_selectedLocation!, 15);
          });
        }
      } else {
        // Show error message if location not found
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Location not found. Please try again.')),
        );
      }
    } catch (e) {
      print('Error searching location: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Error searching location. Please try again.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _getAddressFromCoordinates(LatLng point) async {
    final url = Uri.parse(
        "https://nominatim.openstreetmap.org/reverse?lat=${point.latitude}&lon=${point.longitude}&format=json");

    try {
      final response =
          await http.get(url, headers: {'User-Agent': 'KhidmatApp'});

      final data = json.decode(response.body);
      if (mounted) {
        setState(() {
          _selectedAddress = data['display_name'] ?? "Selected location";
        });
      }
    } catch (e) {
      print('Error getting address: $e');
      if (mounted) {
        setState(() {
          _selectedAddress = "Location selected";
        });
      }
    }
  }

  void _handleTap(TapPosition tapPosition, LatLng point) {
    setState(() {
      _selectedLocation = point;
      _markers = [
        Marker(
          point: point,
          width: 60,
          height: 60,
          builder: (_) =>
              const Icon(Icons.location_pin, color: Colors.red, size: 40),
        )
      ];
    });

    _getAddressFromCoordinates(point);
  }

  @override
  Widget build(BuildContext context) {
    print('LocationPicker: build method called');
    final initialPosition = _currentLocation != null
        ? LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!)
        : LatLng(31.5204, 74.3587); // Lahore as default

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Location'),
        backgroundColor: Colors.purple,
        elevation: 0,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              center: initialPosition,
              zoom: 13.0,
              onTap: _handleTap,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.khidmat.app',
              ),
              MarkerLayer(markers: _markers),
            ],
          ),
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "Search location...",
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () => _searchLocation(_searchController.text),
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.purple),
              ),
            ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_selectedAddress.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.3),
                          spreadRadius: 1,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      _selectedAddress,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                const SizedBox(height: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _selectedLocation == null
                      ? null
                      : () {
                          widget.onLocationSelected(
                            _selectedLocation!.latitude,
                            _selectedLocation!.longitude,
                            _selectedAddress,
                          );
                          Navigator.of(context).pop();
                        },
                  child: const Text(
                    'Confirm Location',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
