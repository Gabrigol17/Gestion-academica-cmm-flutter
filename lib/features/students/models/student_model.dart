class StudentModel {
  final int id;
  final String nombreCompleto;
  final String documento;
  final String correo;
  final String estado; // 'Activo' o 'Inactivo'

  StudentModel({
    required this.id,
    required this.nombreCompleto,
    required this.documento,
    required this.correo,
    required this.estado,
  });

  // Constructor factory: procesa los mapas de la API y crea un StudentModel limpio
  factory StudentModel.fromMaps(
    Map<String, dynamic> estudiante,
    Map<String, dynamic>? persona,
  ) {
    String nombre = 'Estudiante #${estudiante['EST_ID']}';
    String doc = 'Sin documento';
    String email = 'Sin correo';

    // Si encontramos la persona vinculada en T_PERSONA, armamos el nombre
    if (persona != null) {
      final partes = [
        persona['PER_PRIMER_NOMBRE'],
        persona['PER_SEGUNDO_NOMBRE'],
        persona['PER_PRIMER_APELLIDO'],
        persona['PER_SEGUNDO_APELLIDO'],
      ].where((p) => p != null && p.toString().trim().isNotEmpty).join(' ');

      if (partes.isNotEmpty) {
        nombre = partes;
      }
      doc = persona['PER_NUMERO_DOCUMENTO']?.toString() ?? 'Sin documento';
      email = persona['PER_CORREO_INSTITUCIONAL']?.toString() ?? 'Sin correo';
    }

    // Normalizamos el estado a 'Activo' o 'Inactivo'
    final rawEstado = estudiante['EST_ESTADO_INSTITUCIONAL'];
    final estadoTexto =
        (rawEstado == 1 || rawEstado == '1' || rawEstado == 'Activo')
        ? 'Activo'
        : 'Inactivo';

    return StudentModel(
      id: estudiante['EST_ID'] ?? 0,
      nombreCompleto: nombre,
      documento: doc,
      correo: email,
      estado: estadoTexto,
    );
  }
}
