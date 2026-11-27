import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../bloc/students_bloc.dart';
import '../models/student_model.dart';
import 'student_form_dialog.dart';

// Pantalla principal del módulo de estudiantes
class StudentsPage extends StatelessWidget {
  final ApiClient apiClient;

  const StudentsPage({super.key, required this.apiClient});

  @override
  Widget build(BuildContext context) {
    // Proveemos el StudentsBloc a la vista y disparamos la carga inicial
    return BlocProvider(
      create: (context) =>
          StudentsBloc(apiClient: apiClient)..add(LoadStudentsEvent()),
      child: _StudentsView(apiClient: apiClient),
    );
  }
}

// Vista interna que maneja el estado del buscador y renderiza según el BLoC
class _StudentsView extends StatefulWidget {
  final ApiClient apiClient;

  const _StudentsView({required this.apiClient});

  @override
  State<_StudentsView> createState() => _StudentsViewState();
}

class _StudentsViewState extends State<_StudentsView> {
  final TextEditingController _searchController = TextEditingController();
  String _filtroTexto = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // 1. Abrir diálogo para CREAR un nuevo estudiante
  Future<void> _abrirCrear() async {
    final creado = await showDialog<bool>(
      context: context,
      builder: (_) => StudentFormDialog(apiClient: widget.apiClient),
    );

    if (creado == true && mounted) {
      context.read<StudentsBloc>().add(LoadStudentsEvent());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Estudiante creado exitosamente')),
      );
    }
  }

  // 2. Abrir diálogo para EDITAR un estudiante existente
  Future<void> _abrirEditar(StudentModel student) async {
    final actualizado = await showDialog<bool>(
      context: context,
      builder: (_) =>
          StudentFormDialog(apiClient: widget.apiClient, student: student),
    );

    if (actualizado == true && mounted) {
      context.read<StudentsBloc>().add(LoadStudentsEvent());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Estudiante actualizado exitosamente')),
      );
    }
  }

  // 3. Confirmar y ELIMINAR estudiante
  Future<void> _confirmarEliminar(StudentModel student) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Estudiante'),
        content: Text(
          '¿Seguro que deseas eliminar a ${student.nombreCompleto}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true && mounted) {
      try {
        await widget.apiClient.delete('/estudiantes/${student.uuid}');
        if (!mounted) return;
        context.read<StudentsBloc>().add(LoadStudentsEvent());
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Estudiante eliminado')));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Directorio de Estudiantes')),
      floatingActionButton: FloatingActionButton(
        onPressed: _abrirCrear,
        backgroundColor: AppTheme.azulPrimario,
        foregroundColor: Colors.white,
        tooltip: 'Nuevo Estudiante',
        child: const Icon(Icons.add),
      ),
      body: BlocBuilder<StudentsBloc, StudentsState>(
        builder: (context, state) {
          // 1. Estado Cargando
          if (state is StudentsLoading) {
            return const LoadingWidget(mensaje: 'Consultando estudiantes...');
          }

          // 2. Estado Error
          if (state is StudentsError) {
            return ErrorStateWidget(
              mensaje: state.message,
              onRetry: () {
                context.read<StudentsBloc>().add(LoadStudentsEvent());
              },
            );
          }

          // 3. Estado Éxito
          if (state is StudentsSuccess) {
            final estudiantesFiltrados = state.students.where((est) {
              final nombre = est.nombreCompleto.toLowerCase();
              final doc = est.documento.toLowerCase();
              final busqueda = _filtroTexto.toLowerCase();
              return nombre.contains(busqueda) || doc.contains(busqueda);
            }).toList();

            return Column(
              children: [
                // Barra de búsqueda por nombre o documento
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (valor) {
                      setState(() {
                        _filtroTexto = valor.trim();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Buscar por nombre o documento...',
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppTheme.azulPrimario,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppTheme.bordeGris),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppTheme.bordeGris),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),

                // Contador de registros encontrados
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${estudiantesFiltrados.length} ${estudiantesFiltrados.length == 1 ? 'estudiante encontrado' : 'estudiantes encontrados'}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Lista de estudiantes
                Expanded(
                  child: estudiantesFiltrados.isEmpty
                      ? const Center(
                          child: Text(
                            'No se encontraron estudiantes',
                            style: TextStyle(color: Colors.grey, fontSize: 15),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                          itemCount: estudiantesFiltrados.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final estudiante = estudiantesFiltrados[index];
                            return _StudentCard(
                              student: estudiante,
                              onEdit: () => _abrirEditar(estudiante),
                              onDelete: () => _confirmarEliminar(estudiante),
                            );
                          },
                        ),
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

// Tarjeta individual para mostrar datos de cada estudiante
class _StudentCard extends StatelessWidget {
  final StudentModel student;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _StudentCard({
    required this.student,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final bool esActivo = student.estado == 'Activo';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icono del estudiante
                CircleAvatar(
                  backgroundColor: AppTheme.azulPrimario.withValues(alpha: 0.1),
                  foregroundColor: AppTheme.azulPrimario,
                  child: const Icon(Icons.person_outline),
                ),
                const SizedBox(width: 14),

                // Información del estudiante
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.nombreCompleto,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Doc: ${student.documento}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        student.correo,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),

                // Insignia (Chip) de estado institucional
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: esActivo
                        ? Colors.green.shade50
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: esActivo
                          ? Colors.green.shade300
                          : Colors.grey.shade400,
                    ),
                  ),
                  child: Text(
                    student.estado,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: esActivo
                          ? Colors.green.shade800
                          : Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20, thickness: 0.5),

            // Botones de acción: Editar y Eliminar
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Editar'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.azulPrimario,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Eliminar'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
