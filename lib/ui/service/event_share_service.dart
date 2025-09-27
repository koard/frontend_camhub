import 'package:flutter_dotenv/flutter_dotenv.dart';

class EventShareService {
  static String get _baseUrl =>
      dotenv.env['API_BASE_URL']?.trim().replaceAll(RegExp(r"/+$$"), '') ??
      'http://127.0.0.1:8000';

  /// Build an 'open' page URL that attempts to open the app (backend provides /api/events/open/{id})
  static Uri openEventUri(int eventId) => Uri.parse('$_baseUrl/api/events/open/$eventId');

  /// Build the custom-scheme deep link for direct app opening
  static Uri appSchemeUri(int eventId) => Uri.parse('campusapp://event/$eventId');

  /// Title used for sharing
  static String titleFrom(Map<String, dynamic> event) =>
      (event['name'] ?? event['title'] ?? 'กิจกรรม').toString();

  /// Description used for sharing (short)
  static String? shortDescriptionFrom(Map<String, dynamic> event) {
    final desc = (event['description'] as String?)?.trim();
    if (desc == null || desc.isEmpty) return null;
    if (desc.length <= 160) return desc;
    return desc.substring(0, 157) + '...';
  }

  /// Compose the message text for sharing
  static String composeShareText(Map<String, dynamic> event, {Uri? url}) {
    final title = titleFrom(event);
    final desc = shortDescriptionFrom(event);
    final id = int.tryParse((event['id'] ?? '').toString());
    final scheme = id != null ? appSchemeUri(id).toString() : null;
    final openUrl = id != null ? openEventUri(id).toString() : (url?.toString());
    final lines = <String>[
      '📣 $title',
      if (desc != null) desc,
      if (scheme != null) scheme, // เปิดเข้าแอปทันทีถ้ามีแอป
      if (openUrl != null) openUrl, // fallback หน้าเปิดแอป/Intent ในเบราว์เซอร์
    ];
    return lines.join('\n\n');
  }
}
