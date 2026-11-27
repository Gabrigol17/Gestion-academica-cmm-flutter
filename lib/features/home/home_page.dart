import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../students/views/students_page.dart';

class HomePage extends StatelessWidget {
  final ApiClient apiClient;

  const HomePage({super.key, required this.apiClient});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestión Académica CMM')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Bienvenido al Sistema',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.azulOscuro,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Selecciona un módulo para gestionar la información académica.',
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 24),

              // Opciones de los 3 módulos principales
              Expanded(
                child: ListView(
                  children: [
                    _ModuleCard(
                      icon: Icons.school_rounded,
                      title: 'Estudiantes',
                      subtitle: 'Consulta de alumnos matriculados y datos',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                StudentsPage(apiClient: apiClient),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    _ModuleCard(
                      icon: Icons.person_rounded,
                      title: 'Profesores',
                      subtitle: 'Directorio y estado de docentes',
                      onTap: () {
                        // Conectaremos el módulo de profesores
                      },
                    ),
                    const SizedBox(height: 14),
                    _ModuleCard(
                      icon: Icons.class_rounded,
                      title: 'Cursos',
                      subtitle: 'Grados y cursos asignados por vigencia',
                      onTap: () {
                        // Conectaremos el módulo de cursos
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Tarjeta individual para cada módulo en el menú
class _ModuleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ModuleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        leading: CircleAvatar(
          backgroundColor: AppTheme.azulPrimario.withValues(alpha: 0.1),
          foregroundColor: AppTheme.azulPrimario,
          child: Icon(icon),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 13, color: Colors.black54),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 16,
          color: Colors.grey,
        ),
        onTap: onTap,
      ),
    );
  }
}
