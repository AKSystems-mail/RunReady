import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../config/env.dart';
import '../models/enums.dart';
import '../models/route_data.dart';
import 'weather_widget.dart';

class RouteCard extends StatefulWidget {
  final RouteData route;
  final VoidCallback? onSave;
  final bool isSaved;
  final Function(RouteData)? onStartRun;

  const RouteCard({
    super.key,
    required this.route,
    this.onSave,
    this.isSaved = false,
    this.onStartRun,
  });

  @override
  State<RouteCard> createState() => _RouteCardState();
}

class _RouteCardState extends State<RouteCard> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    final apiKey = Env.googleMapsApiKey;
    String mapUrl;

    if (widget.route.mapData != null) {
      final origin = Uri.encodeComponent(widget.route.mapData!.start);
      final destination = Uri.encodeComponent(widget.route.mapData!.end);
      String waypointsParam = "";
      if (widget.route.mapData!.waypoints.isNotEmpty) {
        waypointsParam =
            "&waypoints=${widget.route.mapData!.waypoints.map((w) => Uri.encodeComponent(w)).join('|')}";
      }
      mapUrl =
          "https://www.google.com/maps/embed/v1/directions?key=$apiKey&origin=$origin&destination=$destination$waypointsParam&mode=walking";
    } else {
      final mapQuery = Uri.encodeComponent(
        "${widget.route.title} ${widget.route.preferences.customLocation ?? ''}",
      );
      mapUrl =
          "https://www.google.com/maps/embed/v1/search?key=$apiKey&q=$mapQuery";
    }

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..loadRequest(Uri.parse(mapUrl));
  }

  Future<void> _handleShare() async {
    final text =
        "Check out this ${widget.route.preferences.distance}${distanceUnitToString(widget.route.preferences.unit)} run I found on RunReady: ${widget.route.title}\n\n${widget.route.description}";
    await Share.share(text);
  }

  Future<void> _openExternalMap() async {
    String externalMapUrl;
    if (widget.route.mapData != null) {
      final origin = Uri.encodeComponent(widget.route.mapData!.start);
      final destination = Uri.encodeComponent(widget.route.mapData!.end);
      String waypointsParam = "";
      if (widget.route.mapData!.waypoints.isNotEmpty) {
        waypointsParam =
            "&waypoints=${widget.route.mapData!.waypoints.map((w) => Uri.encodeComponent(w)).join('|')}";
      }
      externalMapUrl =
          "https://www.google.com/maps/dir/?api=1&origin=$origin&destination=$destination&travelmode=walking$waypointsParam";
    } else {
      final mapQuery = Uri.encodeComponent(
        "${widget.route.title} ${widget.route.preferences.customLocation ?? ''}",
      );
      externalMapUrl =
          "https://www.google.com/maps/search/?api=1&query=$mapQuery";
    }

    final uri = Uri.parse(externalMapUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A), // slate-900
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)), // slate-700
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0x80064E3B),
                  Color(0xFF0F172A),
                ], // emerald-900/50 -> slate-900
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              border: Border(bottom: BorderSide(color: Color(0xFF334155))),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _buildBadge(
                            "${widget.route.preferences.distance} ${distanceUnitToString(widget.route.preferences.unit)}",
                            const Color(0xFF10B981), // emerald-500
                            const Color(0xFF022C22), // emerald-950
                          ),
                          const SizedBox(width: 8),
                          _buildBadge(
                            routeTypeToString(
                                      widget.route.preferences.routeType,
                                    ) ==
                                    'loop'
                                ? 'Loop'
                                : 'P2P',
                            const Color(0xFFCBD5E1), // slate-300
                            const Color(0xFF334155), // slate-700
                          ),
                          const SizedBox(width: 8),
                          _buildBadge(
                            routeModeToString(widget.route.preferences.mode) ==
                                    'local'
                                ? 'Local'
                                : 'Explorer',
                            const Color(0xFFCBD5E1), // slate-300
                            const Color(0xFF334155), // slate-700
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.route.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: _handleShare,
                      icon: const Icon(
                        LucideIcons.share2,
                        color: Color(0xFF60A5FA),
                      ), // blue-400
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFF1E293B),
                      ),
                    ),
                    if (widget.onSave != null) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: widget.isSaved ? null : widget.onSave,
                        icon: Icon(
                          LucideIcons.save,
                          color: const Color(0xFF34D399),
                        ), // emerald-400
                        style: IconButton.styleFrom(
                          backgroundColor: widget.isSaved
                              ? const Color(0x3310B981) // emerald-500/20
                              : const Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.route.weather != null)
                  WeatherWidget(weather: widget.route.weather!),

                Text(
                  widget.route.description,
                  style: const TextStyle(
                    color: Color(0xFFCBD5E1), // slate-300
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),

                if (widget.onStartRun != null)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => widget.onStartRun!(widget.route),
                      icon: const Icon(
                        LucideIcons.playCircle,
                        color: Color(0xFFA7F3D0),
                      ), // emerald-200
                      label: const Text("START RUN"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669), // emerald-600
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                    ),
                  ),

                const SizedBox(height: 24),

                // Directions
                if (widget.route.directions != null &&
                    widget.route.directions!.isNotEmpty)
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF334155)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Theme(
                      data: Theme.of(
                        context,
                      ).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        title: const Row(
                          children: [
                            Icon(
                              LucideIcons.navigation,
                              size: 16,
                              color: Color(0xFF34D399),
                            ),
                            SizedBox(width: 8),
                            Text(
                              "Turn-by-Turn Directions",
                              style: TextStyle(
                                color: Color(0xFFE2E8F0),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        iconColor: const Color(0xFF94A3B8),
                        collapsedIconColor: const Color(0xFF94A3B8),
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            color: const Color(0x801E293B),
                            child: Column(
                              children: widget.route.directions!
                                  .asMap()
                                  .entries
                                  .map((entry) {
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 12,
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: 24,
                                            height: 24,
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF334155),
                                              borderRadius:
                                                  BorderRadius.circular(12),
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
                          ),
                        ],
                      ),
                    ),
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
                      WebViewWidget(controller: _controller),
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: _openExternalMap,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: const [BoxShadow(blurRadius: 2)],
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  LucideIcons.externalLink,
                                  size: 12,
                                  color: Color(0xFF0F172A),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  "Open in Maps",
                                  style: TextStyle(
                                    color: Color(0xFF0F172A),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                const Wrap(
                  spacing: 16,
                  children: [
                    Text(
                      "Sync with:",
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Strava",
                      style: TextStyle(
                        color: Color(0xFFF97316),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      "Runkeeper",
                      style: TextStyle(
                        color: Color(0xFF06B6D4),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      "Google Fit",
                      style: TextStyle(
                        color: Color(0xFF3B82F6),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
