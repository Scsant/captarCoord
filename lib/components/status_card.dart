import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StatusCard extends StatelessWidget {
  final bool isActive;
  final int points;
  final String duration;
  final String? statusMessage;

  const StatusCard({
    Key? key,
    required this.isActive,
    required this.points,
    required this.duration,
    this.statusMessage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive 
            ? const Color(0xFF00E5FF).withOpacity(0.3)
            : const Color(0xFFFF4081).withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: (isActive ? const Color(0xFF00E5FF) : const Color(0xFFFF4081))
              .withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          // Status indicator com animação
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Semantics(
                label: isActive ? 'Status: Capturando GPS' : 'Status: Parado',
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive ? const Color(0xFF00E5FF) : const Color(0xFFFF4081),
                    boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: const Color(0xFF00E5FF).withOpacity(0.6),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isActive ? const Color(0xFF00E5FF) : const Color(0xFFFF4081),
                ),
                child: Text(isActive ? 'CAPTURANDO' : 'PARADO'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (statusMessage != null) ...[
            Text(
              statusMessage!,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 18),
          ],
          // Estatísticas
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                icon: Icons.location_on,
                label: 'Pontos',
                value: points.toString(),
                color: Colors.white70,
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withOpacity(0.2),
              ),
              _buildStatItem(
                icon: Icons.timer,
                label: 'Tempo',
                value: duration,
                color: Colors.white70,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: color,
          ),
        ),
      ],
    );
  }
}

