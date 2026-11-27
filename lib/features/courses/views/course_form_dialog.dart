import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../models/course_model.dart';

// Diálogo modal para CREAR o EDITAR un curso
class CourseFormDialog extends StatefulWidget {
  final ApiClient apiClient;
  final CourseModel? course; // Si viene null es CREAR, si tiene datos es EDITAR

  const CourseFormDialog({super.key, required this.apiClient, this.course});

  @override
  State<CourseFormDialog> createState() => _CourseFormDialogState();
}

class _CourseFormDialogState extends State<CourseFormDialog> {
  final _formKey = GlobalKey<FormState>();

  int? _selectedGradeId;
  String _selectedLetra = 'A';
  final int _selectedYearId = 1; // Vigencia activa por defecto (ID 1)

  bool _cargandoGrados = true;
  bool _guardando = false;
  String? _error;

  List<Map<String, dynamic>> _grados = [];

  final List<String> _letras = ['A', 'B', 'C', 'D', 'E'];

  @override
  void initState() {
    super.initState();
    if (widget.course != null) {
      _selectedGradeId = widget.course!.gradeId;
      _selectedLetra = widget.course!.letra;
    }
    _cargarGrados();
  }

  Future<void> _cargarGrados() async {
    try {
      final raw = await widget.apiClient.getList('/grados');
      if (!mounted) return;
      setState(() {
        _grados = raw.whereType<Map<String, dynamic>>().toList();
        _cargandoGrados = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error al cargar lista de grados: $e';
        _cargandoGrados = false;
      });
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedGradeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona un grado')),
      );
      return;
    }

    setState(() => _guardando = true);

    // Campos requeridos por Flask: CUR_VIG_LETRA, CUR_VIG_VIG_ID, CUR_VIG_GRAD_ID
    final payload = {
      'CUR_VIG_LETRA': _selectedLetra,
      'CUR_VIG_VIG_ID': _selectedYearId,
      'CUR_VIG_GRAD_ID': _selectedGradeId,
    };

    try {
      if (widget.course == null) {
        // CREAR (POST)
        await widget.apiClient.post('/cursos-vigencia', payload);
      } else {
        // ACTUALIZAR (PUT por UUID)
        await widget.apiClient.put(
          '/cursos-vigencia/${widget.course!.uuid}',
          payload,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final esEdicion = widget.course != null;

    return AlertDialog(
      title: Text(
        esEdicion ? 'Editar Curso' : 'Nuevo Curso',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: AppTheme.azulOscuro,
        ),
      ),
      content: _cargandoGrados
          ? const SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator()),
            )
          : _error != null
          ? Text(_error!, style: const TextStyle(color: Colors.red))
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Selector de Grado (Ej: 10°, 11°)
                    const Text(
                      'Grado Escolar:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<int>(
                      initialValue: _selectedGradeId,
                      isExpanded: true,
                      hint: const Text('Seleccionar grado...'),
                      items: _grados.map((g) {
                        final nombre =
                            g['GRAD_NOMBRE']?.toString() ??
                            'Grado #${g['GRAD_ID']}';
                        final id = g['GRAD_ID'] as int?;
                        return DropdownMenuItem<int>(
                          value: id,
                          child: Text(nombre),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() => _selectedGradeId = val);
                      },
                      validator: (val) =>
                          val == null ? 'Selecciona un grado' : null,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Selector de Letra de Grupo (Ej: A, B, C)
                    const Text(
                      'Letra / Grupo:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedLetra,
                      items: _letras.map((letra) {
                        return DropdownMenuItem(
                          value: letra,
                          child: Text('Grupo $letra'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedLetra = val);
                      },
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      actions: [
        TextButton(
          onPressed: _guardando ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _guardando || _cargandoGrados ? null : _guardar,
          child: _guardando
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(esEdicion ? 'Actualizar' : 'Crear'),
        ),
      ],
    );
  }
}
