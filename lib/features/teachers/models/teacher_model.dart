class TeacherModel {
  final int id;
  final String uuid;
  final int personId;
  final String nombreCompleto;
  final String documento;
  final String correo;
  final String estado; // 'Activo' o 'Inactivo'

  TeacherModel({
    required this.id,
    required this.uuid,
    required this.personId,
    required this.nombreCompleto,
    required this.documento,
    required this.correo,
    required this.estado,
  });

  // Constructor factory: cruza el mapa de T_DOCENTE con el de T_PERSONA
  factory TeacherModel.fromMaps(
    Map<String, dynamic> docente,
    Map<String, dynamic>? persona,
  ) {
    String nombre = 'Docente #${docente['DOC_ID']}';
    String doc = 'Sin documento';
    String email = 'Sin correo';

    // Si encontramos la persona asociada en T_PERSONA
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
    final rawEstado = docente['DOC_ESTADO'];
    final estadoTexto =
        (rawEstado == 1 || rawEstado == '1' || rawEstado == 'Activo')
        ? 'Activo'
        : 'Inactivo';

    return TeacherModel(
      id: docente['DOC_ID'] ?? 0,
      uuid: docente['DOC_UUID']?.toString() ?? '',
      personId: docente['DOC_PER_ID'] ?? 0,
      nombreCompleto: nombre,
      documento: doc,
      correo: email,
      estado: estadoTexto,
    );
  }
}
