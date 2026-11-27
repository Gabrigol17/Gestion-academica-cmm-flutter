import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/api/api_client.dart';
import '../models/student_model.dart';

// ==========================================
// 1. EVENTOS (Lo que la pantalla pide hacer)
// ==========================================
abstract class StudentsEvent {}

class LoadStudentsEvent extends StudentsEvent {}

// ==========================================
// 2. ESTADOS (Cómo reacciona la pantalla)
// ==========================================
abstract class StudentsState {}

// Estado 1: Cargando datos
class StudentsLoading extends StudentsState {}

// Estado 2: Datos cargados exitosamente
class StudentsSuccess extends StudentsState {
  final List<StudentModel> students;
  StudentsSuccess(this.students);
}

// Estado 3: Ocurrió un error al cargar
class StudentsError extends StudentsState {
  final String message;
  StudentsError(this.message);
}

// ==========================================
// 3. EL BLOC (El intermediario / cerebro)
// ==========================================
class StudentsBloc extends Bloc<StudentsEvent, StudentsState> {
  final ApiClient apiClient;

  StudentsBloc({required this.apiClient}) : super(StudentsLoading()) {
    // Cuando se dispara el evento LoadStudentsEvent:
    on<LoadStudentsEvent>((event, emit) async {
      emit(StudentsLoading());

      try {
        // Consultamos estudiantes y personas al backend
        final estudiantesRaw = await apiClient.getList('/estudiantes');
        final personasRaw = await apiClient.getList('/personas');

        // Creamos un mapa rápido de personas por su ID para encontrarlas fácil
        // Ejemplo: { 5: { 'PER_ID': 5, 'PER_PRIMER_NOMBRE': 'Carlos', ... } }
        final mapaPersonas = <int, Map<String, dynamic>>{};
        for (final p in personasRaw) {
          if (p is Map<String, dynamic> && p['PER_ID'] != null) {
            mapaPersonas[p['PER_ID']] = p;
          }
        }

        // Construimos la lista de StudentModel cruzando cada estudiante con su persona
        final listaEstudiantes = <StudentModel>[];
        for (final est in estudiantesRaw) {
          if (est is Map<String, dynamic>) {
            final perId = est['EST_PER_ID'];
            final datosPersona = mapaPersonas[perId];
            listaEstudiantes.add(StudentModel.fromMaps(est, datosPersona));
          }
        }

        // Notificamos a la pantalla que los datos están listos
        emit(StudentsSuccess(listaEstudiantes));
      } catch (error) {
        // Si no hay internet o el server falló, notificamos el error
        emit(StudentsError(error.toString()));
      }
    });
  }
}
