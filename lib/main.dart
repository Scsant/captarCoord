import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'components/action_buttons.dart';
import 'components/animated_gps_icon.dart';
import 'components/log_list_view.dart';
import 'components/status_card.dart';
import 'utils/file_helper.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GPS Logger',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.transparent,
        textTheme: GoogleFonts.interTextTheme(),
      ),
      home: const GPSTrackerScreen(),
    );
  }
}

class GPSTrackerScreen extends StatefulWidget {
  const GPSTrackerScreen({super.key});

  @override
  State<GPSTrackerScreen> createState() => _GPSTrackerScreenState();
}

class _GPSTrackerScreenState extends State<GPSTrackerScreen> {
  final List<Map<String, dynamic>> _gpsLog = [];
  StreamSubscription<Position>? _positionSubscription;
  bool _isTracking = false;
  bool _hasGpsFix = false;
  String? _statusMessage;
  DateTime? _startTime;

  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    await _requestLocationPermissions(forceDialog: true);
  }

  Future<void> _startTracking() async {
    final permissionGranted = await _requestLocationPermissions();
    if (!permissionGranted) {
      return;
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ative o serviço de localização.')),
        );
      }
      return;
    }

    _gpsLog.clear();
    _statusMessage = 'Inicializando GPS...';
    _hasGpsFix = false;
    _startTime = DateTime.now();

    setState(() {
      _isTracking = true;
    });

    await WakelockPlus.enable();
    await _positionSubscription?.cancel();

    final locationSettings = _buildLocationSettings();

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      _onNewPosition,
      onError: (error) {
        setState(() {
          _statusMessage = 'Erro de GPS: $error';
        });
      },
    );

    // Forçar uma leitura imediata para acelerar fixo inicial
    _obtainInitialFix();
  }

  Future<bool> _requestLocationPermissions({bool forceDialog = false}) async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied || forceDialog) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permissão negada. Autorize a localização.'),
          ),
        );
      }
      return false;
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Permissão negada permanentemente. Ative nas configurações.',
            ),
          ),
        );
      }
      await Geolocator.openAppSettings();
      return false;
    }

    if (_isAndroid) {
      await Permission.ignoreBatteryOptimizations.request();
      await Permission.notification.request();
    }

    return true;
  }

  Future<void> _obtainInitialFix() async {
    try {
      final firstPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
        timeLimit: const Duration(seconds: 15),
      );
      _onNewPosition(firstPosition);
    } catch (e) {
      setState(() {
        _statusMessage = 'Buscando sinal de GPS...';
      });
    }
  }

  LocationSettings _buildLocationSettings() {
    const base = LocationAccuracy.bestForNavigation;

    if (_isAndroid) {
      return AndroidSettings(
        accuracy: base,
        distanceFilter: 0,
        intervalDuration: const Duration(seconds: 1),
        forceLocationManager: true,
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'GPS Logger ativo',
          notificationText: 'Registrando coordenadas...',
          enableWakeLock: true,
          enableWifiLock: true,
          setOngoing: true,
        ),
      );
    }

    return const LocationSettings(
      accuracy: base,
      distanceFilter: 0,
    );
  }

  void _onNewPosition(Position position) {
    final record = {
      'ts': DateTime.now().toUtc().toIso8601String(),
      'lat': position.latitude,
      'lon': position.longitude,
      'speed_m_s': position.speed,
      'altitude': position.altitude,
      'heading': position.heading,
      'accuracy': position.accuracy,
    };

    setState(() {
      _gpsLog.add(record);
      _hasGpsFix = true;
      _statusMessage = null;
    });
  }

  Future<void> _stopTracking() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    await WakelockPlus.disable();

    setState(() {
      _isTracking = false;
      _statusMessage = null;
      _hasGpsFix = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Captura parada! ${_gpsLog.length} pontos registrados.',
          ),
        ),
      );
    }
  }

  Future<void> _saveLogToFile() async {
    if (_gpsLog.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nenhum ponto para exportar.')),
        );
      }
      return;
    }

    try {
      final jsonString = const JsonEncoder.withIndent('  ').convert(_gpsLog);
      final filename =
          'gps_log_${DateTime.now().millisecondsSinceEpoch}.json';

      if (kIsWeb) {
        await saveJsonToFile(jsonString, filename);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('JSON baixado com sucesso.')),
          );
        }
        return;
      }

      final filePath = await saveJsonToFile(jsonString, filename);
      final xFile = XFile(filePath, mimeType: 'application/json');

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('JSON salvo'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Arquivo:', style: GoogleFonts.inter()),
              const SizedBox(height: 8),
              Text(
                filePath,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Toque em compartilhar para salvar em Downloads, enviar por WhatsApp ou abrir com outro app.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.white54,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Share.shareXFiles(
                  [xFile],
                  subject: 'GPS Logger - Dados GPS',
                  text: 'Exportado em ${DateTime.now()}',
                );
              },
              icon: const Icon(Icons.share),
              label: const Text('Compartilhar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E5FF),
                foregroundColor: Colors.black,
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint('Erro ao salvar arquivo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e')),
        );
      }
    }
  }

  String _getDuration() {
    if (_startTime == null) return '00:00:00';
    final duration = DateTime.now().difference(_startTime!);
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.4,
            colors: [
              Color(0xFF0D0D3B),
              Color(0xFF1B004E),
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 700;
              if (isWide) {
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              _buildHeader(),
                              const SizedBox(height: 24),
                              StatusCard(
                                isActive: _isTracking,
                                points: _gpsLog.length,
                                duration: _getDuration(),
                                statusMessage: _statusMessage ??
                                    (_isTracking && !_hasGpsFix
                                        ? 'Buscando sinal de GPS...'
                                        : null),
                              ),
                              const SizedBox(height: 24),
                              ActionButtons(
                                isTracking: _isTracking,
                                canExport: _gpsLog.isNotEmpty,
                                onStart: _startTracking,
                                onStop: _stopTracking,
                                onExport: _saveLogToFile,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        flex: 3,
                        child: LogListView(records: _gpsLog),
                      ),
                    ],
                  ),
                );
              }

              final screenHeight = MediaQuery.of(context).size.height;
              return ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  StatusCard(
                    isActive: _isTracking,
                    points: _gpsLog.length,
                    duration: _getDuration(),
                    statusMessage: _statusMessage ??
                        (_isTracking && !_hasGpsFix
                            ? 'Buscando sinal de GPS...'
                            : null),
                  ),
                  const SizedBox(height: 24),
                  ActionButtons(
                    isTracking: _isTracking,
                    canExport: _gpsLog.isNotEmpty,
                    onStart: _startTracking,
                    onStop: _stopTracking,
                    onExport: _saveLogToFile,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: screenHeight * 0.35,
                    child: LogListView(records: _gpsLog),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        AnimatedGpsIcon(isActive: _isTracking, size: 42),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'GPS Logger',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _isTracking
                    ? 'Capturando coordenadas em tempo real'
                    : 'Pronto para iniciar a captura',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
