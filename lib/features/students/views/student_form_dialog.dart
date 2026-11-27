import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../models/student_model.dart';

// Diálogo modal para VINCULAR o EDITAR un estudiante
class StudentFormDialog extends StatefulWidget {
  final ApiClient apiClient;
  final StudentModel?
  student; // Si viene null es VINCULAR NUEVO, si tiene datos es EDITAR

  const StudentFormDialog({super.key, required this.apiClient, this.student});

  @override
  State<StudentFormDialog> createState() => _StudentFormDialogState();
}

class _StudentFormDialogState extends State<StudentFormDialog> {
  final _formKey = GlobalKey<FormState>();

  int? _selectedPersonId;
  int _selectedEstado =
      1; // Por defecto siempre inicia en 1 (Activo) al crearse

  bool _cargandoPersonas = true;
  bool _guardando = false;
  String? _error;

  List<Map<String, dynamic>> _personas = [];

  @override
  void initState() {
    super.initState();
    if (widget.student != null) {
      _selectedPersonId = widget.student!.personId;
      _selectedEstado = widget.student!.estado == 'Activo' ? 1 : 0;
      _cargandoPersonas = false;
    } else {
      _cargarPersonas();
    }
  }

  // Obtenemos la lista de personas que aún no han sido vinculadas como estudiantes
  Future<void> _cargarPersonas() async {
    try {
      final personasRaw = await widget.apiClient.getList('/personas');
      final estudiantesRaw = await widget.apiClient.getList('/estudiantes');

      final idsOcupados = <int>{};
      for (final e in estudiantesRaw) {
        if (e is Map<String, dynamic> && e['EST_PER_ID'] != null) {
          idsOcupados.add(e['EST_PER_ID'] as int);
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
      'EST_PER_ID': _selectedPersonId,
      'EST_ESTADO_INSTITUCIONAL': _selectedEstado,
    };

    try {
      if (widget.student == null) {
        await widget.apiClient.post('/estudiantes', payload);
      } else {
        await widget.apiClient.put(
          '/estudiantes/${widget.student!.uuid}',
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
    final esEdicion = widget.student != null;

    return AlertDialog(
      title: Text(
        esEdicion ? 'Actualizar Estado de Estudiante' : 'Vincular Estudiante',
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
                    // Texto explicativo en modo creación
                    if (!esEdicion) ...[
                      const Text(
                        'Selecciona una persona registrada en la institución para asignarle el rol de estudiante activo:',
                        style: TextStyle(fontSize: 13, color: Colors.black54),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Persona a vincular
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
                          widget.student!.nombreCompleto,
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

                    // En creación no molestamos al usuario con el estado (se asigna 'Activo' por defecto)
                    // En edición sí permitimos cambiar entre Activo e Inactivo
                    if (esEdicion) ...[
                      const Text(
                        'Estado Institucional:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<int>(
                        value: _selectedEstado,
                        items: const [
                          DropdownMenuItem(
                            value: 1,
                            child: Text('Activo (Matriculado)'),
                          ),
                          DropdownMenuItem(
                            value: 0,
                            child: Text('Inactivo (Retirado / Egresado)'),
                          ),
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
                      // Indicador informativo de que inicia Activo
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
