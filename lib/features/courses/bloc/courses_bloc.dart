import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/api/api_client.dart';
import '../models/course_model.dart';

// ==========================================
// 1. EVENTOS (Cursos)
// ==========================================
abstract class CoursesEvent {}

class LoadCoursesEvent extends CoursesEvent {}

// ==========================================
// 2. ESTADOS (Cursos)
// ==========================================
abstract class CoursesState {}

class CoursesLoading extends CoursesState {}

class CoursesSuccess extends CoursesState {
  final List<CourseModel> courses;
  CoursesSuccess(this.courses);
}

class CoursesError extends CoursesState {
  final String message;
  CoursesError(this.message);
}

// ==========================================
// 3. EL BLOC (CoursesBloc)
// ==========================================
class CoursesBloc extends Bloc<CoursesEvent, CoursesState> {
  final ApiClient apiClient;

  CoursesBloc({required this.apiClient}) : super(CoursesLoading()) {
    on<LoadCoursesEvent>((event, emit) async {
      emit(CoursesLoading());

      try {
        // Consultamos los cursos y los grados para poder mostrar el nombre real
        final cursosRaw = await apiClient.getList('/cursos-vigencia');
        final gradosRaw = await apiClient.getList('/grados');

        // Mapeamos los grados por su ID
        final mapaGrados = <int, Map<String, dynamic>>{};
        for (final g in gradosRaw) {
          if (g is Map<String, dynamic> && g['GRAD_ID'] != null) {
            mapaGrados[g['GRAD_ID']] = g;
          }
        }

        // Cruzamos cada curso con su grado
        final listaCursos = <CourseModel>[];
        for (final cur in cursosRaw) {
          if (cur is Map<String, dynamic>) {
            final gradId = cur['CUR_VIG_GRAD_ID'];
            final datosGrado = mapaGrados[gradId];
            listaCursos.add(CourseModel.fromMaps(cur, datosGrado));
          }
        }

        emit(CoursesSuccess(listaCursos));
      } catch (error) {
        emit(CoursesError(error.toString()));
      }
    });
  }
}
