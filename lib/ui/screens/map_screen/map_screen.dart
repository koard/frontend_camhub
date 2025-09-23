import 'package:flutter/material.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart' as nav;
import 'package:permission_handler/permission_handler.dart';
import 'package:campusapp/models/faculty_destination.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

enum MapMode { map, navigating }

class _MapScreenState extends State<MapScreen> {
  // Controllers
  nav.GoogleNavigationViewController? _navController; // when in navigation mode
  nav.GoogleMapViewController? _mapViewController; // controller for map (explore) mode

  // State
  bool _sessionInitialized = false;
  MapMode _mode = MapMode.map; // current UI mode
  Position? _currentPosition;
  nav.CameraPosition? _initialCamera; // camera for nav map view
  // Marker handling (navigation SDK markers, not google_maps_flutter)
  final List<nav.Marker> _markers = <nav.Marker>[];
  final Map<String, FacultyDestination> _markerIdToFaculty = {};

  // Navigation info subscription
  StreamSubscription<nav.NavInfoEvent>? _navInfoSub;
  nav.NavInfo? _navInfo;

  // Faculty list & selected destination (future expandable)
  // In future, fetch from backend or cached repository service.
  final List<FacultyDestination> _faculties = facultyDestinationsSeed;
  FacultyDestination? _selectedFaculty; // user choice in map mode

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
    if (!await nav.GoogleMapsNavigator.areTermsAccepted()) {
      await nav.GoogleMapsNavigator.showTermsAndConditionsDialog(
        'Campus Hub',
        'PSU',
      );
    }
    await nav.GoogleMapsNavigator.initializeNavigationSession(
      taskRemovedBehavior: nav.TaskRemovedBehavior.continueService,
    );
    if (_currentPosition != null) {
      _initialCamera = nav.CameraPosition(
        target: nav.LatLng(latitude: _currentPosition!.latitude, longitude: _currentPosition!.longitude),
        zoom: 16,
      );
    } else {
      _initialCamera = const nav.CameraPosition(
        target: nav.LatLng(latitude: 7.006000, longitude: 100.498000),
        zoom: 15,
      );
    }
    setState(() => _sessionInitialized = true);
    // No markers (removed google_maps_flutter). Could add overlay later.
  }

  // Start navigation to destination
  Future<void> _startNavigation({bool simulate = true}) async {
    if (!_sessionInitialized) return;
    if (_mode == MapMode.navigating) return;

    // fall back to default engineering faculty if nothing selected yet
    final targetFaculty = _selectedFaculty ?? _faculties.first;

    // Optionally simulate starting user location if we still don't have one
    if (_currentPosition == null && simulate) {
  await nav.GoogleMapsNavigator.simulator.setUserLocation(const nav.LatLng(latitude: 7.006000, longitude: 100.498000));
    }

    // Set destinations (single waypoint)
    final destinations = nav.Destinations(
      waypoints: <nav.NavigationWaypoint>[
        nav.NavigationWaypoint.withLatLngTarget(
          title: targetFaculty.nameTh,
          target: targetFaculty.coordinate,
        ),
      ],
      displayOptions: nav.NavigationDisplayOptions(showDestinationMarkers: true),
    );

    final status = await nav.GoogleMapsNavigator.setDestinations(destinations);
    if (status == nav.NavigationRouteStatus.statusOk) {
      await _setupNavListeners();
      await nav.GoogleMapsNavigator.startGuidance();
      if (simulate) {
        await nav.GoogleMapsNavigator.simulator.simulateLocationsAlongExistingRoute();
      }
      await _navController?.followMyLocation(nav.CameraPerspective.tilted);
      setState(() => _mode = MapMode.navigating);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ไม่สามารถเริ่มนำทางได้')));
      }
    }
  }

  Future<void> _setupNavListeners() async {
    _clearNavListeners();
  _navInfoSub = nav.GoogleMapsNavigator.setNavInfoListener(
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
    if (_mode == MapMode.navigating) {
      await nav.GoogleMapsNavigator.cleanup();
      setState(() => _mode = MapMode.map);
      // Re-init session to allow future nav without rebuilding widget
      await nav.GoogleMapsNavigator.initializeNavigationSession(taskRemovedBehavior: nav.TaskRemovedBehavior.continueService);
    }
  }

  void _clearNavListeners() {
    _navInfoSub?.cancel();
    _navInfoSub = null;
  }

  void _onNavigationViewCreated(nav.GoogleNavigationViewController controller) {
    _navController = controller;
    controller.setMyLocationEnabled(true);
  }

  // Marker logic removed (using only navigation SDK map view in map mode)
  void _onMapModeViewCreated(nav.GoogleMapViewController controller) async {
    _mapViewController = controller;
    await controller.setMyLocationEnabled(true);
    // Add markers once (if not already)
    if (_markers.isEmpty) {
      await _addFacultyMarkers();
    }
  }

  Future<void> _addFacultyMarkers() async {
    if (_mapViewController == null) return;
    final List<nav.MarkerOptions> optionsList = _faculties.map((f) {
      final markerId = 'faculty_${f.id}';
      _markerIdToFaculty[markerId] = f;
      return nav.MarkerOptions(
        position: f.coordinate,
        infoWindow: nav.InfoWindow(title: f.nameTh, snippet: f.nameEn ?? ''),
        visible: true,
        draggable: false,
      );
    }).toList();
    final added = await _mapViewController!.addMarkers(optionsList);
    _markers.clear();
    for (final m in added) {
      if (m != null) _markers.add(m);
    }
    setState(() {});
  }

  void _onMarkerClicked(String markerId) {
    final faculty = _markerIdToFaculty[markerId];
    if (faculty != null) {
      setState(() => _selectedFaculty = faculty);
    }
  }

  @override
  void dispose() {
    _clearNavListeners();
    if (_mode == MapMode.navigating || _sessionInitialized) {
      nav.GoogleMapsNavigator.cleanup();
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
    final bool showNavigationView = _mode == MapMode.navigating; // switch view when nav starts
    return Scaffold(
      appBar: AppBar(title: const Text('แผนที่ & นำทาง')),
      body: !_sessionInitialized || _initialCamera == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (showNavigationView)
                  Expanded(
                    child: nav.GoogleMapsNavigationView(
                      onViewCreated: _onNavigationViewCreated,
                      initialNavigationUIEnabledPreference: nav.NavigationUIEnabledPreference.disabled,
                    ),
                  )
                else
                  Expanded(
                    child: Stack(
                      children: [
                        nav.GoogleMapsMapView(
                          onViewCreated: _onMapModeViewCreated,
                          onMarkerClicked: _onMarkerClicked,
                          initialCameraPosition: _initialCamera!,
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: _buildDestinationSelectorBar(),
                        ),
                      ],
                    ),
                  ),
                _buildInfoBar(),
              ],
            ),
      floatingActionButton: !_sessionInitialized
          ? null
          : (_mode != MapMode.navigating
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

  /// Bottom selector bar shown only in map mode for choosing a faculty.
  /// Currently we only have one seed faculty but UI is built to scale.
  Widget _buildDestinationSelectorBar() {
    // Only show in map mode
    if (_mode != MapMode.map) return const SizedBox.shrink();
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.school, color: Colors.blueAccent),
                const SizedBox(width: 8),
                const Text(
                  'เลือกปลายทาง (ทดลอง)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _faculties.map((f) {
                  final bool selected = (_selectedFaculty?.id ?? _faculties.first.id) == f.id;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(f.nameTh),
                      selected: selected,
                      onSelected: (_) {
                        setState(() => _selectedFaculty = f);
                      },
                      selectedColor: Colors.blueAccent,
                      labelStyle: TextStyle(color: selected ? Colors.white : Colors.black87),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _selectedFaculty?.nameEn ?? _faculties.first.nameEn ?? '',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            // Future: show distance from current location to selected faculty, markers, tap map to change.
            // Future: convert to DraggableScrollableSheet listing all faculties with search.
          ],
        ),
      ),
    );
  }
}
