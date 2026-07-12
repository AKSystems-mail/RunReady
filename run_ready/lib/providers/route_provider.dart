import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/enums.dart';
import '../models/preferences.dart';
import '../models/route_data.dart';
import '../models/user_stats.dart';
import '../models/run_session.dart';
import '../services/gemini_service.dart';

// Services
final geminiServiceProvider = Provider((ref) => GeminiService());

// State Classes
class RouteState {
  final bool isLoading;
  final String? error;
  final RouteData? currentRoute;
  final List<RouteData> savedRoutes;
  final UserStats stats;
  final RoutePreferences preferences;

  RouteState({
    this.isLoading = false,
    this.error,
    this.currentRoute,
    this.savedRoutes = const [],
    required this.stats,
    required this.preferences,
  });

  RouteState copyWith({
    bool? isLoading,
    String? error,
    RouteData? currentRoute,
    List<RouteData>? savedRoutes,
    UserStats? stats,
    RoutePreferences? preferences,
  }) {
    return RouteState(
      isLoading: isLoading ?? this.isLoading,
      error:
          error, // Nullable, so if not passed, it remains null (or we can explicitly clear it)
      currentRoute: currentRoute ?? this.currentRoute,
      savedRoutes: savedRoutes ?? this.savedRoutes,
      stats: stats ?? this.stats,
      preferences: preferences ?? this.preferences,
    );
  }
}

// Notifier
class RouteNotifier extends Notifier<RouteState> {
  final GeminiService _geminiService = GeminiService();
  static const _storageKeyStats = 'rungenie_stats';
  static const _storageKeyRoutes = 'rungenie_routes';
  static const _storageKeyPrefs = 'rungenie_last_prefs';

  @override
  RouteState build() {
    _loadData();
    return RouteState(
      stats: UserStats(totalRuns: 0, totalDistanceKm: 0),
      preferences: RoutePreferences(
        distance: 3,
        unit: DistanceUnit.miles,
        routeType: RouteType.loop,
        mode: RouteMode.local,
      ),
    );
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    // Load Stats
    final statsJson = prefs.getString(_storageKeyStats);
    final stats = statsJson != null
        ? UserStats.fromJson(jsonDecode(statsJson))
        : UserStats(totalRuns: 0, totalDistanceKm: 0);

    // Load Routes
    final routesJson = prefs.getString(_storageKeyRoutes);
    final savedRoutes = routesJson != null
        ? (jsonDecode(routesJson) as List)
              .map((e) => RouteData.fromJson(e))
              .toList()
        : <RouteData>[];

    // Load Prefs
    final prefsJson = prefs.getString(_storageKeyPrefs);
    final routePrefs = prefsJson != null
        ? RoutePreferences.fromJson(jsonDecode(prefsJson))
        : state.preferences;

    state = state.copyWith(
      stats: stats,
      savedRoutes: savedRoutes,
      preferences: routePrefs,
    );
  }

  Future<void> updatePreferences(RoutePreferences prefs) async {
    state = state.copyWith(preferences: prefs);
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_storageKeyPrefs, jsonEncode(prefs.toJson()));
  }

  Future<void> generateRoute() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      Position? position;
      if (state.preferences.customLocation == null ||
          state.preferences.customLocation!.isEmpty) {
        // Get location
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          throw Exception('Location services are disabled.');
        }

        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            throw Exception('Location permissions are denied');
          }
        }

        if (permission == LocationPermission.deniedForever) {
          throw Exception('Location permissions are permanently denied.');
        }

        position = await Geolocator.getCurrentPosition();
        // Store GPS coordinates as customLocation so they persist
        // and can be reused without re-acquiring GPS
        final updatedPrefs = state.preferences.copyWith(
          customLocation: '${position.latitude},${position.longitude}',
        );
        state = state.copyWith(preferences: updatedPrefs);
      }

      final route = await _geminiService.generateRunRoute(
        state.preferences,
        lat: position?.latitude,
        lng: position?.longitude,
      );

      state = state.copyWith(isLoading: false, currentRoute: route);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> saveRoute(RouteData route) async {
    if (state.savedRoutes.any((r) => r.id == route.id)) return;

    final newRoutes = [route, ...state.savedRoutes];
    state = state.copyWith(savedRoutes: newRoutes);

    final sp = await SharedPreferences.getInstance();
    await sp.setString(
      _storageKeyRoutes,
      jsonEncode(newRoutes.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> finishRun(RunSession session) async {
    // Convert to KM
    final distKm = session.unit == DistanceUnit.miles
        ? session.distance * 1.60934
        : session.distance;

    final newStats = UserStats(
      totalRuns: state.stats.totalRuns + 1,
      totalDistanceKm: state.stats.totalDistanceKm + distKm,
      totalTimeSeconds: state.stats.totalTimeSeconds + session.durationSeconds,
      lastRunDate: DateTime.now().millisecondsSinceEpoch,
    );

    state = state.copyWith(stats: newStats);

    final sp = await SharedPreferences.getInstance();
    await sp.setString(_storageKeyStats, jsonEncode(newStats.toJson()));

    // Auto save route if needed
    RouteData? route;
    if (state.currentRoute?.id == session.routeId) {
      route = state.currentRoute;
    } else {
      try {
        route = state.savedRoutes.firstWhere((r) => r.id == session.routeId);
      } catch (e) {
        route = null;
      }
    }

    if (route != null) {
      await saveRoute(route);
    }
  }
}

final routeProvider = NotifierProvider<RouteNotifier, RouteState>(() {
  return RouteNotifier();
});
