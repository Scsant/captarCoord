import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'models/coordinate.dart';
import 'services/coordinate_service.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GPS - Operações Agrícolas',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: CoordinateCaptureScreen(),
    );
  }
}

class CoordinateCaptureScreen extends StatefulWidget {
  @override
  _CoordinateCaptureScreenState createState() => _CoordinateCaptureScreenState();
}

class _CoordinateCaptureScreenState extends State<CoordinateCaptureScreen> {
  final CoordinateService _coordinateService = CoordinateService();
  final _talhaoController = TextEditingController();
  final _projetoController = TextEditingController();
  final _operacaoController = TextEditingController();
  final _operadorController = TextEditingController();
  final _produtoController = TextEditingController();
  final _observacoesController = TextEditingController();
  
  List<Coordinate> _coordinates = [];
  bool _isLoading = false;
  bool _isTracking = false;
  Timer? _trackingTimer;
  int _trackingCount = 0;

  @override
  void initState() {
    super.initState();
    _loadCoordinates();
  }

  @override
  void dispose() {
    _trackingTimer?.cancel();
    _talhaoController.dispose();
    _projetoController.dispose();
    _operacaoController.dispose();
    _operadorController.dispose();
    _produtoController.dispose();
    _observacoesController.dispose();
    super.dispose();
  }

  Future<void> _loadCoordinates() async {
    setState(() => _isLoading = true);
    final coordinates = await _coordinateService.getAllCoordinates();
    setState(() {
      _coordinates = coordinates;
      _isLoading = false;
    });
  }

  Future<void> _captureCoordinate() async {
    // Validar campos obrigatórios
    if (_talhaoController.text.isEmpty ||
        _projetoController.text.isEmpty ||
        _operacaoController.text.isEmpty ||
        _operadorController.text.isEmpty ||
        _produtoController.text.isEmpty) {
      _showSnackBar('Preencha todos os campos obrigatórios!');
      return;
    }

    setState(() => _isLoading = true);
    
    final coordinate = await _coordinateService.captureCurrentLocation(
      talhao: _talhaoController.text,
      projeto: _projetoController.text,
      operacao: _operacaoController.text,
      operador: _operadorController.text,
      produto: _produtoController.text,
      observacoes: _observacoesController.text.isEmpty ? null : _observacoesController.text,
    );

    if (coordinate != null) {
      _showSnackBar('Coordenada capturada: ${coordinate.latitude.toStringAsFixed(6)}, ${coordinate.longitude.toStringAsFixed(6)}');
      _observacoesController.clear(); // Limpar apenas observações
      await _loadCoordinates();
    } else {
      _showSnackBar('Erro ao capturar coordenada. Verifique as permissões do GPS.');
    }
  }

  Future<void> _startAutoTracking() async {
    // Validar campos obrigatórios
    if (_talhaoController.text.isEmpty ||
        _projetoController.text.isEmpty ||
        _operacaoController.text.isEmpty ||
        _operadorController.text.isEmpty ||
        _produtoController.text.isEmpty) {
      _showSnackBar('Preencha todos os campos obrigatórios antes de iniciar o tracking!');
      return;
    }

    setState(() {
      _isTracking = true;
      _trackingCount = 0;
    });

    // Capturar primeira coordenada imediatamente
    await _captureAutoCoordinate();

    // Configurar timer para capturar a cada 2 minutos (120 segundos)
    _trackingTimer = Timer.periodic(Duration(minutes: 2), (timer) async {
      await _captureAutoCoordinate();
    });

    _showSnackBar('Tracking automático iniciado! Capturando a cada 2 minutos.');
  }

  Future<void> _stopAutoTracking() async {
    _trackingTimer?.cancel();
    setState(() {
      _isTracking = false;
    });
    _showSnackBar('Tracking automático parado. Total capturado: $_trackingCount pontos.');
  }

  Future<void> _captureAutoCoordinate() async {
    try {
      final coordinate = await _coordinateService.captureCurrentLocation(
        talhao: _talhaoController.text,
        projeto: _projetoController.text,
        operacao: _operacaoController.text,
        operador: _operadorController.text,
        produto: _produtoController.text,
        observacoes: _observacoesController.text.isEmpty ? null : _observacoesController.text,
      );

      if (coordinate != null) {
        setState(() {
          _trackingCount++;
        });
        
        // Atualizar lista de coordenadas
        await _loadCoordinates();
        
        print('Coordenada automática capturada: ${coordinate.latitude.toStringAsFixed(6)}, ${coordinate.longitude.toStringAsFixed(6)}');
      }
    } catch (e) {
      print('Erro na captura automática: $e');
    }
  }

  Future<void> _exportToJson() async {
    if (_coordinates.isEmpty) {
      _showSnackBar('Nenhuma coordenada para exportar!');
      return;
    }

    try {
      final exportData = {
        'export_date': DateTime.now().toIso8601String(),
        'total_coordinates': _coordinates.length,
        'coordinates': _coordinates.map((c) => c.toJson()).toList(),
      };

      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/coordinates_${DateTime.now().millisecondsSinceEpoch}.json');
      await file.writeAsString(jsonEncode(exportData));

      _showSnackBar('JSON exportado: ${file.path}');
    } catch (e) {
      _showSnackBar('Erro ao exportar: $e');
    }
  }

  Future<void> _deleteCoordinate(String id) async {
    await _coordinateService.deleteCoordinate(id);
    await _loadCoordinates();
    _showSnackBar('Coordenada removida');
  }

