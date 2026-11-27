import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../bloc/teachers_bloc.dart';
import '../models/teacher_model.dart';
import 'teacher_form_dialog.dart';

// Pantalla principal del módulo de profesores
class TeachersPage extends StatelessWidget {
  final ApiClient apiClient;

  const TeachersPage({super.key, required this.apiClient});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          TeachersBloc(apiClient: apiClient)..add(LoadTeachersEvent()),
      child: _TeachersView(apiClient: apiClient),
    );
  }
}

class _TeachersView extends StatefulWidget {
  final ApiClient apiClient;

  const _TeachersView({required this.apiClient});

  @override
  State<_TeachersView> createState() => _TeachersViewState();
}

class _TeachersViewState extends State<_TeachersView> {
  final TextEditingController _searchController = TextEditingController();
  String _filtroTexto = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // 1. Abrir diálogo para CREAR un nuevo docente
  Future<void> _abrirCrear() async {
    final creado = await showDialog<bool>(
      context: context,
      builder: (_) => TeacherFormDialog(apiClient: widget.apiClient),
    );

    if (creado == true && mounted) {
      context.read<TeachersBloc>().add(LoadTeachersEvent());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profesor creado exitosamente')),
      );
    }
  }

  // 2. Abrir diálogo para EDITAR un docente existente
  Future<void> _abrirEditar(TeacherModel teacher) async {
    final actualizado = await showDialog<bool>(
      context: context,
      builder: (_) =>
          TeacherFormDialog(apiClient: widget.apiClient, teacher: teacher),
    );

    if (actualizado == true && mounted) {
      context.read<TeachersBloc>().add(LoadTeachersEvent());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profesor actualizado exitosamente')),
      );
    }
  }

  // 3. Confirmar y ELIMINAR docente
  Future<void> _confirmarEliminar(TeacherModel teacher) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Profesor'),
        content: Text(
          '¿Seguro que deseas eliminar a ${teacher.nombreCompleto}?',
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
        await widget.apiClient.delete('/docentes/${teacher.uuid}');
        if (!mounted) return;
        context.read<TeachersBloc>().add(LoadTeachersEvent());
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Profesor eliminado')));
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
      appBar: AppBar(title: const Text('Directorio de Profesores')),
      floatingActionButton: FloatingActionButton(
        onPressed: _abrirCrear,
        backgroundColor: AppTheme.azulPrimario,
        foregroundColor: Colors.white,
        tooltip: 'Nuevo Profesor',
        child: const Icon(Icons.add),
      ),
      body: BlocBuilder<TeachersBloc, TeachersState>(
        builder: (context, state) {
          // 1. Estado Cargando
          if (state is TeachersLoading) {
            return const LoadingWidget(mensaje: 'Consultando profesores...');
          }

          // 2. Estado Error
          if (state is TeachersError) {
            return ErrorStateWidget(
              mensaje: state.message,
              onRetry: () {
                context.read<TeachersBloc>().add(LoadTeachersEvent());
              },
            );
          }

          // 3. Estado Éxito
          if (state is TeachersSuccess) {
            final profesoresFiltrados = state.teachers.where((doc) {
              final nombre = doc.nombreCompleto.toLowerCase();
              final numDoc = doc.documento.toLowerCase();
              final busqueda = _filtroTexto.toLowerCase();
              return nombre.contains(busqueda) || numDoc.contains(busqueda);
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
                      hintText: 'Buscar profesor por nombre o documento...',
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
                      '${profesoresFiltrados.length} ${profesoresFiltrados.length == 1 ? 'profesor encontrado' : 'profesores encontrados'}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Lista de profesores
                Expanded(
                  child: profesoresFiltrados.isEmpty
                      ? const Center(
                          child: Text(
                            'No se encontraron profesores',
                            style: TextStyle(color: Colors.grey, fontSize: 15),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                          itemCount: profesoresFiltrados.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final profe = profesoresFiltrados[index];
                            return _TeacherCard(
                              teacher: profe,
                              onEdit: () => _abrirEditar(profe),
                              onDelete: () => _confirmarEliminar(profe),
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

// Tarjeta individual para cada profesor
class _TeacherCard extends StatelessWidget {
  final TeacherModel teacher;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TeacherCard({
    required this.teacher,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final bool esActivo = teacher.estado == 'Activo';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icono del docente
                CircleAvatar(
                  backgroundColor: AppTheme.azulPrimario.withValues(alpha: 0.1),
                  foregroundColor: AppTheme.azulPrimario,
                  child: const Icon(Icons.co_present_rounded),
                ),
                const SizedBox(width: 14),

                // Información
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        teacher.nombreCompleto,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Doc: ${teacher.documento}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        teacher.correo,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),

                // Insignia (Chip) de estado
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
                    teacher.estado,
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
