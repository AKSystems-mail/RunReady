import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/enums.dart';
import '../models/preferences.dart';
import '../providers/route_provider.dart';
import '../widgets/route_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routeState = ref.watch(routeProvider);
    final notifier = ref.read(routeProvider.notifier);
    final prefs = routeState.preferences;

    return Scaffold(
      backgroundColor: const Color(0xFF020617), // slate-950
      appBar: AppBar(
        backgroundColor: const Color(0xE60F172A), // slate-900/90
        elevation: 0,
        title: const Row(
          children: [
            Icon(LucideIcons.map, color: Color(0xFF34D399)), // emerald-400
            SizedBox(width: 8),
            Text(
              'RunReady',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              LucideIcons.menu,
              color: Color(0xFFCBD5E1),
            ), // slate-300
            onPressed: () {
              Scaffold.of(context).openEndDrawer();
            },
          ),
        ],
      ),
      endDrawer: _buildDrawer(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Form
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A), // slate-900
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF334155)), // slate-700
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        LucideIcons.navigation,
                        color: Color(0xFF60A5FA),
                        size: 20,
                      ), // blue-400
                      SizedBox(width: 8),
                      Text(
                        'Plan Your Run',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Location
                  const Text(
                    'Start Location',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Current Location (or type address)',
                      hintStyle: const TextStyle(color: Color(0xFF475569)),
                      filled: true,
                      fillColor: const Color(0xFF1E293B), // slate-800
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF334155)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF334155)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Color(0xFF10B981),
                        ), // emerald-500
                      ),
                      suffixIcon:
                          prefs.customLocation == null ||
                              prefs.customLocation!.isEmpty
                          ? const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  LucideIcons.zap,
                                  size: 12,
                                  color: Color(0xFF10B981),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'GPS Active',
                                  style: TextStyle(
                                    color: Color(0xFF10B981),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(width: 12),
                              ],
                            )
                          : null,
                    ),
                    onChanged: (value) {
                      notifier.updatePreferences(
                        RoutePreferences(
                          distance: prefs.distance,
                          unit: prefs.unit,
                          routeType: prefs.routeType,
                          mode: prefs.mode,
                          customLocation: value,
                                loopTightness: prefs.loopTightness,
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      // Distance
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Distance',
                              style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 48,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF1E293B),
                                      borderRadius: BorderRadius.horizontal(
                                        left: Radius.circular(8),
                                      ),
                                      border: Border(
                                        top: BorderSide(
                                          color: Color(0xFF334155),
                                        ),
                                        bottom: BorderSide(
                                          color: Color(0xFF334155),
                                        ),
                                        left: BorderSide(
                                          color: Color(0xFF334155),
                                        ),
                                      ),
                                    ),
                                    child: TextField(
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 16,
                                        ),
                                      ),
                                      controller:
                                          TextEditingController(
                                              text: prefs.distance.toString(),
                                            )
                                            ..selection =
                                                TextSelection.fromPosition(
                                                  TextPosition(
                                                    offset: prefs.distance
                                                        .toString()
                                                        .length,
                                                  ),
                                                ),
                                      onChanged: (val) {
                                        final d = double.tryParse(val);
                                        if (d != null) {
                                          notifier.updatePreferences(
                                            RoutePreferences(
                                              distance: d,
                                              unit: prefs.unit,
                                              routeType: prefs.routeType,
                                              mode: prefs.mode,
                                              customLocation:
                                                  prefs.customLocation,
                                              loopTightness: prefs.loopTightness,
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                ),
                                Container(
                                  height: 48,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF334155), // slate-700
                                    borderRadius: BorderRadius.horizontal(
                                      right: Radius.circular(8),
                                    ),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<DistanceUnit>(
                                      value: prefs.unit,
                                      dropdownColor: const Color(0xFF334155),
                                      icon: const Icon(
                                        Icons.arrow_drop_down,
                                        color: Colors.white,
                                      ),
                                      items: DistanceUnit.values.map((u) {
                                        return DropdownMenuItem(
                                          value: u,
                                          child: Text(
                                            distanceUnitToString(u),
                                            style: const TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          notifier.updatePreferences(
                                            RoutePreferences(
                                              distance: prefs.distance,
                                              unit: val,
                                              routeType: prefs.routeType,
                                              mode: prefs.mode,
                                              customLocation:
                                                  prefs.customLocation,
                                              loopTightness: prefs.loopTightness,
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Structure
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Structure',
                              style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 48,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFF334155),
                                ),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<RouteType>(
                                  value: prefs.routeType,
                                  dropdownColor: const Color(0xFF1E293B),
                                  isExpanded: true,
                                  icon: const Icon(
                                    Icons.arrow_drop_down,
                                    color: Colors.white,
                                  ),
                                  items: RouteType.values.map((t) {
                                    return DropdownMenuItem(
                                      value: t,
                                      child: Text(
                                        t == RouteType.loop
                                            ? 'Loop'
                                            : 'Point-to-Point',
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      notifier.updatePreferences(
                                        RoutePreferences(
                                          distance: prefs.distance,
                                          unit: prefs.unit,
                                          routeType: val,
                                          mode: prefs.mode,
                                          customLocation: prefs.customLocation,
                                loopTightness: prefs.loopTightness,
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Mode
                  const Text(
                    'Route Mode',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildModeButton(
                          context,
                          icon: LucideIcons.home,
                          label: 'Local',
                          subLabel: 'Nearby & Safe',
                          isSelected: prefs.mode == RouteMode.local,
                          onTap: () {
                            notifier.updatePreferences(
                              RoutePreferences(
                                distance: prefs.distance,
                                unit: prefs.unit,
                                routeType: prefs.routeType,
                                mode: RouteMode.local,
                                customLocation: prefs.customLocation,
                                loopTightness: prefs.loopTightness,
                              ),
                            );
                          },
                          activeColor: const Color(0xFF10B981), // emerald-500
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildModeButton(
                          context,
                          icon: LucideIcons.compass,
                          label: 'Explorer',
                          subLabel: 'Scenic & New',
                          isSelected: prefs.mode == RouteMode.explorer,
                          onTap: () {
                            notifier.updatePreferences(
                              RoutePreferences(
                                distance: prefs.distance,
                                unit: prefs.unit,
                                routeType: prefs.routeType,
                                mode: RouteMode.explorer,
                                customLocation: prefs.customLocation,
                                loopTightness: prefs.loopTightness,
                              ),
                            );
                          },
                          activeColor: const Color(0xFF3B82F6), // blue-500
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Loop Tightness Slider (only for Loop routes)
                  if (prefs.routeType == RouteType.loop) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                LucideIcons.repeat,
                                size: 16,
                                color: Color(0xFF60A5FA),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Loop Tightness',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                prefs.loopTightness < 0.33
                                    ? 'Tight (Multi-Lap)'
                                    : prefs.loopTightness < 0.66
                                        ? 'Moderate'
                                        : 'Sprawling',
                                style: TextStyle(
                                  color: prefs.loopTightness < 0.33
                                      ? const Color(0xFF34D399)
                                      : prefs.loopTightness < 0.66
                                          ? const Color(0xFFFBBF24)
                                          : const Color(0xFF60A5FA),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SliderTheme(
                            data: SliderThemeData(
                              activeTrackColor: const Color(0xFF34D399),
                              inactiveTrackColor:
                                  const Color(0xFF334155),
                              thumbColor: const Color(0xFF34D399),
                              overlayColor:
                                  const Color(0x2934D399),
                              trackHeight: 6,
                              thumbShape:
                                  const RoundSliderThumbShape(
                                    enabledThumbRadius: 10,
                                  ),
                              overlayShape:
                                  const RoundSliderOverlayShape(
                                    overlayRadius: 20,
                                  ),
                            ),
                            child: Slider(
                              value: prefs.loopTightness,
                              min: 0.0,
                              max: 1.0,
                              divisions: 20,
                              onChanged: (val) {
                                notifier.updatePreferences(
                                  RoutePreferences(
                                    distance: prefs.distance,
                                    unit: prefs.unit,
                                    routeType: prefs.routeType,
                                    mode: prefs.mode,
                                    customLocation:
                                        prefs.customLocation,
                                    loopTightness: val,
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Tight\nMulti-lap',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 10,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                'Sprawling\nSingle lap',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 10,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              borderRadius:
                                  BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  LucideIcons.info,
                                  size: 14,
                                  color: Color(0xFF94A3B8),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    prefs.loopTightness < 0.33
                                        ? 'Compact loops around a few blocks. Multiple laps to hit the target distance.'
                                        : prefs.loopTightness < 0.66
                                            ? 'Moderate loops with some variation through the neighborhood.'
                                            : 'Wide scenic loops exploring a larger area in a single lap.',
                                    style: const TextStyle(
                                      color: Color(0xFF94A3B8),
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: routeState.isLoading
                          ? null
                          : () => notifier.generateRoute(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669), // emerald-600
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      child: routeState.isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Generate Route',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),

            if (routeState.error != null)
              Container(
                margin: const EdgeInsets.only(top: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0x1AEF4444), // red-500/10
                  border: Border.all(
                    color: const Color(0x80EF4444),
                  ), // red-500/50
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  routeState.error!,
                  style: const TextStyle(color: Color(0xFFFECACA)), // red-200
                  textAlign: TextAlign.center,
                ),
              ),

            if (routeState.currentRoute != null)
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: RouteCard(
                  route: routeState.currentRoute!,
                  onSave: () => notifier.saveRoute(routeState.currentRoute!),
                  isSaved: routeState.savedRoutes.any(
                    (r) => r.id == routeState.currentRoute!.id,
                  ),
                  onStartRun: (route) {
                    context.push('/run', extra: route);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String subLabel,
    required bool isSelected,
    required VoidCallback onTap,
    required Color activeColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withOpacity(0.2)
              : const Color(0xFF1E293B),
          border: Border.all(
            color: isSelected ? activeColor : const Color(0xFF334155),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? activeColor.withOpacity(0.8)
                  : const Color(0xFF94A3B8),
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            Text(
              subLabel,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF020617),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Color(0xFF0F172A)),
            child: Center(
              child: Text(
                'RunReady',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(
              LucideIcons.plusCircle,
              color: Color(0xFF34D399),
            ),
            title: const Text(
              'Plan Run',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              context.pop(); // Close drawer
              // Already on home
            },
          ),
          ListTile(
            leading: const Icon(LucideIcons.history, color: Color(0xFFCBD5E1)),
            title: const Text('History', style: TextStyle(color: Colors.white)),
            onTap: () {
              context.pop();
              context.push('/history');
            },
          ),
          ListTile(
            leading: const Icon(LucideIcons.activity, color: Color(0xFFCBD5E1)),
            title: const Text(
              'My Stats',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              context.pop();
              context.push('/stats');
            },
          ),
        ],
      ),
    );
  }
}
