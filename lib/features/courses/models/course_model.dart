class CourseModel {
  final int id;
  final String uuid;
  final String letra;
  final int gradeId;
  final int yearId;
  final String nombreCompleto; // Ej: "10° - Grupo A"

  CourseModel({
    required this.id,
    required this.uuid,
    required this.letra,
    required this.gradeId,
    required this.yearId,
    required this.nombreCompleto,
  });

  // Constructor factory: cruza el mapa de T_CURSO_VIGENCIA con el de T_GRADO
  factory CourseModel.fromMaps(
    Map<String, dynamic> curso,
    Map<String, dynamic>? grado,
  ) {
    final letra = curso['CUR_VIG_LETRA']?.toString().trim() ?? 'A';
    final gradoNombre = grado?['GRAD_NOMBRE']?.toString().trim();

    final nombre = gradoNombre != null && gradoNombre.isNotEmpty
        ? '$gradoNombre - Grupo $letra'
        : 'Grado #${curso['CUR_VIG_GRAD_ID']} - Grupo $letra';

    return CourseModel(
      id: curso['CUR_VIG_ID'] ?? 0,
      uuid: curso['CUR_VIG_UUID']?.toString() ?? '',
      letra: letra,
      gradeId: curso['CUR_VIG_GRAD_ID'] ?? 0,
      yearId: curso['CUR_VIG_VIG_ID'] ?? 1,
      nombreCompleto: nombre,
    );
  }
}
