import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

// Widget reutilizable para cuando la pantalla está cargando datos
class LoadingWidget extends StatelessWidget {
  final String? mensaje;

  const LoadingWidget({super.key, this.mensaje});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppTheme.azulPrimario),
          if (mensaje != null) ...[
            const SizedBox(height: 12),
            Text(
              mensaje!,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ],
      ),
    );
  }
}

// Widget reutilizable para cuando ocurre un error al consultar la API
class ErrorStateWidget extends StatelessWidget {
  final String mensaje;
  final VoidCallback onRetry;

  const ErrorStateWidget({
    super.key,
    required this.mensaje,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 54,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 12),
            const Text(
              'No se pudo cargar la información',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54, fontSize: 13),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
