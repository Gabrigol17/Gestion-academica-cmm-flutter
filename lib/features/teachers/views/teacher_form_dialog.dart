import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../models/teacher_model.dart';

// Diálogo modal para VINCULAR o EDITAR un profesor
class TeacherFormDialog extends StatefulWidget {
  final ApiClient apiClient;
  final TeacherModel?
  teacher; // Si viene null es VINCULAR, si tiene datos es EDITAR

  const TeacherFormDialog({super.key, required this.apiClient, this.teacher});

  @override
  State<TeacherFormDialog> createState() => _TeacherFormDialogState();
}

class _TeacherFormDialogState extends State<TeacherFormDialog> {
  final _formKey = GlobalKey<FormState>();

  int? _selectedPersonId;
  int _selectedEstado = 1; // Inicia activo por defecto

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
      _cargandoPersonas = false;
    } else {
      _cargarPersonas();
    }
  }

  Future<void> _cargarPersonas() async {
    try {
      final personasRaw = await widget.apiClient.getList('/personas');
      final docentesRaw = await widget.apiClient.getList('/docentes');

      final idsOcupados = <int>{};
      for (final d in docentesRaw) {
        if (d is Map<String, dynamic> && d['DOC_PER_ID'] != null) {
          idsOcupados.add(d['DOC_PER_ID'] as int);
        }
      }

      if (!mounted) return;
      setState(() {
        _personas = personasRaw
            .whereType<Map<String, dynamic>>()
            .where((p) => !idsOcupados.contains(p['PER_ID']))
            .toList();
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

    final payload = {
      'DOC_PER_ID': _selectedPersonId,
      'DOC_ESTADO': _selectedEstado,
    };

    try {
      if (widget.teacher == null) {
        await widget.apiClient.post('/docentes', payload);
      } else {
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
        esEdicion ? 'Actualizar Estado de Docente' : 'Vincular Docente',
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
                    if (!esEdicion) ...[
                      const Text(
                        'Selecciona una persona registrada para asignarle el rol de docente:',
                        style: TextStyle(fontSize: 13, color: Colors.black54),
                      ),
                      const SizedBox(height: 14),
                    ],
                    const Text(
                      'Persona:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),

                    if (esEdicion)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.bordeGris),
                        ),
                        child: Text(
                          widget.teacher!.nombreCompleto,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      )
                    else
                      _personas.isEmpty
                          ? Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.amber.shade300,
                                ),
                              ),
                              child: const Text(
                                'Todas las personas registradas ya tienen un rol asignado.',
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 13,
                                ),
                              ),
                            )
                          : DropdownButtonFormField<int>(
                              value: _selectedPersonId,
                              isExpanded: true,
                              hint: const Text(
                                'Buscar y seleccionar persona...',
                              ),
                              items: _personas.map((p) {
                                final nombre = [
                                  p['PER_PRIMER_NOMBRE'],
                                  p['PER_PRIMER_APELLIDO'],
                                ].whereType<String>().join(' ');
                                final doc = p['PER_NUMERO_DOCUMENTO'] ?? '';
                                final id = p['PER_ID'] as int?;
                                final etiqueta = doc.toString().isNotEmpty
                                    ? '$nombre (Doc: $doc)'
                                    : nombre;
                                return DropdownMenuItem<int>(
                                  value: id,
                                  child: Text(etiqueta),
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

                    if (esEdicion) ...[
                      const Text(
                        'Estado:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<int>(
                        value: _selectedEstado,
                        items: const [
                          DropdownMenuItem(value: 1, child: Text('Activo')),
                          DropdownMenuItem(value: 0, child: Text('Inactivo')),
                        ],
                        onChanged: (val) {
                          if (val != null)
                            setState(() => _selectedEstado = val);
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
                    ] else ...[
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 18,
                            color: Colors.green.shade700,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Iniciará con estado: Activo',
                            style: TextStyle(
                              color: Colors.green.shade800,
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
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
          onPressed:
              _guardando ||
                  _cargandoPersonas ||
                  (!esEdicion && _personas.isEmpty)
              ? null
              : _guardar,
          child: _guardando
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(esEdicion ? 'Actualizar' : 'Vincular'),
        ),
      ],
    );
  }
}
