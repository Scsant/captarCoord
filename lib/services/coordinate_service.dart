import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:geolocator/geolocator.dart';
import '../models/coordinate.dart';

class CoordinateService {
  static final CoordinateService _instance = CoordinateService._internal();
  factory CoordinateService() => _instance;
  CoordinateService._internal();

  Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'coordinates.db');
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE coordinates (
            id TEXT PRIMARY KEY,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            accuracy REAL,
            timestamp TEXT NOT NULL,
            talhao TEXT NOT NULL,
            projeto TEXT NOT NULL,
            operacao TEXT NOT NULL,
            operador TEXT NOT NULL,
            produto TEXT NOT NULL,
            observacoes TEXT
          )
        ''');
        
        // Índices para performance
        await db.execute('CREATE INDEX idx_coordinates_timestamp ON coordinates (timestamp)');
        await db.execute('CREATE INDEX idx_coordinates_talhao ON coordinates (talhao)');
        await db.execute('CREATE INDEX idx_coordinates_projeto ON coordinates (projeto)');
        await db.execute('CREATE INDEX idx_coordinates_operacao ON coordinates (operacao)');
      },
    );
  }

  // Salvar coordenada
  Future<String> saveCoordinate(Coordinate coordinate) async {
    final db = await database;
    await db.insert('coordinates', coordinate.toMap());
    return coordinate.id;
  }

  // Capturar coordenada atual do GPS
  Future<Coordinate?> captureCurrentLocation({
    required String talhao,
    required String projeto,
    required String operacao,
    required String operador,
    required String produto,
    String? observacoes,
  }) async {
    try {
      // Verificar permissões
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      // Obter posição atual
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final coordinate = Coordinate(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        talhao: talhao,
        projeto: projeto,
        operacao: operacao,
        operador: operador,
        produto: produto,
        observacoes: observacoes,
      );

      await saveCoordinate(coordinate);
      return coordinate;
    } catch (e) {
      print('Erro ao capturar coordenada: $e');
      return null;
    }
  }

  // Buscar todas as coordenadas
  Future<List<Coordinate>> getAllCoordinates() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'coordinates',
      orderBy: 'timestamp DESC',
    );
    return List.generate(maps.length, (i) => Coordinate.fromMap(maps[i]));
  }

  // Deletar coordenada
  Future<void> deleteCoordinate(String id) async {
    final db = await database;
    await db.delete(
      'coordinates',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Deletar todas as coordenadas
  Future<void> deleteAllCoordinates() async {
    final db = await database;
    await db.delete('coordinates');
  }

  // Contar coordenadas
  Future<int> getCoordinateCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM coordinates');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}






