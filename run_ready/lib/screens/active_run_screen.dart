import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../config/env.dart';
import '../models/route_data.dart' as models;
import '../models/run_session.dart';
import '../providers/route_provider.dart';

class ActiveRunScreen extends ConsumerStatefulWidget {
  final models.RouteData route;

  const ActiveRunScreen({super.key, required this.route});

  @override
  ConsumerState<ActiveRunScreen> createState() => _ActiveRunScreenState();
}

class _ActiveRunScreenState extends ConsumerState<ActiveRunScreen> {
  late FlutterTts _flutterTts;
  Timer? _timer;
  int _elapsedSeconds = 0;
  bool _isPaused = false;
  int _currentStep = 0;
  bool _isMuted = false;
  bool _showMap = false;
  late final WebViewController _mapController;

  @override
  void initState() {
    super.initState();
    _initTts();
    _startTimer();
    _initMap();
  }

  void _initTts() {
    _flutterTts = FlutterTts();
    _flutterTts.setLanguage("en-US");
    _speakCurrentStep();
  }

  void _initMap() {
    final apiKey = Env.googleMapsApiKey;
    String mapUrl;
    if (widget.route.mapData != null) {
      final saddr = Uri.encodeComponent(widget.route.mapData!.start);
      final daddr = Uri.encodeComponent(widget.route.mapData!.end);
      // Using embed API for consistency
      mapUrl =
          "https://www.google.com/maps/embed/v1/directions?key=$apiKey&origin=$saddr&destination=$daddr&waypoints=${widget.route.mapData!.waypoints.join('|')}&mode=walking";
    } else {
      final q = Uri.encodeComponent(
        "${widget.route.title} ${widget.route.preferences.customLocation ?? ''}",
      );
      mapUrl = "https://www.google.com/maps/embed/v1/search?key=$apiKey&q=$q";
    }

    _mapController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF1E293B))
      ..loadRequest(Uri.parse(mapUrl));
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused) {
        setState(() {
          _elapsedSeconds++;
        });
      }
    });
  }

  Future<void> _speakCurrentStep() async {
    if (_isMuted ||
        widget.route.directions == null ||
        widget.route.directions!.isEmpty)
      return;
    await _flutterTts.speak(widget.route.directions![_currentStep]);
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
    });
  }

  void _stopRun() {
    _timer?.cancel();
    final session = RunSession(
      routeId: widget.route.id,
      startTime:
          DateTime.now().millisecondsSinceEpoch - (_elapsedSeconds * 1000),
      endTime: DateTime.now().millisecondsSinceEpoch,
      durationSeconds: _elapsedSeconds,
      distance: widget.route.preferences.distance,
      unit: widget.route.preferences.unit,
    );

    ref.read(routeProvider.notifier).finishRun(session);
    context.pop(); // Go back

    // Show summary dialog or snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Run Finished! Stats saved.'),
        backgroundColor: Color(0xFF10B981),
      ),
    );
  }

  String _formatTime(int totalSeconds) {
    final hrs = totalSeconds ~/ 3600;
    final mins = (totalSeconds % 3600) ~/ 60;
    final secs = totalSeconds % 60;
    if (hrs > 0) {
      return '$hrs:${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final directions = widget.route.directions ?? ["Start your run!"];

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF1E293B),
                border: Border(bottom: BorderSide(color: Color(0xFF334155))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.route.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          _showMap ? LucideIcons.map : LucideIcons.map,
                          color: _showMap
                              ? const Color(0xFF34D399)
                              : const Color(0xFF94A3B8),
                        ),
                        onPressed: () => setState(() => _showMap = !_showMap),
                      ),
                      IconButton(
                        icon: Icon(
                          _isMuted ? LucideIcons.volumeX : LucideIcons.volume2,
                          color: _isMuted
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF34D399),
                        ),
                        onPressed: () => setState(() => _isMuted = !_isMuted),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Main Content
            Expanded(
              child: Stack(
                children: [
                  if (_showMap)
                    WebViewWidget(controller: _mapController)
                  else
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _formatTime(_elapsedSeconds),
                            style: const TextStyle(
                              fontSize: 80,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: 'monospace',
                            ),
                          ),
                          const Text(
                            'ELAPSED TIME',
                            style: TextStyle(
                              color: Color(0xFF10B981),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Directions Card
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: const BoxDecoration(
                        color: Color(0xFF1E293B),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 20,
                            offset: Offset(0, -5),
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
                                size: 12,
                                color: Color(0xFF34D399),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'CURRENT INSTRUCTION',
                                style: TextStyle(
                                  color: Color(0xFF34D399),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            directions[_currentStep],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton.filled(
                                onPressed: _currentStep > 0
                                    ? () {
                                        setState(() => _currentStep--);
                                        _speakCurrentStep();
                                      }
                                    : null,
                                icon: const Icon(LucideIcons.chevronLeft),
                                style: IconButton.styleFrom(
                                  backgroundColor: const Color(0xFF334155),
                                ),
                              ),
                              Text(
                                '${_currentStep + 1} / ${directions.length}',
                                style: const TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontFamily: 'monospace',
                                ),
                              ),
                              IconButton.filled(
                                onPressed: _currentStep < directions.length - 1
                                    ? () {
                                        setState(() => _currentStep++);
                                        _speakCurrentStep();
                                      }
                                    : null,
                                icon: const Icon(LucideIcons.chevronRight),
                                style: IconButton.styleFrom(
                                  backgroundColor:
                                      _currentStep == directions.length - 1
                                      ? const Color(0xFF059669)
                                      : const Color(0xFF334155),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Controls
            Container(
              padding: const EdgeInsets.all(24),
              color: const Color(0xFF020617),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _togglePause,
                      icon: Icon(
                        _isPaused ? LucideIcons.play : LucideIcons.pause,
                        color: _isPaused
                            ? const Color(0xFF34D399)
                            : const Color(0xFFFACC15),
                      ),
                      label: Text(_isPaused ? 'Resume' : 'Pause'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E293B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _stopRun,
                      icon: const Icon(
                        LucideIcons.stopCircle,
                        color: Color(0xFFF87171),
                      ),
                      label: const Text('Stop Run'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0x1AEF4444),
                        foregroundColor: const Color(0xFFF87171),
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
