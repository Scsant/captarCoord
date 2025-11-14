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
  Timer? _clockTimer;
  bool _isTracking = false;
  bool _hasGpsFix = false;
  String? _statusMessage;
  DateTime? _startTime;
  DateTime? _lastCaptureTime;

  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  void initState() {
    super.initState();
    debugPrint('[GPS] ========== APP INICIADO ==========');
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    await _requestLocationPermissions(forceDialog: true);
  }

  Future<void> _startTracking() async {
    debugPrint('[GPS] Iniciando tracking...');

    final permissionGranted = await _requestLocationPermissions();
    if (!permissionGranted) {
      debugPrint('[GPS] Permissão negada');
      return;
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    debugPrint('[GPS] Serviço de localização: ${serviceEnabled ? "ATIVADO" : "DESATIVADO"}');

    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Ative o GPS nas configurações do dispositivo!'),
            duration: Duration(seconds: 5),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    _gpsLog.clear();
    _statusMessage = 'Inicializando GPS...';
    _hasGpsFix = false;
    _startTime = DateTime.now();
    _lastCaptureTime = null;

    setState(() {
      _isTracking = true;
    });

    debugPrint('[GPS] Habilitando wakelock...');
    await WakelockPlus.enable();
    await _positionSubscription?.cancel();
    _clockTimer?.cancel();

    // Timer para atualizar o relógio a cada segundo
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _isTracking) {
        setState(() {
          // Apenas atualiza o relógio, forçando rebuild
        });
      }
    });

    final locationSettings = _buildLocationSettings();
    debugPrint('[GPS] Configurações: $locationSettings');

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      _onNewPosition,
      onError: (error) {
        debugPrint('[GPS] ERRO no stream: $error');
        setState(() {
          _statusMessage = 'Erro de GPS: $error';
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao capturar GPS: $error'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
    );

    // Forçar uma leitura imediata para acelerar fixo inicial
    debugPrint('[GPS] Solicitando posição inicial...');
    _obtainInitialFix();
  }

  Future<bool> _requestLocationPermissions({bool forceDialog = false}) async {
    LocationPermission permission = await Geolocator.checkPermission();
    debugPrint('[GPS] Permissão atual: $permission');

    if (permission == LocationPermission.denied || forceDialog) {
      debugPrint('[GPS] Solicitando permissão...');
      permission = await Geolocator.requestPermission();
      debugPrint('[GPS] Nova permissão: $permission');
    }

    if (permission == LocationPermission.denied) {
      debugPrint('[GPS] Permissão NEGADA pelo usuário');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Permissão negada. Autorize a localização.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('[GPS] Permissão negada PERMANENTEMENTE');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '❌ Permissão negada permanentemente. Ative nas configurações.',
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
      await Geolocator.openAppSettings();
      return false;
    }

    debugPrint('[GPS] Permissão CONCEDIDA: $permission');

    if (_isAndroid) {
      debugPrint('[GPS] Solicitando permissões adicionais do Android...');
      final batteryOptimization = await Permission.ignoreBatteryOptimizations.request();
      final notification = await Permission.notification.request();
      debugPrint('[GPS] Battery optimization: $batteryOptimization, Notification: $notification');
    }

    return true;
  }

  Future<void> _obtainInitialFix() async {
    try {
      debugPrint('[GPS] Aguardando primeira posição (timeout: 15s)...');
      final firstPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
        timeLimit: const Duration(seconds: 15),
      );
      debugPrint('[GPS] ✅ Primeira posição obtida: lat=${firstPosition.latitude}, lon=${firstPosition.longitude}, acc=${firstPosition.accuracy}m');
      _onNewPosition(firstPosition);
    } catch (e) {
      debugPrint('[GPS] ⚠️ Primeira posição falhou: $e');
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
        intervalDuration: const Duration(seconds: 30), // 30 segundos entre capturas
        forceLocationManager: true,
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'GPS Logger ativo',
          notificationText: 'Registrando coordenadas a cada 30 segundos',
          enableWakeLock: true,
          enableWifiLock: true,
          setOngoing: true,
        ),
      );
    }

    return const LocationSettings(
      accuracy: base,
      distanceFilter: 0,
      timeLimit: const Duration(seconds: 30), // 30 segundos entre capturas
    );
  }

  void _onNewPosition(Position position) {
    final now = DateTime.now();
    final record = {
      'ts': now.toUtc().toIso8601String(),
      'lat': position.latitude,
      'lon': position.longitude,
      'speed_m_s': position.speed,
      'altitude': position.altitude,
      'heading': position.heading,
      'accuracy': position.accuracy,
    };

    debugPrint('[GPS] 📍 Nova posição #${_gpsLog.length + 1}: lat=${position.latitude.toStringAsFixed(6)}, lon=${position.longitude.toStringAsFixed(6)}, acc=${position.accuracy.toStringAsFixed(1)}m');

    _lastCaptureTime = now;

    // Otimização: só atualiza a UI se necessário
    if (!_hasGpsFix || _statusMessage != null) {
      setState(() {
        _gpsLog.add(record);
        _hasGpsFix = true;
        _statusMessage = null;
      });
    } else {
      // Não precisa setState - apenas adiciona ao log
      _gpsLog.add(record);
      // O Timer já está atualizando a UI a cada segundo
    }
  }

  Future<void> _stopTracking() async {
    debugPrint('[GPS] Parando tracking...');
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    _clockTimer?.cancel();
    _clockTimer = null;
    await WakelockPlus.disable();

    setState(() {
      _isTracking = false;
      _statusMessage = null;
      _hasGpsFix = false;
      _lastCaptureTime = null;
    });

    debugPrint('[GPS] Tracking parado. Total de pontos: ${_gpsLog.length}');

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

  String? _getNextCaptureInfo() {
    if (!_isTracking || _lastCaptureTime == null) return null;

    final now = DateTime.now();
    final elapsed = now.difference(_lastCaptureTime!).inSeconds;
    final remaining = 30 - elapsed;

    if (remaining <= 0) {
      return 'Próxima captura: aguardando GPS...';
    }

    return 'Próxima captura em ${remaining}s';
  }

  @override
  void dispose() {
    debugPrint('[GPS] Dispose - limpando recursos...');
    _positionSubscription?.cancel();
    _clockTimer?.cancel();
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
                                nextCaptureInfo: _getNextCaptureInfo(),
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
                    nextCaptureInfo: _getNextCaptureInfo(),
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
