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
  nav.GoogleNavigationViewController? _navController;
  nav.GoogleMapViewController? _mapViewController;

  bool _sessionInitialized = false;
  MapMode _mode = MapMode.map;
  Position? _currentPosition;
  nav.CameraPosition? _initialCamera;
  final List<nav.Marker> _markers = <nav.Marker>[];
  // Markers & mapping
  //  _markerIdToFaculty: markerId (SDK) -> FacultyDestination
  //  _facultyIdToMarker: faculty.id -> marker (for showing its info window)
  final Map<String, FacultyDestination> _markerIdToFaculty = {};
  final Map<String, nav.Marker> _facultyIdToMarker = {};

  StreamSubscription<nav.NavInfoEvent>? _navInfoSub; // for camera follow
  DateTime? _lastFollowUpdate;

  final List<FacultyDestination> _faculties = facultyDestinationsSeed;
  FacultyDestination? _selectedFaculty;
  bool _simulateRoute = false; // simulate movement when starting navigation
  // Chip auto-scroll
  final ScrollController _chipsScrollController = ScrollController();
  final Map<String, GlobalKey> _chipKeys = {}; // faculty.id -> key for size/position

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
      if (_initialCamera == null) {
        setState(() {
          _initialCamera = nav.CameraPosition(
            target: nav.LatLng(latitude: pos.latitude, longitude: pos.longitude),
            zoom: 17,
          );
        });
      }
      _focusCameraOnCurrentLocation();
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
        zoom: 17,
      );
  }
    setState(() => _sessionInitialized = true);
  }

  // Start navigation to destination
  Future<void> _startNavigation({bool simulate = false}) async {
    if (!_sessionInitialized) return;
    if (_mode == MapMode.navigating) return;

  final targetFaculty = _selectedFaculty; // no default; user must choose

    if (_currentPosition == null) {
      await _getDeviceLocation();
    }
    if (_currentPosition == null || targetFaculty == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(targetFaculty == null ? 'กรุณาเลือกปลายทางก่อนเริ่มนำทาง' : 'ยังไม่ทราบตำแหน่งปัจจุบัน โปรดลองอีกครั้ง')),
        );
      }
      return;
    }

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
      _focusCameraOnCurrentLocation(follow: true);
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
        final now = DateTime.now();
        if (_mode == MapMode.navigating &&
            (_lastFollowUpdate == null || now.difference(_lastFollowUpdate!) > const Duration(milliseconds: 1500))) {
          _lastFollowUpdate = now;
          _navController?.followMyLocation(nav.CameraPerspective.tilted);
        }
      },
      numNextStepsToPreview: 10,
    );
  }

  Future<void> _stopNavigation() async {
    try {
      await nav.GoogleMapsNavigator.stopGuidance();
      // Optionally also clear route:
      // await nav.GoogleMapsNavigator.clearDestinations();
    } catch (_) {}
    _clearNavListeners();
    if (mounted) {
      setState(() => _mode = MapMode.map);
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

  void _onMapModeViewCreated(nav.GoogleMapViewController controller) async {
    _mapViewController = controller;
    await controller.setMyLocationEnabled(true);
    // Always (re)add markers when the map view is (re)created to keep ID mappings fresh
    await _addFacultyMarkers();
    _focusCameraOnCurrentLocation();
  }

  Future<void> _addFacultyMarkers() async {
    if (_mapViewController == null) return;
    // Clear local caches before adding new markers (old controller was disposed when switching views)
    _markers.clear();
    _markerIdToFaculty.clear();
    _facultyIdToMarker.clear();
    final List<nav.MarkerOptions> optionsList = _faculties.map((f) {
      return nav.MarkerOptions(
        position: f.coordinate,
        infoWindow: nav.InfoWindow(title: f.nameTh, snippet: f.nameEn ?? ''),
        visible: true,
        draggable: false,
      );
    }).toList();
    final added = await _mapViewController!.addMarkers(optionsList);
    for (int i = 0; i < added.length; i++) {
      final m = added[i];
      if (m == null) continue;
      _markers.add(m);
      final id = _extractMarkerId(m);
      if (id != null) _markerIdToFaculty[id] = _faculties[i];
      _facultyIdToMarker[_faculties[i].id] = m;
    }
    setState(() {});
  }

  String? _extractMarkerId(nav.Marker m) {
    try {
      final dyn = m as dynamic;
      final List<dynamic> candidates = [];
      try {
        final v = dyn.id;
        if (v != null) candidates.add(v);
      } catch (_) {}
      try {
        final v = dyn.markerId;
        if (v != null) candidates.add(v);
        try {
          final inner = dyn.markerId?.value;
          if (inner != null) candidates.add(inner);
        } catch (_) {}
      } catch (_) {}
      if (candidates.isEmpty) return null;
      return candidates.first.toString();
    } catch (_) {
      return null;
    }
  }

  /// Animate or move camera to current device location (if available).
  Future<void> _focusCameraOnCurrentLocation({bool follow = false}) async {
    if (_currentPosition == null) return;
    final pos = nav.LatLng(
        latitude: _currentPosition!.latitude, longitude: _currentPosition!.longitude);
    final cam = nav.CameraUpdate.newCameraPosition(nav.CameraPosition(target: pos, zoom: 17));
    try {
      if (_mode == MapMode.navigating && _navController != null) {
        await _navController!.animateCamera(cam);
        if (follow) {
          await _navController!.followMyLocation(nav.CameraPerspective.tilted);
        }
      } else if (_mapViewController != null) {
        await _mapViewController!.animateCamera(cam);
      }
    } catch (_) {}
  }

  /// Marker tapped -> select faculty & focus camera
  void _onMarkerClicked(String markerId) {
    final faculty = _markerIdToFaculty[markerId];
    if (faculty == null) return; // No mapping (should not normally happen)
    if (_selectedFaculty?.id == faculty.id) {
      // Already selected; still show info window again for user feedback.
      _focusCameraOnFaculty(faculty);
      _scrollSelectedChipIntoView();
      return;
    }
    setState(() => _selectedFaculty = faculty);
    _focusCameraOnFaculty(faculty);
    _scrollSelectedChipIntoView();
  }

  Future<void> _focusCameraOnFaculty(FacultyDestination f) async {
    if (_mapViewController == null) return;
    final update = nav.CameraUpdate.newCameraPosition(
      nav.CameraPosition(target: f.coordinate, zoom: 17),
    );
    try {
      await _mapViewController!.animateCamera(update);
      final marker = _facultyIdToMarker[f.id];
      if (marker != null) {
        try {
          final dyn = marker as dynamic;
          await dyn.showInfoWindow();
        } catch (_) {}
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _clearNavListeners();
    if (_mode == MapMode.navigating || _sessionInitialized) {
      nav.GoogleMapsNavigator.cleanup();
    }
    _chipsScrollController.dispose();
    super.dispose();
  }

  // Removed legacy custom navigation bar & helpers; using built-in Google UI.

  @override
  Widget build(BuildContext context) {
    final bool showNavigationView = _mode == MapMode.navigating; // switch view when nav starts
    return Scaffold(
      appBar: AppBar(
        title: const Text('แผนที่'),
      ),
      body: !_sessionInitialized || _initialCamera == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (showNavigationView)
                  Expanded(
                    child: Stack(
                      children: [
                        nav.GoogleMapsNavigationView(
                          onViewCreated: _onNavigationViewCreated,
                        ),
                        Positioned(
                          right: 12,
                          bottom: 12,
                          child: _buildStopNavButton(),
                        ),
                      ],
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
              ],
            ),
      floatingActionButton: null,
    );
  }

  /// Floating stop navigation pill (blends with dark nav UI)
  Widget _buildStopNavButton() {
    return SafeArea(
      top: false,
      child: GestureDetector(
        onTap: _stopNavigation,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.55),
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: Colors.white.withOpacity(0.12), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 14,
                height: 14,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.red.shade600,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.6),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              const Text(
                'หยุดนำทาง',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
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
                const Expanded(
                  child: Text(
                    'เลือกปลายทาง',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                _buildSimToggle(),
                ElevatedButton.icon(
                  onPressed: _sessionInitialized && _selectedFaculty != null
                      ? () => _startNavigation(simulate: _simulateRoute)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.navigation, size: 18),
                  label: const Text('เริ่มนำทาง'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              controller: _chipsScrollController,
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _faculties.asMap().entries.map((entry) {
                  final f = entry.value;
                  final bool selected = _selectedFaculty?.id == f.id;
                  final key = _chipKeys.putIfAbsent(f.id, () => GlobalKey());
                  return Padding(
                    key: key,
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(f.nameTh),
                      selected: selected,
                      onSelected: (_) {
                        setState(() => _selectedFaculty = f);
                        _focusCameraOnFaculty(f);
                        _scrollSelectedChipIntoView();
                      },
                      selectedColor: Colors.blueAccent,
                      labelStyle: TextStyle(color: selected ? Colors.white : Colors.black87),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Ensure currently selected chip is visible (tries to center it if possible)
  void _scrollSelectedChipIntoView() {
    if (!_chipsScrollController.hasClients) return;
    final selected = _selectedFaculty;
    if (selected == null) return;
    final key = _chipKeys[selected.id];
    if (key == null) return;
    // Use postFrame to ensure layout complete before measuring
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = key.currentContext;
      if (ctx == null || !_chipsScrollController.hasClients) return;
      final box = ctx.findRenderObject() as RenderBox?;
      if (box == null) return;
      final position = box.localToGlobal(Offset.zero);
      final size = box.size;
      // Get list viewport bounds
      final listPosition = (_chipsScrollController.position.context.storageContext.findRenderObject()) as RenderBox?;
      if (listPosition == null) return;
      final listLeft = listPosition.localToGlobal(Offset.zero).dx;
      final listRight = listLeft + listPosition.size.width;
      final chipLeft = position.dx;
      final chipRight = chipLeft + size.width;
      double targetOffset = _chipsScrollController.offset;
      const edgePadding = 24.0; // comfortable margin
      // If chip out of left bound
      if (chipLeft < listLeft + edgePadding) {
        targetOffset -= (listLeft + edgePadding - chipLeft);
      } else if (chipRight > listRight - edgePadding) {
        targetOffset += (chipRight - (listRight - edgePadding));
      } else {
        return; // already fully visible
      }
      targetOffset = targetOffset.clamp(
        0,
        _chipsScrollController.position.maxScrollExtent,
      );
      _chipsScrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Widget _buildSimToggle() {
    return GestureDetector(
      onTap: () => setState(() => _simulateRoute = !_simulateRoute),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: _simulateRoute ? Colors.orange.shade600 : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(20),
          boxShadow: _simulateRoute
              ? [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _simulateRoute ? Icons.play_circle_fill : Icons.play_circle_outline,
              size: 18,
              color: _simulateRoute ? Colors.white : Colors.black87,
            ),
            const SizedBox(width: 4),
            Text(
              'Sim',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _simulateRoute ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(width: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 26,
              height: 14,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: _simulateRoute ? Colors.white.withOpacity(0.9) : Colors.black.withOpacity(0.25),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: _simulateRoute ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: _simulateRoute ? Colors.orange.shade700 : Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
