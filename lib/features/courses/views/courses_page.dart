import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../bloc/courses_bloc.dart';
import '../models/course_model.dart';
import 'course_form_dialog.dart';

// Pantalla principal del módulo de cursos
class CoursesPage extends StatelessWidget {
  final ApiClient apiClient;

  const CoursesPage({super.key, required this.apiClient});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          CoursesBloc(apiClient: apiClient)..add(LoadCoursesEvent()),
      child: _CoursesView(apiClient: apiClient),
    );
  }
}

class _CoursesView extends StatefulWidget {
  final ApiClient apiClient;

  const _CoursesView({required this.apiClient});

  @override
  State<_CoursesView> createState() => _CoursesViewState();
}

class _CoursesViewState extends State<_CoursesView> {
  final TextEditingController _searchController = TextEditingController();
  String _filtroTexto = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // 1. CREAR curso
  Future<void> _abrirCrear() async {
    final creado = await showDialog<bool>(
      context: context,
      builder: (_) => CourseFormDialog(apiClient: widget.apiClient),
    );

    if (creado == true && mounted) {
      context.read<CoursesBloc>().add(LoadCoursesEvent());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Curso creado exitosamente')),
      );
    }
  }

  // 2. EDITAR curso
  Future<void> _abrirEditar(CourseModel course) async {
    final actualizado = await showDialog<bool>(
      context: context,
      builder: (_) =>
          CourseFormDialog(apiClient: widget.apiClient, course: course),
    );

    if (actualizado == true && mounted) {
      context.read<CoursesBloc>().add(LoadCoursesEvent());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Curso actualizado exitosamente')),
      );
    }
  }

  // 3. ELIMINAR curso
  Future<void> _confirmarEliminar(CourseModel course) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Curso'),
        content: Text('¿Seguro que deseas eliminar ${course.nombreCompleto}?'),
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
        await widget.apiClient.delete('/cursos-vigencia/${course.uuid}');
        if (!mounted) return;
        context.read<CoursesBloc>().add(LoadCoursesEvent());
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Curso eliminado')));
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
      appBar: AppBar(title: const Text('Estructura de Cursos')),
      floatingActionButton: FloatingActionButton(
        onPressed: _abrirCrear,
        backgroundColor: AppTheme.azulPrimario,
        foregroundColor: Colors.white,
        tooltip: 'Nuevo Curso',
        child: const Icon(Icons.add),
      ),
      body: BlocBuilder<CoursesBloc, CoursesState>(
        builder: (context, state) {
          // 1. Estado Cargando
          if (state is CoursesLoading) {
            return const LoadingWidget(mensaje: 'Consultando cursos...');
          }

          // 2. Estado Error
          if (state is CoursesError) {
            return ErrorStateWidget(
              mensaje: state.message,
              onRetry: () {
                context.read<CoursesBloc>().add(LoadCoursesEvent());
              },
            );
          }

          // 3. Estado Éxito
          if (state is CoursesSuccess) {
            final cursosFiltrados = state.courses.where((c) {
              final nombre = c.nombreCompleto.toLowerCase();
              final busqueda = _filtroTexto.toLowerCase();
              return nombre.contains(busqueda);
            }).toList();

            return Column(
              children: [
                // Barra de búsqueda por nombre de curso
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
                      hintText: 'Buscar por grado o grupo...',
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
                      '${cursosFiltrados.length} ${cursosFiltrados.length == 1 ? 'curso registrado' : 'cursos registrados'}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Lista de cursos
                Expanded(
                  child: cursosFiltrados.isEmpty
                      ? const Center(
                          child: Text(
                            'No se encontraron cursos',
                            style: TextStyle(color: Colors.grey, fontSize: 15),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                          itemCount: cursosFiltrados.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final curso = cursosFiltrados[index];
                            return _CourseCard(
                              course: curso,
                              onEdit: () => _abrirEditar(curso),
                              onDelete: () => _confirmarEliminar(curso),
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

// Tarjeta individual para cada curso
class _CourseCard extends StatelessWidget {
  final CourseModel course;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CourseCard({
    required this.course,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          children: [
            Row(
              children: [
                // Icono de aula / grupo
                CircleAvatar(
                  backgroundColor: AppTheme.azulPrimario.withValues(alpha: 0.1),
                  foregroundColor: AppTheme.azulPrimario,
                  child: const Icon(Icons.class_outlined),
                ),
                const SizedBox(width: 14),

                // Información
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.nombreCompleto,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Letra: ${course.letra} · Vigencia ID #${course.yearId}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),
                    ],
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
