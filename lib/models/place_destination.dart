import 'package:google_navigation_flutter/google_navigation_flutter.dart';

/// Represents a campus place (faculty/building/landmark/poi) that can
/// be chosen as a navigation destination.
class PlaceDestination {
  final String id; // stable id for storage/favorites later
  final String nameTh; // Thai display name
  final String? nameEn; // Optional secondary text (EN/description)
  final String? code; // Optional short code for searching/display
  final String? description; // Optional long description/details
  final LatLng coordinate;

  const PlaceDestination({
    required this.id,
    required this.nameTh,
    this.nameEn,
    this.code,
    this.description,
    required this.coordinate,
  });
}
