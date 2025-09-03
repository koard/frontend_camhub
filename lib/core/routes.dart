import 'package:flutter/material.dart';
import 'package:campusapp/ui/screens/main_screen/main_screen.dart';
import 'package:campusapp/ui/screens/annoucement_screen/announcements_screen.dart';
import 'package:campusapp/ui/screens/events_screen/events_screen.dart';
import 'package:campusapp/ui/screens/profile_screen/profile_screen.dart';
import 'package:campusapp/ui/screens/schedule_screen/schedule_screen.dart';
import 'package:campusapp/ui/screens/account_screen/login_screen.dart';
import 'package:campusapp/ui/screens/map_screen/map_screen.dart';
import 'package:campusapp/ui/screens/group_screen/group_screen.dart';
import 'package:campusapp/ui/screens/example_info_screen/example_info_screen.dart';
import 'package:campusapp/ui/screens/simulation_screen/simulation_screen.dart';
import 'package:campusapp/ui/screens/subject_screen/subject_screen.dart';
import 'package:campusapp/ui/screens/started_screen/splash_screen.dart';
import 'package:campusapp/ui/screens/started_screen/on_boarding_screen.dart';

class AppRoutes {
  static const String home = '/home';
  static const String events = '/events';
  static const String profile = '/profile';
  static const String schedule = '/schedule';
  static const String login = '/login';
  static const String map = '/map';
  static const String group = '/group';
  static const String exampleInfo = '/exampleInfo';
  static const String simulation = '/simulation';
  static const String subject = '/subject';
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String announcements = '/announcements';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return _buildSlideRoute(const MainHomeScreen(), settings);
      case announcements:
        return _buildSlideRoute(const AnnouncementScreen(), settings);
      case events:
        return _buildSlideRoute(const EventsScreen(), settings);
      case profile:
        return _buildSlideRoute(const ProfileScreen(), settings);
      case schedule:
        return _buildSlideRoute(const ScheduleScreen(), settings);
      case login:
        return _buildSlideRoute(const LoginScreen(), settings);
      case map:
        return _buildSlideRoute(const MapScreen(), settings);
      case group:
        return _buildSlideRoute(const GroupScreen(), settings);
      case exampleInfo:
        return _buildSlideRoute(const ExampleInfoScreen(), settings);
      case simulation:
        return _buildSlideRoute(const SimulationScreen(), settings);
      case subject:
        return _buildSlideRoute(const SubjectScreen(), settings);
      case onboarding:
        return _buildSlideRoute(const OnboardingScreen(), settings);
      default:
        return _buildSlideRoute(const SplashScreen(), settings);
    }
  }

  static PageRouteBuilder _buildSlideRoute(
    Widget page,
    RouteSettings settings,
  ) {
    return PageRouteBuilder(
      settings: settings,
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;

        final tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));

        final offsetAnimation = animation.drive(tween);

        return SlideTransition(
          position: offsetAnimation,
          child: FadeTransition(opacity: animation, child: child),
        );
      },
    );
  }
}
