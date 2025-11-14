import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ActionButtons extends StatelessWidget {
  final bool isTracking;
  final bool canExport;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onExport;

  const ActionButtons({
    Key? key,
    required this.isTracking,
    required this.canExport,
    required this.onStart,
    required this.onStop,
    required this.onExport,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: _buildStartButton(enabled: !isTracking)),
            const SizedBox(width: 16),
            Expanded(child: _buildStopButton(enabled: isTracking)),
          ],
        ),
        const SizedBox(height: 16),
        // Botão Exportar
        OutlinedButton.icon(
          onPressed: canExport ? onExport : null,
          icon: const Icon(Icons.download, size: 20),
          label: Text(
            'Exportar JSON',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFF00E5FF), width: 1.5),
            foregroundColor: const Color(0xFF00E5FF),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStartButton({required bool enabled}) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00E5FF), Color(0xFF0099CC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E5FF).withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: enabled ? onStart : null,
        icon: Semantics(
          label: 'Iniciar captura GPS',
          child: const Icon(Icons.play_arrow, size: 24),
        ),
        label: Text(
          'Iniciar',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }

  Widget _buildStopButton({required bool enabled}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFF4081),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF4081).withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: enabled ? onStop : null,
        icon: Semantics(
          label: 'Parar captura GPS',
          child: const Icon(Icons.stop, size: 24),
        ),
        label: Text(
          'Parar',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }
}

