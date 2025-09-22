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
  // Controllers
  GoogleNavigationViewController? _navController; // when in navigation mode

  // State
  bool _sessionInitialized = false;
  bool _navigationRunning = false;
  Position? _currentPosition;
  CameraPosition? _initialCamera;

  // Navigation info subscription
  StreamSubscription<NavInfoEvent>? _navInfoSub;
  NavInfo? _navInfo;

  // Destination (Faculty of Engineering PSU Hat Yai) mock coordinates
  static const LatLng _destFacultyEng = LatLng(
    latitude: 7.005094, // approximate
    longitude: 100.495329, // approximate
  );

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
    try {
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() => _currentPosition = pos);
    } catch (_) {}
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
    } else {
      // fallback to campus center approx if location not ready yet
      _initialCamera = const CameraPosition(
        target: LatLng(latitude: 7.006000, longitude: 100.498000),
        zoom: 15,
      );
    }
    setState(() => _sessionInitialized = true);
  }

  // Start navigation to destination
  Future<void> _startNavigation({bool simulate = true}) async {
    if (!_sessionInitialized) return;
    if (_navigationRunning) return;

    // Optionally simulate starting user location if we still don't have one
    if (_currentPosition == null && simulate) {
      await GoogleMapsNavigator.simulator.setUserLocation(const LatLng(latitude: 7.006000, longitude: 100.498000));
    }

    // Set destinations (single waypoint)
    final destinations = Destinations(
      waypoints: <NavigationWaypoint>[
        NavigationWaypoint.withLatLngTarget(
          title: 'วิศวกรรมศาสตร์ ม.อ. หาดใหญ่',
          target: _destFacultyEng,
        ),
      ],
      displayOptions: NavigationDisplayOptions(showDestinationMarkers: true),
    );

    final status = await GoogleMapsNavigator.setDestinations(destinations);
    if (status == NavigationRouteStatus.statusOk) {
      await _setupNavListeners();
      await GoogleMapsNavigator.startGuidance();
      if (simulate) {
        await GoogleMapsNavigator.simulator.simulateLocationsAlongExistingRoute();
      }
      await _navController?.followMyLocation(CameraPerspective.tilted);
      setState(() => _navigationRunning = true);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ไม่สามารถเริ่มนำทางได้')));
      }
    }
  }

  Future<void> _setupNavListeners() async {
    _clearNavListeners();
    _navInfoSub = GoogleMapsNavigator.setNavInfoListener(
      (event) {
        if (!mounted) return;
        setState(() => _navInfo = event.navInfo);
      },
      numNextStepsToPreview: 25,
    );
  }

  Future<void> _stopNavigation() async {
    _clearNavListeners();
    _navInfo = null;
    if (_navigationRunning) {
      await GoogleMapsNavigator.cleanup();
      setState(() => _navigationRunning = false);
      // Re-init session to allow future nav without rebuilding widget
      await GoogleMapsNavigator.initializeNavigationSession(taskRemovedBehavior: TaskRemovedBehavior.continueService);
    }
  }

  void _clearNavListeners() {
    _navInfoSub?.cancel();
    _navInfoSub = null;
  }

  void _onMapViewCreated(GoogleMapViewController controller) {
    // Use map view controller to animate to destination before navigation.
    controller.setMyLocationEnabled(true);
  }

  void _onNavigationViewCreated(GoogleNavigationViewController controller) {
    _navController = controller;
    controller.setMyLocationEnabled(true);
  }

  @override
  void dispose() {
    _clearNavListeners();
    if (_navigationRunning || _sessionInitialized) {
      GoogleMapsNavigator.cleanup();
    }
    super.dispose();
  }

  Widget _buildInfoBar() {
    if (_navInfo == null) return const SizedBox.shrink();
    final nav = _navInfo!;
    return Container(
      width: double.infinity,
      color: Colors.green.shade700,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (nav.timeToFinalDestinationSeconds != null && nav.distanceToFinalDestinationMeters != null)
            Text(
              'ถึงปลายทางใน ~${_formatDuration(nav.timeToFinalDestinationSeconds!)} (${_formatDistance(nav.distanceToFinalDestinationMeters!)})',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          if (nav.currentStep != null)
            Text(
              'ขั้นต่อไป: ${nav.currentStep!.fullInstructions}',
              style: const TextStyle(color: Colors.white, fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final d = Duration(seconds: seconds);
    if (d.inHours > 0) {
      final h = d.inHours;
      final m = d.inMinutes.remainder(60);
      return '${h}ชม ${m}นาที';
    }
    if (d.inMinutes >= 1) {
      return '${d.inMinutes}นาที';
    }
    return '${d.inSeconds}วิ';
  }

  String _formatDistance(int meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} กม.';
    }
    return '$meters ม.';
  }

  @override
  Widget build(BuildContext context) {
    final bool showNavigationView = _navigationRunning; // switch view when nav starts
    return Scaffold(
      appBar: AppBar(title: const Text('แผนที่ & นำทาง')),
      body: !_sessionInitialized || _initialCamera == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (showNavigationView)
                  Expanded(
                    child: GoogleMapsNavigationView(
                      onViewCreated: _onNavigationViewCreated,
                      initialNavigationUIEnabledPreference: NavigationUIEnabledPreference.disabled,
                    ),
                  )
                else
                  Expanded(
                    child: GoogleMapsMapView(
                      onViewCreated: _onMapViewCreated,
                      initialCameraPosition: _initialCamera!,
                    ),
                  ),
                _buildInfoBar(),
              ],
            ),
      floatingActionButton: !_sessionInitialized
          ? null
          : (!_navigationRunning
              ? FloatingActionButton.extended(
                  onPressed: () => _startNavigation(simulate: true),
                  icon: const Icon(Icons.directions),
                  label: const Text('เริ่มนำทาง'),
                )
              : FloatingActionButton.extended(
                  backgroundColor: Colors.red,
                  onPressed: _stopNavigation,
                  icon: const Icon(Icons.stop),
                  label: const Text('หยุดนำทาง'),
                )),
    );
  }
}
