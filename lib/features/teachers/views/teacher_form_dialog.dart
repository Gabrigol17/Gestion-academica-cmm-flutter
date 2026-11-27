import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../models/teacher_model.dart';

// Diálogo modal para CREAR o EDITAR un profesor
class TeacherFormDialog extends StatefulWidget {
  final ApiClient apiClient;
  final TeacherModel?
  teacher; // Si viene null es CREAR, si tiene datos es EDITAR

  const TeacherFormDialog({super.key, required this.apiClient, this.teacher});

  @override
  State<TeacherFormDialog> createState() => _TeacherFormDialogState();
}

class _TeacherFormDialogState extends State<TeacherFormDialog> {
  final _formKey = GlobalKey<FormState>();

  int? _selectedPersonId;
  int _selectedEstado = 1; // 1 = Activo, 0 = Inactivo

  bool _cargandoPersonas = true;
  bool _guardando = false;
  String? _error;

  List<Map<String, dynamic>> _personas = [];

  @override
  void initState() {
    super.initState();
    if (widget.teacher != null) {
      _selectedPersonId = widget.teacher!.personId;
      _selectedEstado = widget.teacher!.estado == 'Activo' ? 1 : 0;
    }
    _cargarPersonas();
  }

  Future<void> _cargarPersonas() async {
    try {
      final raw = await widget.apiClient.getList('/personas');
      if (!mounted) return;
      setState(() {
        _personas = raw.whereType<Map<String, dynamic>>().toList();
        _cargandoPersonas = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error al cargar lista de personas: $e';
        _cargandoPersonas = false;
      });
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPersonId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona una persona')),
      );
      return;
    }

    setState(() => _guardando = true);

    // Campos requeridos por Flask para DOCENTES: DOC_PER_ID y DOC_ESTADO
    final payload = {
      'DOC_PER_ID': _selectedPersonId,
      'DOC_ESTADO': _selectedEstado,
    };

    try {
      if (widget.teacher == null) {
        // CREAR (POST)
        await widget.apiClient.post('/docentes', payload);
      } else {
        // ACTUALIZAR (PUT por UUID)
        await widget.apiClient.put(
          '/docentes/${widget.teacher!.uuid}',
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
    final esEdicion = widget.teacher != null;

    return AlertDialog(
      title: Text(
        esEdicion ? 'Editar Profesor' : 'Nuevo Profesor',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: AppTheme.azulOscuro,
        ),
      ),
      content: _cargandoPersonas
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
                    // Selector de Persona
                    const Text(
                      'Persona:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<int>(
                      initialValue: _selectedPersonId,
                      isExpanded: true,
                      hint: const Text('Seleccionar persona...'),
                      items: _personas.map((p) {
                        final nombre = [
                          p['PER_PRIMER_NOMBRE'],
                          p['PER_PRIMER_APELLIDO'],
                        ].whereType<String>().join(' ');
                        final id = p['PER_ID'] as int?;
                        return DropdownMenuItem<int>(
                          value: id,
                          child: Text(nombre.isEmpty ? 'Persona #$id' : nombre),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() => _selectedPersonId = val);
                      },
                      validator: (val) =>
                          val == null ? 'Selecciona una persona' : null,
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

                    // Selector de Estado
                    const Text(
                      'Estado:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<int>(
                      initialValue: _selectedEstado,
                      items: const [
                        DropdownMenuItem(value: 1, child: Text('Activo')),
                        DropdownMenuItem(value: 0, child: Text('Inactivo')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedEstado = val);
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
          onPressed: _guardando || _cargandoPersonas ? null : _guardar,
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
