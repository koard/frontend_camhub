import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'ui/screens/main_screen/main_screen.dart';
import 'package:campusapp/ui/screens/started_screen/on_boarding_screen.dart';
import 'package:campusapp/core/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'ui/providers/subject_provider.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'core/deep_link_handler.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
late final DeepLinkHandler deepLinkHandler;

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  // Preserve splash screen during initialization
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Your initialization code
  await dotenv.load(fileName: 'assets/.env');

  runApp(const MyApp());

  // Start deep link handler after app is ready (route deep links after normal nav)
  deepLinkHandler = DeepLinkHandler(navigatorKey: navigatorKey);
  unawaited(deepLinkHandler.init());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MultiProvider(
          providers: [ChangeNotifierProvider(create: (_) => SubjectProvider())],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Flutter Onboarding Example',
            navigatorKey: navigatorKey,
            onGenerateRoute: AppRoutes.onGenerateRoute,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF113F67),
              ),
              textTheme: GoogleFonts.promptTextTheme(
                Theme.of(context).textTheme,
              ),
              appBarTheme: AppBarTheme(
                backgroundColor: const Color(0xFF113F67),
                centerTitle: true,
                titleTextStyle: GoogleFonts.prompt(
                  textStyle: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                iconTheme: IconThemeData(
                  color: Colors.white, // สีของลูกศร
                  size: 18.sp, // ขนาดของลูกศร (ถ้าต้องการ)
                ),
              ),
            ),
            home: const Launcher(),
          ),
        );
      },
    );
  }
}

// Launcher widget: เช็คว่าควรไป onboarding หรือ home
class Launcher extends StatefulWidget {
  const Launcher({super.key});

  @override
  State<Launcher> createState() => _LauncherState();
}

class _LauncherState extends State<Launcher> {
  Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('seenOnboarding') != true;
  }

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Your app initialization logic
    final isFirst = await isFirstLaunch();

    // Remove splash screen after initialization
    FlutterNativeSplash.remove();

    // Navigate based on first launch
    navigatorKey.currentState?.pushReplacement(
      MaterialPageRoute(
        builder:
            (_) => isFirst ? const OnboardingScreen() : const MainHomeScreen(),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF113F67),
      body: Center(child: CircularProgressIndicator(color: Colors.white)),
    );
  }
}
