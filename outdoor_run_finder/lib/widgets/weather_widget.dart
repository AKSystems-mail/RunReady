import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/weather_info.dart';

class WeatherWidget extends StatelessWidget {
  final WeatherInfo weather;

  const WeatherWidget({super.key, required this.weather});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B), // slate-800
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)), // slate-700
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    LucideIcons.sun,
                    color: Color(0xFFFACC15),
                    size: 20,
                  ), // yellow-400
                  SizedBox(width: 8),
                  Text(
                    'Current Conditions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFE2E8F0), // slate-200
                    ),
                  ),
                ],
              ),
              if (weather.warnings.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0x33EF4444), // red-500/20
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        LucideIcons.alertTriangle,
                        size: 12,
                        color: Color(0xFFF87171),
                      ), // red-400
                      SizedBox(width: 4),
                      Text(
                        'WARNING',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFF87171), // red-400
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildMetric(
                icon: LucideIcons.thermometer,
                iconColor: weather.isComfortable
                    ? const Color(0xFF34D399)
                    : const Color(0xFFFB923C), // emerald-400 : orange-400
                value: weather.temperature,
                label: 'Temp',
                bgColor: weather.isComfortable
                    ? const Color(0x1A10B981)
                    : const Color(0x1AF97316), // emerald-500/10 : orange-500/10
                borderColor: weather.isComfortable
                    ? const Color(0x3310B981)
                    : const Color(0x33F97316),
              ),
              const SizedBox(width: 12),
              _buildMetric(
                icon: LucideIcons.cloudRain,
                iconColor: const Color(0xFF60A5FA), // blue-400
                value: weather.precipitationChance,
                label: 'Precipitation',
              ),
              const SizedBox(width: 12),
              _buildMetric(
                icon: LucideIcons.sunrise,
                iconColor: const Color(0xFFFDE047), // yellow-300
                value: weather.sunrise,
                label: 'Sunrise',
              ),
              const SizedBox(width: 12),
              _buildMetric(
                icon: LucideIcons.sunset,
                iconColor: const Color(0xFFFDBA74), // orange-300
                value: weather.sunset,
                label: 'Sunset',
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFF334155)), // slate-700
          const SizedBox(height: 16),
          if (!weather.isComfortable)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                'Running conditions might be uncomfortable. Check temperature.',
                style: TextStyle(
                  color: Color(0xFFFDBA74),
                  fontSize: 14,
                ), // orange-300
              ),
            ),
          ...weather.warnings.map(
            (warn) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.alertTriangle,
                    size: 14,
                    color: Color(0xFFF87171),
                  ), // red-400
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      warn,
                      style: const TextStyle(
                        color: Color(0xFFF87171), // red-400
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (weather.isComfortable && weather.warnings.isEmpty)
            const Text(
              'Conditions look great for a run! 🏃',
              style: TextStyle(
                color: Color(0xFF34D399),
                fontSize: 14,
              ), // emerald-400
            ),
        ],
      ),
    );
  }

  Widget _buildMetric({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
    Color? bgColor,
    Color? borderColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor ?? const Color(0x4D334155), // slate-700/30
          borderRadius: BorderRadius.circular(8),
          border: borderColor != null ? Border.all(color: borderColor) : null,
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 10,
              ), // slate-400
            ),
          ],
        ),
      ),
    );
  }
}
