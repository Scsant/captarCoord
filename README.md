# App de Captura de Coordenadas GPS

Um aplicativo Flutter simples para capturar coordenadas GPS e exportar em formato JSON para análise posterior em Python.

## Funcionalidades

- 📍 Captura de coordenadas GPS em tempo real
- 🏷️ Sistema de tags para organizar pontos
- 📝 Descrições opcionais para cada coordenada
- 💾 Armazenamento local com SQLite
- 📤 Exportação em formato JSON
- 🗑️ Gerenciamento de coordenadas (visualizar, excluir)

## Como usar

### 1. Capturar coordenadas
- Digite uma tag (obrigatório) para identificar o ponto
- Adicione uma descrição opcional
- Toque em "Capturar Coordenada" para obter a localização atual

### 2. Visualizar coordenadas
- Todas as coordenadas são exibidas em uma lista
- Mostra latitude, longitude, tag, descrição e timestamp
- Permite excluir coordenadas individuais

### 3. Exportar dados
- Use o botão de download na AppBar para exportar todas as coordenadas
- O arquivo JSON é salvo no diretório de documentos do dispositivo
- Formato do JSON:
```json
{
  "export_date": "2024-01-01T12:00:00.000Z",
  "total_coordinates": 5,
  "coordinates": [
    {
      "id": "uuid",
      "latitude": -23.123456,
      "longitude": -46.654321,
      "accuracy": 5.0,
      "timestamp": "2024-01-01T12:00:00.000Z",
      "description": "Descrição opcional",
      "tag": "Ponto A"
    }
  ]
}
```

## Estrutura do projeto

```
lib/
├── models/
│   └── coordinate.dart          # Modelo de dados para coordenadas
├── services/
│   └── coordinate_service.dart  # Serviço para operações com coordenadas
└── flutter_gps_app.dart        # App principal
```

## Dependências principais

- `geolocator`: Para captura de coordenadas GPS
- `permission_handler`: Para gerenciar permissões
- `sqflite`: Para armazenamento local
- `path_provider`: Para acesso ao sistema de arquivos
- `uuid`: Para IDs únicos

## Próximos passos

1. Execute `flutter pub get` para instalar dependências
2. Execute `flutter run` para testar o app
3. Use as coordenadas exportadas em Python para gerar buffers

## Permissões necessárias

O app solicitará permissão de localização quando necessário para capturar coordenadas GPS.






