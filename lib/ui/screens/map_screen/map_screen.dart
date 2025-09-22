import 'package:flutter/material.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapViewController? _controller;
  bool _sessionInitialized = false;
  Position? _currentPosition;
  CameraPosition? _initialCamera;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  Future<void> _prepare() async {
    await _requestPermissions();
    await _getDeviceLocation();
    await _initializeSession();
  }

  Future<void> _requestPermissions() async {
    // Use permission_handler for coarse/fine location (Android) and WhenInUse location (iOS) at runtime.
    final status = await Permission.location.request();
    if (status.isDenied || status.isPermanentlyDenied) {
      // Show simple dialog to inform user.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ต้องเปิดสิทธิ์การเข้าถึงตำแหน่งเพื่อใช้งานแผนที่')),
        );
      }
    }
  }

  Future<void> _getDeviceLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
    }
    final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() => _currentPosition = pos);
  }

  Future<void> _initializeSession() async {
    if (!await GoogleMapsNavigator.areTermsAccepted()) {
      await GoogleMapsNavigator.showTermsAndConditionsDialog(
        'Campus Hub',
        'PSU',
      );
    }
    await GoogleMapsNavigator.initializeNavigationSession(
      taskRemovedBehavior: TaskRemovedBehavior.continueService,
    );
    if (_currentPosition != null) {
      _initialCamera = CameraPosition(
        target: LatLng(latitude: _currentPosition!.latitude, longitude: _currentPosition!.longitude),
        zoom: 16,
      );
    }
    setState(() => _sessionInitialized = true);
  }

  void _onMapViewCreated(GoogleMapViewController controller) {
    _controller = controller;
    _controller?.setMyLocationEnabled(true);
  }

  @override
  void dispose() {
    if (_sessionInitialized) {
      GoogleMapsNavigator.cleanup();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('แผนที่ (Google Navigation SDK)')),
      body: !_sessionInitialized || _initialCamera == null
          ? const Center(child: CircularProgressIndicator())
      : GoogleMapsMapView(
        onViewCreated: _onMapViewCreated,
              initialCameraPosition: _initialCamera!,
            ),
      floatingActionButton: (_controller != null)
          ? FloatingActionButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('ตัวอย่าง map view – ยังไม่เริ่มนำทาง'),
                  ),
                );
              },
              child: const Icon(Icons.navigation),
            )
          : null,
    );
  }
}
