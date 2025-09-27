import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:campusapp/ui/service/event_service.dart';
import 'package:campusapp/ui/screens/events_screen/event_detail_screen.dart';

class DeepLinkHandler {
  DeepLinkHandler({required this.navigatorKey});

  final GlobalKey<NavigatorState> navigatorKey;
  final AppLinks _appLinks = AppLinks();

  StreamSubscription<Uri>? _sub;
  Uri? _lastUri;
  DateTime? _lastHandledAt;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    _sub = _appLinks.uriLinkStream.listen(
      (uri) => _onUri(uri),
      onError: (_) {},
    );
  }

  void _onUri(Uri uri) {
    if (!_shouldHandle(uri)) return;
    _lastUri = uri;
    _lastHandledAt = DateTime.now();
    _handleUri(uri);
  }

  bool _shouldHandle(Uri uri) {
    if (uri.scheme != 'campusapp') return false;
    if (uri.host != 'event') return false;

    // Dedupe quick repeats
    final same = _lastUri?.toString() == uri.toString();
    final recent = _lastHandledAt != null &&
        DateTime.now().difference(_lastHandledAt!) < const Duration(seconds: 1);
    if (same && recent) return false;
    return true;
  }

  Future<void> _handleUri(Uri uri) async {
    final idStr = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
    final eventId = int.tryParse(idStr ?? '');
    if (eventId == null) return;
    try {
      final data = await EventService.fetchPublicById(eventId);
      final route = MaterialPageRoute(
        builder: (_) => EventDetailScreen(event: data ?? {'id': eventId}),
      );
      navigatorKey.currentState?.push(route);
    } catch (e) {
      final ctx = navigatorKey.currentContext;
      if (ctx != null) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text('เปิดกิจกรรมไม่สำเร็จ: $e')),
        );
      }
    }
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
  }
}
