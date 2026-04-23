import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  LatLng _center = const LatLng(3.1390, 101.6869); // Default KL
  LatLng? _selectedLocation;
  String _address = 'Tap map to pick a location';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchAddress(String query) async {
    if (query.trim().isEmpty) return;
    setState(() => _isLoading = true);
    FocusManager.instance.primaryFocus?.unfocus(); // hide keyboard
    try {
      List<Location> locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        final loc = locations.first;
        final latLng = LatLng(loc.latitude, loc.longitude);
        setState(() {
          _center = latLng;
          _selectedLocation = latLng;
          _address = 'Loading location name...';
          _isLoading = false;
        });
        _mapController.move(latLng, 15.0);
        await _getAddress(latLng);
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Address not found. Please try another search.')),
        );
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    
    if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
      try {
        final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        setState(() {
          _center = LatLng(position.latitude, position.longitude);
          _selectedLocation = _center;
          _isLoading = false;
        });
        _mapController.move(_center, 15.0);
        await _getAddress(_center);
      } catch (e) {
        setState(() => _isLoading = false);
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _getAddress(LatLng latLng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latLng.latitude, latLng.longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        setState(() {
          // Format the address nicely
          List<String> addressParts = [];
          if (p.street != null && p.street!.isNotEmpty) addressParts.add(p.street!);
          else if (p.name != null && p.name!.isNotEmpty) addressParts.add(p.name!);
          
          if (p.subLocality != null && p.subLocality!.isNotEmpty) addressParts.add(p.subLocality!);
          if (p.locality != null && p.locality!.isNotEmpty) addressParts.add(p.locality!);
          
          _address = addressParts.isNotEmpty 
              ? addressParts.join(', ') 
              : '${latLng.latitude.toStringAsFixed(4)}, ${latLng.longitude.toStringAsFixed(4)}';
        });
      } else {
        setState(() { 
          _address = '${latLng.latitude.toStringAsFixed(4)}, ${latLng.longitude.toStringAsFixed(4)}'; 
        });
      }
    } catch (e) {
      setState(() { 
        _address = '${latLng.latitude.toStringAsFixed(4)}, ${latLng.longitude.toStringAsFixed(4)}'; 
      });
    }
  }

  void _onMapTap(TapPosition tapPosition, LatLng latLng) async {
    setState(() {
      _selectedLocation = latLng;
      _address = 'Loading location name...';
    });
    await _getAddress(latLng);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Pick a Location', style: TextStyle(color: Colors.orange, fontSize: 16)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.orange),
        actions: [
          if (_selectedLocation != null)
            TextButton(
              onPressed: () {
                Navigator.pop(context, {
                  'name': _address,
                  'lat': _selectedLocation!.latitude,
                  'lng': _selectedLocation!.longitude,
                });
              },
              child: const Text('Confirm', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
            )
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 13.0,
              onTap: _onMapTap,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.XFatHub',
              ),
              if (_selectedLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedLocation!,
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.location_on, color: Colors.orange, size: 40),
                    )
                  ],
                )
            ],
          ),
          
          // Search Bar Overlay
          Positioned(
            top: 20, left: 20, right: 20,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF333333)),
                boxShadow: const [
                  BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 4)),
                ],
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search for a city or place...',
                  hintStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: const Icon(Icons.search, color: Colors.orange),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      FocusManager.instance.primaryFocus?.unfocus();
                    },
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                onSubmitted: _searchAddress,
              ),
            ),
          ),

          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: Colors.orange)),
          if (_selectedLocation != null)
             Positioned(
               bottom: 20, left: 20, right: 20,
               child: Container(
                 decoration: BoxDecoration(
                   color: const Color(0xFF1E1E1E),
                   borderRadius: BorderRadius.circular(12),
                   border: Border.all(color: const Color(0xFF2A2A2A)),
                 ),
                 padding: const EdgeInsets.all(16.0),
                 child: Row(
                   children: [
                     const Icon(Icons.location_on, color: Colors.orange),
                     const SizedBox(width: 12),
                     Expanded(
                       child: Text(
                         _address, 
                         style: const TextStyle(color: Colors.white, fontSize: 14),
                         maxLines: 2,
                         overflow: TextOverflow.ellipsis,
                       ),
                     ),
                   ],
                 ),
               )
             )
        ],
      )
    );
  }
}
