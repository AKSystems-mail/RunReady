import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/route_provider.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routeState = ref.watch(routeProvider);
    final stats = routeState.stats;

    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      appBar: AppBar(
        backgroundColor: const Color(0xE60F172A),
        title: const Row(
          children: [
            Icon(LucideIcons.activity, color: Color(0xFF34D399)),
            SizedBox(width: 8),
            Text('My Stats', style: TextStyle(color: Colors.white)),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildStatCard(
              title: 'Total Runs',
              value: stats.totalRuns.toString(),
              icon: LucideIcons.trophy,
              color: const Color(0xFFFACC15), // yellow-400
            ),
            const SizedBox(height: 16),
            _buildStatCard(
              title: 'Total Distance',
              value: '${stats.totalDistanceKm.toStringAsFixed(1)} km',
              icon: LucideIcons.map,
              color: const Color(0xFF60A5FA), // blue-400
            ),
            const SizedBox(height: 16),
            _buildStatCard(
              title: 'Total Time',
              value: _formatDuration(stats.totalTimeSeconds),
              icon: LucideIcons.clock,
              color: const Color(0xFFA78BFA), // purple-400
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final hrs = seconds ~/ 3600;
    final mins = (seconds % 3600) ~/ 60;
    return '${hrs}h ${mins}m';
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
