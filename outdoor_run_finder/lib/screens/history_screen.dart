import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/route_provider.dart';
import '../widgets/route_card.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routeState = ref.watch(routeProvider);
    final savedRoutes = routeState.savedRoutes;

    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      appBar: AppBar(
        backgroundColor: const Color(0xE60F172A),
        title: const Row(
          children: [
            Icon(LucideIcons.history, color: Color(0xFFA78BFA)), // purple-400
            SizedBox(width: 8),
            Text('Saved Routes', style: TextStyle(color: Colors.white)),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: savedRoutes.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'No saved routes yet.',
                    style: TextStyle(color: Color(0xFF64748B)),
                  ),
                  TextButton(
                    onPressed: () => context.pop(),
                    child: const Text(
                      'Create one now',
                      style: TextStyle(color: Color(0xFF34D399)),
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: savedRoutes.length,
              itemBuilder: (context, index) {
                final route = savedRoutes[index];
                return RouteCard(
                  route: route,
                  isSaved: true,
                  onStartRun: (r) => context.push('/run', extra: r),
                );
              },
            ),
    );
  }
}
