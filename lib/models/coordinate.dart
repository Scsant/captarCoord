import 'package:uuid/uuid.dart';

class Coordinate {
  final String id;
  final double latitude;
  final double longitude;
  final double? accuracy;
  final DateTime timestamp;
  final String talhao;
  final String projeto;
  final String operacao;
  final String operador;
  final String produto;
  final String? observacoes;

  Coordinate({
    String? id,
    required this.latitude,
    required this.longitude,
    this.accuracy,
    DateTime? timestamp,
    required this.talhao,
    required this.projeto,
    required this.operacao,
    required this.operador,
    required this.produto,
    this.observacoes,
  }) : id = id ?? const Uuid().v4(),
       timestamp = timestamp ?? DateTime.now();

  // Para SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'timestamp': timestamp.toIso8601String(),
      'talhao': talhao,
      'projeto': projeto,
      'operacao': operacao,
      'operador': operador,
      'produto': produto,
      'observacoes': observacoes,
    };
  }

  factory Coordinate.fromMap(Map<String, dynamic> map) {
    return Coordinate(
      id: map['id'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      accuracy: map['accuracy'],
      timestamp: DateTime.parse(map['timestamp']),
      talhao: map['talhao'],
      projeto: map['projeto'],
      operacao: map['operacao'],
      operador: map['operador'],
      produto: map['produto'],
      observacoes: map['observacoes'],
    );
  }

  // Para exportação JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'timestamp': timestamp.toIso8601String(),
      'talhao': talhao,
      'projeto': projeto,
      'operacao': operacao,
      'operador': operador,
      'produto': produto,
      'observacoes': observacoes,
    };
  }

  @override
  String toString() {
    return 'Coordinate(lat: $latitude, lng: $longitude, time: $timestamp)';
  }
}






