import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/route_data.dart';

class RouteCard extends StatefulWidget {
  final RouteData route;

  const RouteCard({super.key, required this.route});

  @override
  State<RouteCard> createState() => _RouteCardState();
}

class _RouteCardState extends State<RouteCard> {
  GoogleMapController? _mapController;
  LatLng? _start;
  LatLng? _end;
  List<LatLng> _parsedCoords = [];

  @override
  void initState() {
    super.initState();
    _parseRouteData();
  }

  void _parseRouteData() {
    final startCoords = widget.route.mapData.start.split(',');
    if (startCoords.length == 2) {
      _start = LatLng(double.parse(startCoords[0]), double.parse(startCoords[1]));
    }

    final endCoords = widget.route.mapData.end.split(',');
    if (endCoords.length == 2) {
      _end = LatLng(double.parse(endCoords[0]), double.parse(endCoords[1]));
    }

    _parsedCoords = widget.route.mapData.routeCoordinates.map((c) {
      final parts = c.split(',');
      return LatLng(double.parse(parts[0]), double.parse(parts[1]));
    }).toList();
  }

  void _openExternalMap() {
    // Implementation for external maps app
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Directions list
          Column(
            children: widget.route.directions!
                .asMap()
                .entries
                .map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFF334155),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF475569),
                            ),
                          ),
                          child: Text(
                            "${entry.key + 1}",
                            style: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            entry.value,
                            style: const TextStyle(
                              color: Color(0xFFCBD5E1),
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                })
                .toList(),
          ),
          const SizedBox(height: 24),

          // Map View
          Container(
            height: 256,
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                if (_start != null)
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _start!,
                      zoom: 14,
                    ),
                    onMapCreated: (controller) => _mapController = controller,
                    polylines: {
                      if (_parsedCoords.isNotEmpty)
                        Polyline(
                          polylineId: const PolylineId('route'),
                          points: _parsedCoords,
                          color: const Color(0xFF10B981),
                          width: 5,
                        ),
                    },
                    markers: {
                      if (_start != null)
                        Marker(
                          markerId: const MarkerId('start'),
                          position: _start!,
                        ),
                      if (_end != null)
                        Marker(
                          markerId: const MarkerId('end'),
                          position: _end!,
                        ),
                    },
                  )
                else
                  const Center(child: Text("No route data")),
                
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: IconButton(
                    icon: const Icon(Icons.open_in_new, color: Colors.white),
                    onPressed: _openExternalMap,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Sync with info (omitted)
        ],
      ),
    );
  }
}
