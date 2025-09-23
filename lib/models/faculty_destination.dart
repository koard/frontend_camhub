import 'package:google_navigation_flutter/google_navigation_flutter.dart';

/// Represents a campus faculty (or any future point of interest) that can
/// be chosen as a navigation destination.
class FacultyDestination {
  final String id; // stable id for storage/favorites later
  final String nameTh; // Thai display name
  final String? nameEn; // Optional English name
  final LatLng coordinate;

  const FacultyDestination({
    required this.id,
    required this.nameTh,
    this.nameEn,
    required this.coordinate,
  });
}

/// Temporary seed list. Right now we only have Faculty of Engineering but
/// we structure as a list to easily expand.
const facultyDestinationsSeed = <FacultyDestination>[
  FacultyDestination(
    id: 'eng',
    nameTh: 'คณะวิศวกรรมศาสตร์',
    nameEn: 'Faculty of Engineering',
    coordinate: LatLng(latitude: 7.006289565879179, longitude: 100.50111598306944),
  ),
  FacultyDestination(
    id: 'sci',
    nameTh: 'คณะวิทยาศาสตร์',
    nameEn: 'Faculty of Science',
    coordinate: LatLng(latitude: 7.008032439042828, longitude: 100.49723894261248),
  ),
  FacultyDestination(
    id: 'mgmt',
    nameTh: 'คณะวิทยาการจัดการ',
    nameEn: 'Faculty of Management Sciences',
    coordinate: LatLng(latitude: 7.000200, longitude: 100.494800), // TODO: verify
  ),
  FacultyDestination(
    id: 'med',
    nameTh: 'คณะแพทยศาสตร์',
    nameEn: 'Faculty of Medicine',
    coordinate: LatLng(latitude: 7.005900, longitude: 100.501900), // TODO: verify
  ),
  FacultyDestination(
    id: 'nur',
    nameTh: 'คณะพยาบาลศาสตร์',
    nameEn: 'Faculty of Nursing',
    coordinate: LatLng(latitude: 7.006900, longitude: 100.500500), // TODO: verify
  ),
  FacultyDestination(
    id: 'dent',
    nameTh: 'คณะทันตแพทยศาสตร์',
    nameEn: 'Faculty of Dentistry',
    coordinate: LatLng(latitude: 7.004700, longitude: 100.502400), // TODO: verify
  ),
  FacultyDestination(
    id: 'pharm',
    nameTh: 'คณะเภสัชศาสตร์',
    nameEn: 'Faculty of Pharmaceutical Sciences',
    coordinate: LatLng(latitude: 7.000900, longitude: 100.498800), // TODO: verify
  ),
  FacultyDestination(
    id: 'natres',
    nameTh: 'คณะทรัพยากรธรรมชาติ',
    nameEn: 'Faculty of Natural Resources',
    coordinate: LatLng(latitude: 6.998600, longitude: 100.496800), // TODO: verify
  ),
  FacultyDestination(
    id: 'agro',
    nameTh: 'คณะอุตสาหกรรมเกษตร',
    nameEn: 'Faculty of Agro-Industry',
    coordinate: LatLng(latitude: 7.002800, longitude: 100.497700), // TODO: verify
  ),
  FacultyDestination(
    id: 'econ',
    nameTh: 'คณะเศรษฐศาสตร์',
    nameEn: 'Faculty of Economics',
    coordinate: LatLng(latitude: 7.000800, longitude: 100.495700), // TODO: verify
  ),
  FacultyDestination(
    id: 'lib',
    nameTh: 'คณะศิลปศาสตร์',
    nameEn: 'Faculty of Liberal Arts',
    coordinate: LatLng(latitude: 7.001900, longitude: 100.493900), // TODO: verify
  ),
  FacultyDestination(
    id: 'vet',
    nameTh: 'คณะสัตวแพทยศาสตร์',
    nameEn: 'Faculty of Veterinary Science',
    coordinate: LatLng(latitude: 7.012300, longitude: 100.491400), // TODO: verify
  ),
];
