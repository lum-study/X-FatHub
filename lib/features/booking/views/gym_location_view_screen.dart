import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geocoding/geocoding.dart';

class GymLocationViewScreen extends StatefulWidget {
  final String gymName;
  final String? gymAddress;
  final String? slotLocation;

  const GymLocationViewScreen({
    super.key,
    required this.gymName,
    this.gymAddress,
    this.slotLocation,
  });

  @override
  State<GymLocationViewScreen> createState() => _GymLocationViewScreenState();
}

class _GymLocationViewScreenState extends State<GymLocationViewScreen> {
  LatLng? _gymLocation;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _resolveLocation();
  }

  Future<void> _resolveLocation() async {
    try {
      final query = widget.gymAddress ?? widget.slotLocation;
      if (query == null || query.isEmpty) {
        setState(() {
          _errorMessage = "Address not available";
          _isLoading = false;
        });
        return;
      }

      final locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        setState(() {
          _gymLocation = LatLng(locations.first.latitude, locations.first.longitude);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = "Could not find location on map";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Error finding location";
        _isLoading = false;
      });
    }
  }

  Future<void> _openInGoogleMaps() async {
    if (_gymLocation == null) return;
    final url = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${_gymLocation!.latitude},${_gymLocation!.longitude}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openInWaze() async {
    if (_gymLocation == null) return;
    final url = Uri.parse(
        'https://waze.com/ul?ll=${_gymLocation!.latitude},${_gymLocation!.longitude}&navigate=yes');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Color(0xFFFFA500)),
        title: Text(
          widget.gymName,
          style: const TextStyle(color: Color(0xFFFFA500), fontSize: 18),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFA500)))
                : _errorMessage != null
                    ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.white)))
                    : FlutterMap(
                        options: MapOptions(
                          initialCenter: _gymLocation!,
                          initialZoom: 15.0,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.XFatHub',
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: _gymLocation!,
                                width: 50,
                                height: 50,
                                child: const Icon(
                                  Icons.location_on,
                                  color: Colors.red,
                                  size: 40,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFF111111),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.gymName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.gymAddress != null || widget.slotLocation != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    widget.gymAddress ?? widget.slotLocation!,
                    style: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 14),
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _gymLocation != null ? _openInGoogleMaps : null,
                        icon: const Icon(Icons.map),
                        label: const Text('Google Maps'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFA500),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _gymLocation != null ? _openInWaze : null,
                        icon: const Icon(Icons.directions_car),
                        label: const Text('Waze'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF333333),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
