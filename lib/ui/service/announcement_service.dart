import 'package:campusapp/models/announcement.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:developer';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AnnouncementService {
  String get _baseUrl =>
      dotenv.env['API_BASE_URL']?.trim().replaceAll(RegExp(r"/+$"), '') ??
      'http://localhost:8000';

  /// Get access token from secure storage
  Future<String?> _getAccessToken() async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'access_token');
    log('[Announcement] Raw stored token: $token');

    if (token == null || token.isEmpty) {
      log('[Announcement] No token found');
      return null;
    }

    // Parse token (support both JSON and raw string)
    try {
      final decoded = jsonDecode(token);
      if (decoded is Map &&
          decoded['access_token'] is String &&
          (decoded['access_token'] as String).isNotEmpty) {
        return decoded['access_token'] as String;
      } else {
        return token; // fallback to raw string
      }
    } catch (_) {
      return token; // not JSON
    }
  }

  Future<List<Announcement>> getAnnouncements({
    int page = 1,
    int perPage = 10,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/annc/?page=$page&per_page=$perPage');
    log('[Announcement] Fetching from: $uri');

    try {
      final res = await http.get(uri, headers: {'accept': 'application/json'});
      log('[Announcement] Status: ${res.statusCode}');

      if (res.statusCode >= 200 && res.statusCode < 300) {
        if (res.body.isEmpty) {
          return <Announcement>[];
        }

        final decoded = jsonDecode(res.body);
        if (decoded is Map<String, dynamic> &&
            decoded['announcements'] is List) {
          final List<dynamic> jsonList = decoded['announcements'];
          final announcements =
              jsonList.map((json) => Announcement.fromJson(json)).toList();

          // Save to file for offline fallback
          await _persistLatestAnnouncementFile(announcements);

          return announcements;
        } else {
          log('[Announcement] Unexpected response structure');
          return <Announcement>[];
        }
      } else {
        log('[Announcement] Failed to fetch: ${res.statusCode}');
        return <Announcement>[];
      }
    } catch (e, st) {
      log('[Announcement] Exception: $e\n$st');
      return <Announcement>[];
    }
  }

  // ------------- File based offline backup -------------
  static const String _fileName = 'latest_announcements.json';

  Future<File?> _getAnnouncementFile() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      return File('${dir.path}/$_fileName');
    } catch (e) {
      log('[Announcement][File] Get file error: $e');
      return null;
    }
  }

  Future<void> _persistLatestAnnouncementFile(List<Announcement> data) async {
    try {
      final f = await _getAnnouncementFile();
      if (f == null) return;
      final jsonData = data.map((a) => a.toJson()).toList();
      await f.writeAsString(jsonEncode(jsonData), flush: true);
      log(
        '[Announcement][File] Saved announcement file (${data.length} items)',
      );
    } catch (e) {
      log('[Announcement][File] Save error: $e');
    }
  }

  Future<List<Announcement>> loadLatestAnnouncementFromFile() async {
    try {
      final f = await _getAnnouncementFile();
      if (f == null) return <Announcement>[];
      if (!await f.exists()) return <Announcement>[];
      final content = await f.readAsString();
      if (content.isEmpty) return <Announcement>[];
      final decoded = jsonDecode(content);
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
            .map((json) => Announcement.fromJson(json.cast<String, dynamic>()))
            .toList(growable: false);
      }
    } catch (e) {
      log('[Announcement][File] Load error: $e');
    }
    return <Announcement>[];
  }

  /// Fetch with file fallback (priority: network -> file -> empty)
  Future<List<Announcement>> getAnnouncementsWithFileFallback({
    int page = 1,
    int perPage = 10,
  }) async {
    final remote = await getAnnouncements(page: page, perPage: perPage);
    if (remote.isNotEmpty) return remote;
    final fileData = await loadLatestAnnouncementFromFile();
    if (fileData.isNotEmpty) {
      log(
        '[Announcement][File] Using file cached announcements (${fileData.length})',
      );
      return fileData;
    }
    return <Announcement>[];
  }

  /// Smart fetch with offline fallback - shows bookmarked announcements when offline
  Future<List<Announcement>> getAnnouncementsSmartOffline({
    int page = 1,
    int perPage = 10,
  }) async {
    final token = await _getAccessToken();

    // If we have a token, try to get online data first
    if (token != null) {
      try {
        final remote = await getAnnouncements(page: page, perPage: perPage);
        if (remote.isNotEmpty) {
          log(
            '[Announcement] Using online data (${remote.length} announcements)',
          );
          return remote;
        }
      } catch (e) {
        log('[Announcement] Online fetch failed: $e');
      }

      // If online data fetch failed but we have token, try fallback
      final fileData = await loadLatestAnnouncementFromFile();
      if (fileData.isNotEmpty) {
        log(
          '[Announcement][Online-Fallback] Using cached announcements (${fileData.length})',
        );
        return fileData;
      }
    }

    // If no token or online data failed, return bookmarked announcements only (like getBookmarkedAnnouncements)
    final bookmarkedData = await loadBookmarkCache();
    if (bookmarkedData.isNotEmpty) {
      log(
        '[Announcement][Offline] Using bookmarked announcements only (${bookmarkedData.length})',
      );
      return bookmarkedData;
    }

    // No bookmarks found - return empty instead of all cached announcements
    log('[Announcement][Offline] No bookmarked announcements found');
    return <Announcement>[];
  }

  /// Persist announcement data to file manually
  Future<void> persistAnnouncementToFile(List<Announcement> data) async {
    await _persistLatestAnnouncementFile(data);
  }

  /// Clear announcement cache file (call on logout)
  Future<void> clearAnnouncementFileCache() async {
    try {
      final f = await _getAnnouncementFile();
      if (f != null && await f.exists()) {
        await f.delete();
        log('[Announcement][File] Deleted announcement cache file');
      }
    } catch (e) {
      log('[Announcement][File] Delete error: $e');
    }
  }

  // ------------- Bookmark Cache File Management -------------

  /// Get bookmark cache file reference
  Future<File?> _getBookmarkCacheFile() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      return File('${dir.path}/cached_bookmarks.json');
    } catch (e) {
      log('[Bookmark][File] Get file error: $e');
      return null;
    }
  }

  /// Get bookmark IDs cache file reference
  Future<File?> _getBookmarkIdsCacheFile() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      return File('${dir.path}/cached_bookmark_ids.json');
    } catch (e) {
      log('[Bookmark][File] Get IDs file error: $e');
      return null;
    }
  }

  /// Save bookmarked announcements to local file
  Future<void> _persistBookmarkCache(List<Announcement> bookmarks) async {
    try {
      final f = await _getBookmarkCacheFile();
      if (f == null) return;

      final jsonData = bookmarks.map((a) => a.toJson()).toList();
      await f.writeAsString(jsonEncode(jsonData), flush: true);
      log('[Bookmark][File] Saved ${bookmarks.length} bookmarks to cache');
    } catch (e) {
      log('[Bookmark][File] Save error: $e');
    }
  }

  /// Load bookmarked announcements from local file
  Future<List<Announcement>> loadBookmarkCache() async {
    try {
      final f = await _getBookmarkCacheFile();
      if (f == null || !await f.exists()) return <Announcement>[];

      final content = await f.readAsString();
      if (content.isEmpty) return <Announcement>[];

      final decoded = jsonDecode(content);
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
            .map((json) => Announcement.fromJson(json.cast<String, dynamic>()))
            .toList(growable: false);
      }
    } catch (e) {
      log('[Bookmark][File] Load error: $e');
    }
    return <Announcement>[];
  }

  /// Save bookmark IDs to local file for quick access
  Future<void> _persistBookmarkIds(Set<int> ids) async {
    try {
      final f = await _getBookmarkIdsCacheFile();
      if (f == null) return;

      await f.writeAsString(jsonEncode(ids.toList()), flush: true);
      log('[Bookmark][File] Saved ${ids.length} bookmark IDs');
    } catch (e) {
      log('[Bookmark][File] Save IDs error: $e');
    }
  }

  /// Load bookmark IDs from local file
  Future<Set<int>> loadBookmarkIds() async {
    try {
      final f = await _getBookmarkIdsCacheFile();
      if (f == null || !await f.exists()) return <int>{};

      final content = await f.readAsString();
      if (content.isEmpty) return <int>{};

      final decoded = jsonDecode(content);
      if (decoded is List) {
        return decoded.whereType<int>().toSet();
      }
    } catch (e) {
      log('[Bookmark][File] Load IDs error: $e');
    }
    return <int>{};
  }

  /// Clear bookmark cache files (call on logout)
  Future<void> clearBookmarkCache() async {
    try {
      final bookmarkFile = await _getBookmarkCacheFile();
      if (bookmarkFile != null && await bookmarkFile.exists()) {
        await bookmarkFile.delete();
        log('[Bookmark][File] Deleted bookmark cache file');
      }

      final idsFile = await _getBookmarkIdsCacheFile();
      if (idsFile != null && await idsFile.exists()) {
        await idsFile.delete();
        log('[Bookmark][File] Deleted bookmark IDs cache file');
      }
    } catch (e) {
      log('[Bookmark][File] Clear cache error: $e');
    }
  }

  // ------------- Bookmark API Methods with Offline Support -------------

  /// Get bookmarked announcements with offline support
  Future<List<Announcement>> getBookmarkedAnnouncements({
    int page = 1,
    int perPage = 10,
  }) async {
    final token = await _getAccessToken();

    // If no token, return cached bookmarks for offline viewing
    if (token == null) {
      final cached = await loadBookmarkCache();
      log('[Bookmark] No token - returning ${cached.length} cached bookmarks');
      return cached;
    }

    final uri = Uri.parse(
      '$_baseUrl/api/annc/bookmarks/?page=$page&per_page=$perPage',
    );
    log('[Announcement] Fetching bookmarks from: $uri');

    try {
      final res = await http.get(
        uri,
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      log('[Announcement] Bookmark Status: ${res.statusCode}');

      if (res.statusCode >= 200 && res.statusCode < 300) {
        if (res.body.isEmpty) {
          await _persistBookmarkCache(<Announcement>[]);
          await _persistBookmarkIds(<int>{});
          return <Announcement>[];
        }

        final decoded = jsonDecode(res.body);
        List<Announcement> bookmarks = <Announcement>[];

        if (decoded is Map<String, dynamic>) {
          // Handle new pagination structure with bookmarks array
          if (decoded['bookmarks'] is List) {
            final List<dynamic> bookmarksList = decoded['bookmarks'];
            bookmarks =
                bookmarksList
                    .where(
                      (bookmark) =>
                          bookmark is Map<String, dynamic> &&
                          bookmark['announcement'] is Map<String, dynamic>,
                    )
                    .map(
                      (bookmark) =>
                          Announcement.fromJson(bookmark['announcement']),
                    )
                    .toList();
          }
          // Fallback for old structure
          else if (decoded['announcements'] is List) {
            final List<dynamic> jsonList = decoded['announcements'];
            bookmarks =
                jsonList.map((json) => Announcement.fromJson(json)).toList();
          }
        } else if (decoded is List) {
          // Direct array response - check if it's bookmarks or announcements
          if (decoded.isNotEmpty && decoded.first is Map<String, dynamic>) {
            final firstItem = decoded.first as Map<String, dynamic>;
            if (firstItem.containsKey('announcement')) {
              // Array of bookmark objects
              bookmarks =
                  decoded
                      .where(
                        (bookmark) =>
                            bookmark is Map<String, dynamic> &&
                            bookmark['announcement'] is Map<String, dynamic>,
                      )
                      .map(
                        (bookmark) =>
                            Announcement.fromJson(bookmark['announcement']),
                      )
                      .toList();
            } else {
              // Direct array of announcements
              bookmarks =
                  decoded.map((json) => Announcement.fromJson(json)).toList();
            }
          }
        }

        // Cache the fetched bookmarks for offline use
        await _persistBookmarkCache(bookmarks);
        await _persistBookmarkIds(bookmarks.map((a) => a.id).toSet());

        log('[Bookmark] Fetched and cached ${bookmarks.length} bookmarks');
        return bookmarks;
      } else if (res.statusCode == 401) {
        const storage = FlutterSecureStorage();
        await storage.delete(key: 'access_token');
        // Return cached bookmarks even if token is invalid
        final cached = await loadBookmarkCache();
        return cached;
      }

      // Network error - fallback to cached bookmarks
      final cached = await loadBookmarkCache();
      log(
        '[Bookmark] Network error - returning ${cached.length} cached bookmarks',
      );
      return cached;
    } catch (e, st) {
      log('[Announcement] Bookmark fetch exception: $e\n$st');
      // Fallback to cached bookmarks on exception
      final cached = await loadBookmarkCache();
      log('[Bookmark] Exception - returning ${cached.length} cached bookmarks');
      return cached;
    }
  }

  /// Create bookmark for announcement and update local cache
  Future<bool> createBookmark(int announcementId) async {
    final token = await _getAccessToken();
    if (token == null) return false;

    final uri = Uri.parse('$_baseUrl/api/annc/bookmarks/$announcementId');
    log('[Announcement] Creating bookmark: $uri');

    try {
      final res = await http.post(
        uri,
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      log('[Announcement] Create bookmark status: ${res.statusCode}');

      if (res.statusCode >= 200 && res.statusCode < 300) {
        // Update local cache immediately
        final cachedIds = await loadBookmarkIds();
        cachedIds.add(announcementId);
        await _persistBookmarkIds(cachedIds);

        // Also try to add the announcement to the bookmark cache if available
        final allAnnouncements = await loadLatestAnnouncementFromFile();
        final targetAnnouncement = allAnnouncements.firstWhere(
          (a) => a.id == announcementId,
          orElse: () => throw StateError('Announcement not found'),
        );

        try {
          final cachedBookmarks = await loadBookmarkCache();
          if (!cachedBookmarks.any((b) => b.id == announcementId)) {
            cachedBookmarks.add(targetAnnouncement);
            await _persistBookmarkCache(cachedBookmarks);
          }
        } catch (_) {
          // If announcement not found in cache, skip adding to bookmark cache
        }

        log('[Bookmark] Added ID $announcementId to cache');
        return true;
      } else if (res.statusCode == 401) {
        const storage = FlutterSecureStorage();
        await storage.delete(key: 'access_token');
      }
      return false;
    } catch (e, st) {
      log('[Announcement] Create bookmark exception: $e\n$st');
      return false;
    }
  }

  /// Delete bookmark for announcement and update local cache
  Future<bool> deleteBookmark(int announcementId) async {
    final token = await _getAccessToken();
    if (token == null) return false;

    final uri = Uri.parse('$_baseUrl/api/annc/bookmarks/$announcementId');
    log('[Announcement] Deleting bookmark: $uri');

    try {
      final res = await http.delete(
        uri,
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      log('[Announcement] Delete bookmark status: ${res.statusCode}');

      if (res.statusCode >= 200 && res.statusCode < 300) {
        // Update local cache immediately
        final cachedIds = await loadBookmarkIds();
        cachedIds.remove(announcementId);
        await _persistBookmarkIds(cachedIds);

        // Also remove from bookmark cache if exists
        final cachedBookmarks = await loadBookmarkCache();
        final updatedBookmarks =
            cachedBookmarks.where((b) => b.id != announcementId).toList();
        await _persistBookmarkCache(updatedBookmarks);

        log('[Bookmark] Removed ID $announcementId from cache');
        return true;
      } else if (res.statusCode == 401) {
        const storage = FlutterSecureStorage();
        await storage.delete(key: 'access_token');
      }
      return false;
    } catch (e, st) {
      log('[Announcement] Delete bookmark exception: $e\n$st');
      return false;
    }
  }

  /// Check if specific announcement is bookmarked with offline support
  Future<bool> isAnnouncementBookmarked(int announcementId) async {
    final cachedIds = await loadBookmarkIds();
    return cachedIds.contains(announcementId);
  }

  /// Get bookmark IDs for efficient status checking with offline support
  Future<Set<int>> getBookmarkedAnnouncementIds() async {
    final token = await _getAccessToken();

    // If no token, return cached bookmark IDs
    if (token == null) {
      final cached = await loadBookmarkIds();
      log(
        '[Bookmark] No token - returning ${cached.length} cached bookmark IDs',
      );
      return cached;
    }

    final uri = Uri.parse('$_baseUrl/api/annc/bookmarks/');
    log('[Announcement] Fetching bookmark IDs');

    try {
      final res = await http.get(
        uri,
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (res.statusCode >= 200 && res.statusCode < 300) {
        if (res.body.isEmpty) {
          await _persistBookmarkIds(<int>{});
          return <int>{};
        }

        final decoded = jsonDecode(res.body);
        Set<int> bookmarkIds = <int>{};

        if (decoded is Map<String, dynamic> && decoded['bookmarks'] is List) {
          final List<dynamic> bookmarksList = decoded['bookmarks'];
          bookmarkIds =
              bookmarksList
                  .where(
                    (bookmark) =>
                        bookmark is Map<String, dynamic> &&
                        bookmark['announcement_id'] is int,
                  )
                  .map((bookmark) => bookmark['announcement_id'] as int)
                  .toSet();
        }

        // Cache the fetched bookmark IDs
        await _persistBookmarkIds(bookmarkIds);
        log('[Bookmark] Fetched and cached ${bookmarkIds.length} bookmark IDs');

        return bookmarkIds;
      } else if (res.statusCode == 401) {
        const storage = FlutterSecureStorage();
        await storage.delete(key: 'access_token');
        // Return cached IDs even if token is invalid
        final cached = await loadBookmarkIds();
        return cached;
      }

      // Network error - fallback to cached IDs
      final cached = await loadBookmarkIds();
      log(
        '[Bookmark] Network error - returning ${cached.length} cached bookmark IDs',
      );
      return cached;
    } catch (e, st) {
      log('[Announcement] Bookmark IDs fetch exception: $e\n$st');
      // Fallback to cached IDs on exception
      final cached = await loadBookmarkIds();
      log(
        '[Bookmark] Exception - returning ${cached.length} cached bookmark IDs',
      );
      return cached;
    }
  }

  /// Sync bookmarks from server (call after login)
  Future<void> syncBookmarksAfterLogin() async {
    log('[Bookmark] Syncing bookmarks after login');
    await getBookmarkedAnnouncements(); // This will fetch and cache
    await getBookmarkedAnnouncementIds(); // This will fetch and cache IDs
  }

  /// Clear all caches (call on logout)
  Future<void> clearAllCaches() async {
    await clearAnnouncementFileCache();
    await clearBookmarkCache();
    log('[Cache] Cleared all caches');
  }

  /// Check if user has valid token (online status)
  Future<bool> isOnline() async {
    final token = await _getAccessToken();
    return token != null;
  }
}
