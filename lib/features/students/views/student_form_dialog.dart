import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../models/student_model.dart';

// Diálogo modal para CREAR o EDITAR un estudiante
class StudentFormDialog extends StatefulWidget {
  final ApiClient apiClient;
  final StudentModel?
  student; // Si viene null es CREAR, si viene con datos es EDITAR

  const StudentFormDialog({super.key, required this.apiClient, this.student});

  @override
  State<StudentFormDialog> createState() => _StudentFormDialogState();
}

class _StudentFormDialogState extends State<StudentFormDialog> {
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
    // Si estamos editando, precargamos los valores actuales
    if (widget.student != null) {
      _selectedPersonId = widget.student!.personId;
      _selectedEstado = widget.student!.estado == 'Activo' ? 1 : 0;
    }
    _cargarPersonas();
  }

  // Obtenemos la lista de personas para poblar el Dropdown
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

  // Función para guardar (POST si es nuevo, PUT si es edición)
  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPersonId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona una persona')),
      );
      return;
    }

    setState(() => _guardando = true);

    final payload = {
      'EST_PER_ID': _selectedPersonId,
      'EST_ESTADO_INSTITUCIONAL': _selectedEstado,
    };

    try {
      if (widget.student == null) {
        // CREAR (POST)
        await widget.apiClient.post('/estudiantes', payload);
      } else {
        // ACTUALIZAR (PUT por UUID)
        await widget.apiClient.put(
          '/estudiantes/${widget.student!.uuid}',
          payload,
        );
      }

      if (!mounted) return;
      Navigator.of(context)
          .pop(true); // Retorna true para indicar que hubo éxito
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _guardando = false;
      });
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
    final esEdicion = widget.student != null;

    return AlertDialog(
      title: Text(
        esEdicion ? 'Editar Estudiante' : 'Nuevo Estudiante',
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

                    // Selector de Estado Institucional
                    const Text(
                      'Estado Institucional:',
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