  Future<void> _deleteAllCoordinates() async {
    final confirmed = await _showConfirmDialog(
      'Confirmar exclusão',
      'Deseja remover todas as coordenadas?',
    );
    
    if (confirmed == true) {
      await _coordinateService.deleteAllCoordinates();
      await _loadCoordinates();
      _showSnackBar('Todas as coordenadas foram removidas');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<bool?> _showConfirmDialog(String title, String content) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('GPS - Operações Agrícolas'),
        backgroundColor: Colors.blue[700],
        actions: [
          IconButton(
            onPressed: _exportToJson,
            icon: Icon(Icons.download),
            tooltip: 'Exportar JSON',
          ),
          IconButton(
            onPressed: _deleteAllCoordinates,
            icon: Icon(Icons.delete_sweep),
            tooltip: 'Limpar todas',
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Formulário de captura
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Data atual (apenas informativa)
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, color: Colors.blue[700]),
                          SizedBox(width: 8),
                          Text(
                            'Data: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                    
                    // Talhão
                    TextField(
                      controller: _talhaoController,
                      decoration: InputDecoration(
                        labelText: 'Talhão *',
                        hintText: 'Ex: T001, T002, etc.',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.agriculture),
                      ),
                    ),
                    SizedBox(height: 12),
                    
                    // Projeto
                    TextField(
                      controller: _projetoController,
                      decoration: InputDecoration(
                        labelText: 'Projeto *',
                        hintText: 'Nome do projeto',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.folder),
                      ),
                    ),
                    SizedBox(height: 12),
                    
                    // Operação
                    TextField(
                      controller: _operacaoController,
                      decoration: InputDecoration(
                        labelText: 'Operação *',
                        hintText: 'Ex: Plantio, Colheita, Pulverização',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.build),
                      ),
                    ),
                    SizedBox(height: 12),
                    
                    // Operador
                    TextField(
                      controller: _operadorController,
                      decoration: InputDecoration(
                        labelText: 'Operador *',
                        hintText: 'Nome do operador',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    SizedBox(height: 12),
                    
                    // Produto
                    TextField(
                      controller: _produtoController,
                      decoration: InputDecoration(
                        labelText: 'Produto *',
                        hintText: 'Nome do produto utilizado',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.inventory),
                      ),
                    ),
                    SizedBox(height: 12),
                    
                    // Observações
                    TextField(
                      controller: _observacoesController,
                      decoration: InputDecoration(
                        labelText: 'Observações (opcional)',
                        hintText: 'Informações adicionais',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.note),
                      ),
                      maxLines: 2,
                    ),
                    SizedBox(height: 16),
                    
                    // Status do tracking
                    if (_isTracking)
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green[300]!),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.gps_fixed, color: Colors.green[700]),
                                SizedBox(width: 8),
                                Text(
                                  'TRACKING ATIVO',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[700],
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '$_trackingCount pontos',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    SizedBox(height: 16),
                    
                    // Botões de controle
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isLoading || _isTracking ? null : _captureCoordinate,
                            icon: Icon(Icons.my_location),
                            label: Text('Captura Manual'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : (_isTracking ? _stopAutoTracking : _startAutoTracking),
                            icon: Icon(_isTracking ? Icons.stop : Icons.play_arrow),
                            label: Text(_isTracking ? 'Parar Auto' : 'Iniciar Auto'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isTracking ? Colors.red : Colors.green,
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 8),
                    
                    // Informação sobre tracking automático
                    if (!_isTracking)
                      Text(
                        'Auto: Captura a cada 2 minutos automaticamente',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 16),
            
            // Lista de coordenadas
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : _coordinates.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.location_off, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'Nenhuma coordenada capturada',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Use o formulário acima para capturar coordenadas',
                                style: TextStyle(color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _coordinates.length,
                          itemBuilder: (context, index) {
                            final coord = _coordinates[index];
                            return Card(
                              margin: EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: Icon(Icons.place, color: Colors.blue),
                                title: Text('${coord.talhao} - ${coord.operacao}'),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Projeto: ${coord.projeto}'),
                                    Text('Operador: ${coord.operador}'),
                                    Text('Produto: ${coord.produto}'),
                                    Text('Lat: ${coord.latitude.toStringAsFixed(6)}'),
                                    Text('Lng: ${coord.longitude.toStringAsFixed(6)}'),
                                    if (coord.observacoes != null)
                                      Text('Obs: ${coord.observacoes}'),
                                    Text(
                                      '${coord.timestamp.day}/${coord.timestamp.month}/${coord.timestamp.year} ${coord.timestamp.hour}:${coord.timestamp.minute.toString().padLeft(2, '0')}',
                                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                                trailing: IconButton(
                                  onPressed: () => _deleteCoordinate(coord.id),
                                  icon: Icon(Icons.delete, color: Colors.red),
                                ),
                              ),
                            );
                          },
                        ),
            ),
            
            // Resumo
            if (_coordinates.isNotEmpty)
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('${_coordinates.length}', style: TextStyle(fontSize: 18, color: Colors.blue[700])),
                      ],
                    ),
                    Column(
                      children: [
                        Text('Última captura', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                          '${_coordinates.first.timestamp.day}/${_coordinates.first.timestamp.month}',
                          style: TextStyle(fontSize: 18, color: Colors.blue[700]),
                        ),
                      ],
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