import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/api/api_client.dart';
import '../models/teacher_model.dart';

// ==========================================
// 1. EVENTOS (Profesores)
// ==========================================
abstract class TeachersEvent {}

class LoadTeachersEvent extends TeachersEvent {}

// ==========================================
// 2. ESTADOS (Profesores)
// ==========================================
abstract class TeachersState {}

class TeachersLoading extends TeachersState {}

class TeachersSuccess extends TeachersState {
  final List<TeacherModel> teachers;
  TeachersSuccess(this.teachers);
}

class TeachersError extends TeachersState {
  final String message;
  TeachersError(this.message);
}

// ==========================================
// 3. EL BLOC (TeachersBloc)
// ==========================================
class TeachersBloc extends Bloc<TeachersEvent, TeachersState> {
  final ApiClient apiClient;

  TeachersBloc({required this.apiClient}) : super(TeachersLoading()) {
    on<LoadTeachersEvent>((event, emit) async {
      emit(TeachersLoading());

      try {
        // Consultamos docentes y personas en paralelo
        final docentesRaw = await apiClient.getList('/docentes');
        final personasRaw = await apiClient.getList('/personas');

        // Mapeamos las personas por su ID para búsqueda rápida O(1)
        final mapaPersonas = <int, Map<String, dynamic>>{};
        for (final p in personasRaw) {
          if (p is Map<String, dynamic> && p['PER_ID'] != null) {
            mapaPersonas[p['PER_ID']] = p;
          }
        }

        // Cruzamos cada docente con sus datos personales
        final listaDocentes = <TeacherModel>[];
        for (final doc in docentesRaw) {
          if (doc is Map<String, dynamic>) {
            final perId = doc['DOC_PER_ID'];
            final datosPersona = mapaPersonas[perId];
            listaDocentes.add(TeacherModel.fromMaps(doc, datosPersona));
          }
        }

        emit(TeachersSuccess(listaDocentes));
      } catch (error) {
        emit(TeachersError(error.toString()));
      }
    });
  }
}
