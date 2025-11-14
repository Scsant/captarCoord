import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LogListView extends StatelessWidget {
  final List<Map<String, dynamic>> records;

  const LogListView({
    Key? key,
    required this.records,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off,
              size: 48,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhum registro ainda',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
          ],
        ),
      );
    }

    // Mostrar apenas os últimos 10 registros
    final recentRecords = records.length > 10 
      ? records.sublist(records.length - 10)
      : records;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(
                  Icons.location_on,
                  color: Color(0xFF00E5FF),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Últimos registros',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E5FF).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${records.length}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF00E5FF),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white24),
          // Lista
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: recentRecords.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final record = recentRecords[recentRecords.length - 1 - index];
                return _buildLogItem(record);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogItem(Map<String, dynamic> record) {
    final ts = record['ts'] as String? ?? '';
    final lat = record['lat'] as double? ?? 0.0;
    final lon = record['lon'] as double? ?? 0.0;
    final speed = record['speed_m_s'] as double? ?? 0.0;
    final alt = record['altitude'] as double? ?? 0.0;

    // Formatar timestamp
    DateTime? dateTime;
    try {
      dateTime = DateTime.parse(ts);
    } catch (e) {
      // Ignorar erro de parsing
    }

    final timeStr = dateTime != null
      ? '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}'
      : '--:--:--';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timestamp
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: 14,
                color: Colors.white.withOpacity(0.6),
              ),
              const SizedBox(width: 6),
              Text(
                timeStr,
                style: GoogleFonts.robotoMono(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Coordenadas
          Row(
            children: [
              Expanded(
                child: _buildInfoChip(
                  'Lat',
                  lat.toStringAsFixed(6),
                  Icons.my_location,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildInfoChip(
                  'Lon',
                  lon.toStringAsFixed(6),
                  Icons.explore,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Speed e Altitude
          Row(
            children: [
              Expanded(
                child: _buildInfoChip(
                  'Speed',
                  '${speed.toStringAsFixed(2)} m/s',
                  Icons.speed,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildInfoChip(
                  'Alt',
                  '${alt.toStringAsFixed(1)}m',
                  Icons.height,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.white.withOpacity(0.5)),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.robotoMono(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}




