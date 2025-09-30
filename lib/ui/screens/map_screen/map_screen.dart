import 'package:flutter/material.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart' as nav;
import 'package:permission_handler/permission_handler.dart';
import 'package:campusapp/models/place_destination.dart';
import 'package:campusapp/models/location.dart' as model;
import 'package:campusapp/ui/service/location_service.dart';

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
  //  _markerIdToPlace: markerId (SDK) -> PlaceDestination (generic place)
  //  _placeIdToMarker: place.id -> marker (for showing its info window)
  final Map<String, PlaceDestination> _markerIdToPlace = {};
  final Map<String, nav.Marker> _placeIdToMarker = {};

  StreamSubscription<nav.NavInfoEvent>? _navInfoSub; // for camera follow
  DateTime? _lastFollowUpdate;

  List<PlaceDestination> _places = [];
  List<PlaceDestination> _filteredPlaces = [];
  PlaceDestination? _selectedPlace;
  bool _descExpanded = false;
  bool _loadingLocations = false;
  String? _locationsError;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  // Pending deep-link/route search
  String? _pendingQuery;
  bool _pendingAutoSelectFirst = false;
  String? _pendingExactName;
  String? _pendingPlaceId;
  String? _pendingPlaceCode;
  bool _initialSearchApplied = false;
  // Chip auto-scroll
  final ScrollController _chipsScrollController = ScrollController();
  final Map<String, GlobalKey> _chipKeys = {}; // faculty.id -> key for size/position

  @override
  void initState() {
    super.initState();
    _prepare();
    // Read route args after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic>) {
        final q = (args['query'] as String?)?.trim();
        _pendingExactName = (args['exactName'] as String?)?.trim();
        _pendingPlaceId = (args['placeId'] as String?)?.trim();
        _pendingPlaceCode = (args['placeCode'] as String?)?.trim();
        if (q != null && q.isNotEmpty) {
          _pendingQuery = q;
          _pendingAutoSelectFirst = args['autoSelectFirst'] == true;
          setState(() {
            _searchQuery = q;
            _searchController.text = q;
            _applyFilter();
          });
          _attemptApplyPendingSearch();
        } else {
          // Even without a query, try to apply pending exact selection if provided
          _pendingAutoSelectFirst = args['autoSelectFirst'] == true;
          _attemptApplyPendingSearch();
        }
      }
    });
  }

  Future<void> _prepare() async {
    await _requestPermissions();
    await _getDeviceLocation();
    await _loadLocations();
    await _initializeSession();
  }

  Future<void> _loadLocations() async {
    setState(() {
      _loadingLocations = true;
      _locationsError = null;
    });
    try {
      final items = await LocationService.fetchAll();
      _places = items
          .map((model.Location l) => PlaceDestination(
                id: l.id.toString(),
                nameTh: l.name,
                nameEn: (l.description?.isNotEmpty == true)
                    ? l.description
                    : (l.code.isNotEmpty ? l.code : null),
                code: (l.code.isNotEmpty ? l.code : null),
                description: l.description,
                coordinate: nav.LatLng(
                  latitude: l.latitude ?? 0,
                  longitude: l.longitude ?? 0,
                ),
              ))
          .where((f) => !(f.coordinate.latitude == 0 && f.coordinate.longitude == 0))
          .toList();
      _applyFilter();
      // Do not auto-select any place on initial load
      // If map view is active, refresh markers to reflect new places
      if (_mapViewController != null) {
        await _addPlaceMarkers();
      }
      _attemptApplyPendingSearch();
    } catch (e) {
      _locationsError = e.toString();
      _places = [];
    } finally {
      if (mounted) setState(() => _loadingLocations = false);
    }
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
  Future<void> _startNavigation() async {
    if (!_sessionInitialized) return;
    if (_mode == MapMode.navigating) return;

  final targetFaculty = _selectedPlace; // no default; user must choose

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
    await _addPlaceMarkers();
    _focusCameraOnCurrentLocation();
    _attemptApplyPendingSearch();
  }

  Future<void> _addPlaceMarkers() async {
    if (_mapViewController == null) return;
    // Clear local caches before adding new markers (old controller was disposed when switching views)
    _markers.clear();
    _markerIdToPlace.clear();
    _placeIdToMarker.clear();
    final List<nav.MarkerOptions> optionsList = _places.map((f) {
      return nav.MarkerOptions(
        position: f.coordinate,
        infoWindow: nav.InfoWindow(
          title: f.nameTh,
          snippet: (f.code ?? f.nameEn ?? ''),
        ),
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
      if (id != null) _markerIdToPlace[id] = _places[i];
      _placeIdToMarker[_places[i].id] = m;
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
    final faculty = _markerIdToPlace[markerId];
    if (faculty == null) return; // No mapping (should not normally happen)
    if (_selectedPlace?.id == faculty.id) {
      // Already selected; still show info window again for user feedback.
      _focusCameraOnFaculty(faculty);
      _scrollSelectedChipIntoView();
      return;
    }
    setState(() {
      _selectedPlace = faculty;
      _descExpanded = false; // reset expand state on new selection
    });
    _focusCameraOnFaculty(faculty);
    _scrollSelectedChipIntoView();
  }

  Future<void> _focusCameraOnFaculty(PlaceDestination f) async {
    if (_mapViewController == null) return;
    final update = nav.CameraUpdate.newCameraPosition(
      nav.CameraPosition(target: f.coordinate, zoom: 17),
    );
    try {
      await _mapViewController!.animateCamera(update);
      final marker = _placeIdToMarker[f.id];
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
    _searchController.dispose();
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
                        // Top overlay: search bar + results list (iOS style)
                        Positioned(
                          left: 0,
                          right: 0,
                          top: 0,
                          child: SafeArea(
                            bottom: false,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildCupertinoSearchBar(),
                                  if (_locationsError != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: _buildErrorBanner(),
                                    ),
                                  if (_searchQuery.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: _buildSearchResultsCard(),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Bottom overlay: selected place detail card
                        if (_mode == MapMode.map && _selectedPlace != null && _searchQuery.isEmpty)
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: _buildSelectedPlaceCard(),
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
            color: Colors.black.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
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
                      color: Colors.red.withValues(alpha: 0.6),
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

  /// Top iOS-style search bar
  Widget _buildCupertinoSearchBar() {
    final bool loading = _loadingLocations;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'ค้นหาสถานที่',
              ),
              textInputAction: TextInputAction.search,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.trim();
                  _applyFilter();
                });
              },
              onSubmitted: (_) {
                // keep results open; user can tap an item
              },
            ),
          ),
          if (loading)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else if (_searchQuery.isNotEmpty)
            IconButton(
              tooltip: 'ล้าง',
              icon: const Icon(Icons.close, size: 18),
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                  _searchController.clear();
                  _applyFilter();
                  FocusScope.of(context).unfocus();
                });
              },
            )
          else
            IconButton(
              tooltip: 'โหลดใหม่',
              icon: const Icon(Icons.refresh),
              onPressed: _loadLocations,
            ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      decoration: BoxDecoration(
  color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.orange, size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'โหลดตำแหน่งจากเซิร์ฟเวอร์ไม่สำเร็จ: $_locationsError',
              style: const TextStyle(color: Colors.orange, fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton(
            onPressed: _loadLocations,
            child: const Text('ลองใหม่', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResultsCard() {
    final results = _filteredPlaces;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      constraints: const BoxConstraints(maxHeight: 260),
      child: results.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(12.0),
              child: Text('ไม่พบผลการค้นหา', style: TextStyle(color: Colors.grey)),
            )
          : ListView.separated(
              shrinkWrap: true,
              itemCount: results.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final p = results[index];
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.place_outlined),
                  title: Text(p.nameTh, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(p.code ?? p.nameEn ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                  onTap: () {
                    setState(() {
                      _selectedPlace = p;
                      _searchQuery = '';
                      _searchController.clear();
                    });
                    _focusCameraOnFaculty(p);
                    _scrollSelectedChipIntoView();
                    FocusScope.of(context).unfocus();
                  },
                );
              },
            ),
    );
  }

  Widget _buildSelectedPlaceCard() {
    final p = _selectedPlace!;
    final distanceText = _formatDistanceTo(p);
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.place, color: Colors.redAccent),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.nameTh,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        p.code ?? p.nameEn ?? '-',
                        style: const TextStyle(color: Colors.black54),
                      ),
                      if (distanceText != null) ...[
                        const SizedBox(height: 2),
                        Text(distanceText, style: const TextStyle(color: Colors.black54, fontSize: 12)),
                      ],
                      if ((p.description ?? '').isNotEmpty) ...[
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => setState(() => _descExpanded = !_descExpanded),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('รายละเอียด', style: TextStyle(fontWeight: FontWeight.w600)),
                              Icon(_descExpanded ? Icons.expand_less : Icons.expand_more),
                            ],
                          ),
                        ),
                        AnimatedCrossFade(
                          crossFadeState: _descExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                          duration: const Duration(milliseconds: 200),
                          firstChild: Padding(
                            padding: const EdgeInsets.only(top: 6.0),
                            child: Text(
                              p.description!,
                              style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.25),
                            ),
                          ),
                          secondChild: Padding(
                            padding: const EdgeInsets.only(top: 6.0),
                            child: Text(
                              p.description!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.25),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'ปิด',
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => _selectedPlace = null),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _sessionInitialized ? _startNavigation : null,
                    icon: const Icon(Icons.navigation),
                    label: const Text('เริ่มนำทาง'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // sim toggle removed
              ],
            ),
          ],
        ),
      ),
    );
  }

  String? _formatDistanceTo(PlaceDestination p) {
    if (_currentPosition == null) return null;
    try {
      final d = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        p.coordinate.latitude,
        p.coordinate.longitude,
      );
      if (d.isNaN) return null;
      if (d < 1000) {
        return '${d.toStringAsFixed(0)} m';
      } else {
        return '${(d / 1000).toStringAsFixed(1)} km';
      }
    } catch (_) {
      return null;
    }
  }

  void _applyFilter() {
    if (_searchQuery.isEmpty) {
      _filteredPlaces = _places;
      return;
    }
    final q = _searchQuery.toLowerCase();
    _filteredPlaces = _places.where((p) {
      final nameTh = p.nameTh.toLowerCase();
      final nameEn = (p.nameEn ?? '').toLowerCase();
      final code = (p.code ?? '').toLowerCase();
      final desc = (p.description ?? '').toLowerCase();
      return nameTh.contains(q) || nameEn.contains(q) || code.contains(q) || desc.contains(q);
    }).toList();
  }

  /// Ensure currently selected chip is visible (tries to center it if possible)
  void _scrollSelectedChipIntoView() {
    if (!_chipsScrollController.hasClients) return;
    final selected = _selectedPlace;
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

  /// Apply pending search passed via route arguments: set first match selected and focus.
  void _attemptApplyPendingSearch() async {
    if (_initialSearchApplied) return;
    if (_mapViewController == null) return; // Needs map controller
    if (_places.isEmpty) return; // Needs data
    // 1) Direct select by placeId
    if (_pendingPlaceId != null && _pendingPlaceId!.isNotEmpty) {
      final p = _places.firstWhere(
        (e) => e.id == _pendingPlaceId,
        orElse: () => _places.first,
      );
      setState(() {
        _selectedPlace = p;
        _descExpanded = false;
        _searchQuery = '';
        _searchController.text = '';
        _applyFilter();
      });
      await _focusCameraOnFaculty(p);
      _scrollSelectedChipIntoView();
      _initialSearchApplied = true;
      return;
    }
    // 2) Direct select by placeCode (exact match, case-insensitive)
    if (_pendingPlaceCode != null && _pendingPlaceCode!.isNotEmpty) {
      final code = _pendingPlaceCode!.toLowerCase();
      final match = _places.firstWhere(
        (e) => (e.code ?? '').toLowerCase() == code,
        orElse: () => _places.first,
      );
      setState(() {
        _selectedPlace = match;
        _descExpanded = false;
        _searchQuery = '';
        _searchController.text = '';
        _applyFilter();
      });
      await _focusCameraOnFaculty(match);
      _scrollSelectedChipIntoView();
      _initialSearchApplied = true;
      return;
    }
    // 3) Direct select by exactName (TH/EN), case-insensitive
    if (_pendingExactName != null && _pendingExactName!.isNotEmpty) {
      final n = _pendingExactName!.toLowerCase();
      final candidates = _places.where((e) =>
          e.nameTh.toLowerCase() == n || (e.nameEn ?? '').toLowerCase() == n);
      if (candidates.isNotEmpty) {
        final p = candidates.first;
        setState(() {
          _selectedPlace = p;
          _descExpanded = false;
          _searchQuery = '';
          _searchController.text = '';
          _applyFilter();
        });
        await _focusCameraOnFaculty(p);
        _scrollSelectedChipIntoView();
        _initialSearchApplied = true;
        return;
      }
    }
    // 4) Fallback: use query filter and auto-select first result
    if (_pendingQuery == null) return;
    if (_filteredPlaces.isEmpty) return; // No match
    if (!_pendingAutoSelectFirst) return;
    final p = _filteredPlaces.first;
    setState(() {
      _selectedPlace = p;
      _descExpanded = false;
      // Clear search to show the selected place card with the navigation button
      _searchQuery = '';
      _searchController.text = '';
      _applyFilter();
    });
    await _focusCameraOnFaculty(p);
    _scrollSelectedChipIntoView();
    _initialSearchApplied = true;
  }
}
