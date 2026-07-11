import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'models/route_data.dart' as models;
import 'screens/active_run_screen.dart';
import 'screens/history_screen.dart';
import 'screens/home_screen.dart';
import 'screens/stats_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: RunReadyApp()));
}

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    GoRoute(
      path: '/history',
      builder: (context, state) => const HistoryScreen(),
    ),
    GoRoute(path: '/stats', builder: (context, state) => const StatsScreen()),
    GoRoute(
      path: '/run',
      builder: (context, state) {
        final route = state.extra as models.RouteData;
        return ActiveRunScreen(route: route);
      },
    ),
  ],
);

class RunReadyApp extends StatelessWidget {
  const RunReadyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'RunReady',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF020617), // slate-950
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF10B981), // emerald-500
          secondary: Color(0xFF3B82F6), // blue-500
          surface: Color(0xFF0F172A), // slate-900
          background: Color(0xFF020617), // slate-950
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        useMaterial3: true,
      ),
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
