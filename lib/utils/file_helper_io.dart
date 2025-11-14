import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show Platform;

Future<String> saveJsonToFile(String jsonString, String filename) async {
  Directory directory;
  
  if (Platform.isAndroid) {
    // No Android, usar getExternalStorageDirectory que aponta para /storage/emulated/0/
    // e depois navegar para Downloads
    try {
      final externalStorage = await getExternalStorageDirectory();
      if (externalStorage != null) {
        // Subir para /storage/emulated/0/ e depois ir para Download
        final downloadPath = '/storage/emulated/0/Download';
        final downloadDir = Directory(downloadPath);
        
        // Criar pasta Download se não existir
        if (!await downloadDir.exists()) {
          await downloadDir.create(recursive: true);
        }
        
        directory = downloadDir;
      } else {
        // Fallback para diretório do app
        directory = await getApplicationDocumentsDirectory();
      }
    } catch (e) {
      // Se falhar, tentar caminho alternativo
      try {
        // Tentar outros caminhos comuns
        final paths = [
          '/storage/emulated/0/Download',
          '/sdcard/Download',
          '/storage/sdcard0/Download',
        ];
        
        Directory? foundDir;
        for (final path in paths) {
          final dir = Directory(path);
          if (await dir.exists()) {
            foundDir = dir;
            break;
          }
        }
        
        directory = foundDir ?? await getApplicationDocumentsDirectory();
      } catch (e2) {
        // Último fallback
        directory = await getApplicationDocumentsDirectory();
      }
    }
  } else if (Platform.isIOS) {
    // No iOS, usar diretório de documentos (acessível via Files app)
    directory = await getApplicationDocumentsDirectory();
  } else {
    // Desktop - usar Downloads do usuário
    final userHome = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '';
    if (userHome.isNotEmpty) {
      final downloadsDir = Directory('$userHome/Downloads');
      if (await downloadsDir.exists()) {
        directory = downloadsDir;
      } else {
        directory = await getApplicationDocumentsDirectory();
      }
    } else {
      directory = await getApplicationDocumentsDirectory();
    }
  }
  
  final file = File('${directory.path}/$filename');
  await file.writeAsString(jsonString);
  
  // Retornar caminho amigável para o usuário
  if (Platform.isAndroid && directory.path.contains('Download')) {
    return 'Downloads/$filename';
  }
  
  return file.path;
}

