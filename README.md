# Gestión Académica CMM · Flutter

Aplicación móvil de **gestión académica para el Colegio Madre Marcelina**, desarrollada como proyecto formativo del programa **ADSO del SENA**.

La app consume una API REST hecha en **Flask + MySQL** y permite administrar tres módulos principales: **Estudiantes**, **Profesores** y **Cursos**.

> Este documento está escrito pensando en alguien que está empezando en el mundo del código. Si nunca has tocado Flutter o no sabes qué es un "BLoC", aquí encontrarás las explicaciones paso a paso, con analogías y sin dar nada por obvio.

---

## Tabla de contenido

1. [¿Qué hace la aplicación hoy?](#1-qué-hace-la-aplicación-hoy)
2. [Tecnologías y librerías usadas (y por qué)](#2-tecnologías-y-librerías-usadas-y-por-qué)
3. [¿Por qué BLoC y no StatefulWidget?](#3-por-qué-bloc-y-no-statefulwidget)
4. [Cómo está organizado el proyecto](#4-cómo-está-organizado-el-proyecto)
5. [Los módulos explicados uno por uno](#5-los-módulos-explicados-uno-por-uno)
6. [Cómo se comunican la app y el backend](#6-cómo-se-comunican-la-app-y-el-backend)
7. [Cómo ejecutar el proyecto](#7-cómo-ejecutar-el-proyecto)
8. [Avances y correcciones realizadas](#8-avances-y-correcciones-realizadas)
9. [Qué sigue (pendientes)](#9-qué-sigue-pendientes)
10. [Glosario rápido](#10-glosario-rápido)

---

## 1. ¿Qué hace la aplicación hoy?

La app abre en una **pantalla de inicio** con tres tarjetas, una por módulo. Al tocar cualquiera se entra a su pantalla, donde se puede:

| Módulo | Qué se puede hacer | Pantalla |
|---|---|---|
| **Estudiantes** | Listar, buscar por nombre o documento, crear (vincular una persona), editar el estado (Activo/Inactivo) y eliminar | `Directorio de Estudiantes` |
| **Profesores** | Listar, buscar, crear (vincular una persona), editar el estado y eliminar | `Directorio de Profesores` |
| **Cursos** | Listar los grupos por grado y vigencia, crear, editar y eliminar, evitando duplicados | `Estructura de Cursos` |

En las tres pantallas se manejan los mismos cuatro estados de una petición real a un servidor:

- **Cargando** → aparece un spinner con un mensaje ("Consultando estudiantes...").
- **Éxito** → se muestra la lista de tarjetas.
- **Vacío** → "No se encontraron estudiantes" / "No se encontraron profesores" / "No se encontraron cursos".
- **Error** → un icono de nube desconectada, el mensaje del error y un botón **Reintentar**.

Además, después de crear, editar o eliminar, la lista **se recarga sola** y aparece un mensaje flotante (SnackBar) confirmando la acción.

---

## 2. Tecnologías y librerías usadas (y por qué)

### Flutter

Es el framework de Google con el que se construye la app. Se eligió porque con **un solo código en Dart** se puede compilar para Android, iOS, web y escritorio, y porque el programa ADSO trabaja con él.

### `flutter_bloc` — manejo de estado

Es la librería que organiza **de dónde salen los datos y cómo cambian**. Se eligió porque:

- Obliga a separar la **interfaz** (lo que se ve) de la **lógica** (las peticiones al servidor).
- Deja un historial claro de qué le pasó a la pantalla: primero *cargando*, luego *éxito* o *error*.
- Es un estándar de la industria: aparece en ofertas de trabajo y en la documentación oficial de Flutter.
- Facilita el trabajo en equipo: varias personas pueden tocar la pantalla y el BLoC sin pisarse el código.

### `http` — peticiones al backend

Permite hacer llamadas HTTP (`GET`, `POST`, `PUT`, `DELETE`) desde Dart. Se eligió por ser la opción **oficial y más simple** para consumir una API REST; no requiere configuración extra ni generación de código.

### `cupertino_icons`

Paquete de íconos con estilo iOS. Ya venía en la plantilla de Flutter y no afecta la lógica.

### `flutter_lints` (solo desarrollo)

Reglas que avisan cuando el código se está escribiendo de forma desordenada. **No se sube a la app final**, solo ayuda mientras se programa.

### Del lado del servidor (fuera de este repositorio)

- **Flask (Python)** → API REST que expone los datos.
- **MySQL** → base de datos relacional con las tablas del colegio.

---

## 3. ¿Por qué BLoC y no StatefulWidget?

Esta es la pregunta más importante del proyecto, así que vamos por partes.

### Primero: ¿qué es un estado?

El **estado** es toda la información que la pantalla necesita para dibujarse en un momento dado. Por ejemplo, en la pantalla de estudiantes:

- ¿Estamos cargando? → mostrar spinner.
- ¿Llegaron los datos? → mostrar tarjetas.
- ¿Hubo un error? → mostrar el mensaje rojo.

Cuando esa información cambia, la pantalla debe **volver a dibujarse**.

### Cómo lo haría un `StatefulWidget`

Un `StatefulWidget` es un widget que "recuerda" cosas y puede cambiar solo. Es perfecto para cosas pequeñas y locales. De hecho, **el proyecto sí usa `StatefulWidget`**, pero solo para lo que es realmente local:

- El texto que la persona escribe en el buscador (`_searchController`).
- La persona seleccionada en el formulario (`_selectedPersonId`).
- La letra del curso y el grado en el formulario.

El problema aparece cuando quieres usar `StatefulWidget` para **todo**, incluidas las peticiones al servidor:

```dart
// ❌ Versión ingenua con StatefulWidget
class StudentsPage extends StatefulWidget { ... }

class _StudentsPageState extends State<StudentsPage> {
  List<StudentModel> estudiantes = [];
  bool cargando = false;
  String? error;

  @override
  void initState() {
    super.initState();
    _cargar(); // mezcla lógica de red con la pantalla
  }
  ...
}
```

Esto funciona, pero trae problemas reales cuando el proyecto crece:

1. **La pantalla se vuelve gigante.** Termina con `setState`, `try/catch`, mapeo de datos y botones, todo en el mismo archivo.
2. **No se puede reutilizar la lógica.** Si otra pantalla necesita los estudiantes, hay que copiar y pegar la petición.
3. **Es difícil de probar.** Para probar la lógica hay que "montar" la pantalla completa.
4. **Estados imposibles.** Con tres variables sueltas (`cargando`, `error`, `estudiantes`) puedes terminar en combinaciones que no tienen sentido, por ejemplo `cargando = true` **y** `error != null` **y** la lista llena al mismo tiempo.
5. **Se mezclan dos tipos de estado.** El texto del buscador (temporal, de la pantalla) y la lista de estudiantes (del servidor, de negocio) viven revueltos.

### Cómo lo hace BLoC

BLoC significa **Business Logic Component** (componente de lógica de negocio). Es un patrón con tres piezas:

```
        EVENTO                  BLoC                    ESTADO
   "quiero cargar"  →  procesa la petición  →  "estoy cargando"
   (LoadStudentsEvent)   (llama a la API)      "listo, aquí están"
                                              "falló con este error"
```

Se lee así:

- **Evento**: algo que *pide* la pantalla. Es una clase vacía, sin lógica: `LoadStudentsEvent`.
- **Estado**: cómo está la pantalla en ese instante. Es una clase por cada situación: `StudentsLoading`, `StudentsSuccess`, `StudentsError`. **Solo puede existir uno a la vez**, así que los estados imposibles desaparecen.
- **BLoC**: el cerebro que recibe el evento, hace el trabajo (consultar el servidor, cruzar datos) y emite el estado.

En el código real del proyecto:

```dart
class StudentsBloc extends Bloc<StudentsEvent, StudentsState> {
  final ApiClient apiClient;

  StudentsBloc({required this.apiClient}) : super(StudentsLoading()) {
    on<LoadStudentsEvent>((event, emit) async {
      emit(StudentsLoading());              // 1. aviso: estoy cargando

      try {
        final estudiantesRaw = await apiClient.getList('/estudiantes');
        final personasRaw = await apiClient.getList('/personas');
        // ... se cruzan los datos ...
        emit(StudentsSuccess(listaEstudiantes)); // 2. aviso: listo
      } catch (error) {
        emit(StudentsError(error.toString()));   // 3. aviso: falló
      }
    });
  }
}
```

Y la pantalla solo *escucha* y *decide qué dibujar*:

```dart
BlocBuilder<StudentsBloc, StudentsState>(
  builder: (context, state) {
    if (state is StudentsLoading) return const LoadingWidget(...);
    if (state is StudentsError)   return ErrorStateWidget(...);
    if (state is StudentsSuccess) return ListView(...);
    return const SizedBox.shrink();
  },
)
```

### Comparación directa

| Aspecto | `StatefulWidget` para todo | BLoC |
|---|---|---|
| ¿Dónde vive la petición al servidor? | Dentro de la pantalla | En el BLoC (separado) |
| Tamaño del archivo de pantalla | Crece sin control | Se mantiene enfocado en la UI |
| Estados posibles | Muchos e inválidos | Uno a la vez, bien definidos |
| Reutilizar lógica en otra pantalla | Copiar y pegar | Se crea el mismo BLoC |
| Probar la lógica sin interfaz | Difícil | Sencillo (el BLoC es solo Dart) |
| Curva de aprendizaje | Baja | Media, pero es estándar |

### La regla que sigue este proyecto

> **BLoC para los datos que vienen del servidor. `StatefulWidget` para lo que solo le importa a esa pantalla.**

Por eso `StudentsPage` es un `StatelessWidget` que crea el BLoC y dentro tiene un `StatefulWidget` pequeño (`_StudentsView`) que solo guarda el texto del buscador. Lo mejor de ambos mundos.

### ¿Y qué hay de Provider, Riverpod o setState?

Son alternativas válidas. Se descartaron porque:

- **Provider** es más una herramienta de inyección de dependencias; no define por sí solo el flujo evento → estado.
- **Riverpod** es muy bueno, pero su modelo es más abstracto para alguien que empieza y el equipo ya iba a aprender un patrón nuevo de todos modos.
- **`setState` puro** es lo que intentamos evitar por los problemas de la lista anterior.

BLoC además es el patrón más documentado en el ecosistema Flutter en español, lo cual ayuda en un proyecto formativo.

---

## 4. Cómo está organizado el proyecto

```
lib/
├── main.dart                     # Punto de entrada: crea el ApiClient y arranca la app
├── app.dart                      # MaterialApp, tema y pantalla inicial
│
├── core/                         # Código compartido por todos los módulos
│   ├── api/
│   │   └── api_client.dart       # GET / POST / PUT / DELETE hacia Flask
│   ├── theme/
│   │   └── app_theme.dart        # Colores institucionales (azul y blanco)
│   └── widgets/
│       └── common_widgets.dart   # LoadingWidget y ErrorStateWidget reutilizables
│
└── features/                     # Un "feature" = un módulo de la app
    ├── home/
    │   └── home_page.dart        # Menú con las 3 tarjetas
    ├── students/
    │   ├── models/student_model.dart      # Datos limpios del estudiante
    │   ├── bloc/students_bloc.dart        # Eventos, estados y lógica
    │   └── views/students_page.dart       # Pantalla + diálogo de formulario
    ├── teachers/
    │   ├── models/teacher_model.dart
    │   ├── bloc/teachers_bloc.dart
    │   └── views/teachers_page.dart
    └── courses/
        ├── models/course_model.dart
        ├── bloc/courses_bloc.dart
        └── views/courses_page.dart
```

### ¿Por qué esta forma de carpetas?

Se llama **arquitectura por features (módulos)**. La idea es que todo lo de estudiantes (su modelo, su BLoC y su pantalla) viva junto. Así, cuando alguien pide "arregla el módulo de cursos", se sabe exactamente qué carpeta abrir y no hay que buscar en veinte lugares.

Dentro de cada módulo se repiten **tres capas**:

1. **`models/`** — traduce lo que llega del servidor a un objeto de Dart. Aquí vive el famoso `fromMaps`, que recibe dos tablas y arma un solo objeto con nombre, documento y correo.
2. **`bloc/`** — la lógica: qué pedir, cómo cruzarlo y qué estados emitir.
3. **`views/`** — la interfaz: tarjetas, buscador, botones y formularios.

La pantalla nunca habla directo con el servidor: **siempre pasa por el BLoC**, y el BLoC siempre pasa por el `ApiClient`. Esa cadena se llama *flujo unidireccional de datos* y es lo que hace fácil rastrear un error.

---

## 5. Los módulos explicados uno por uno

### 5.1 Estudiantes

**Pantalla:** `StudentsPage` → `Directorio de Estudiantes`

- Buscador en vivo por **nombre** o **documento**.
- Contador ("3 estudiantes encontrados").
- Cada tarjeta muestra nombre, documento, correo y una insignia verde/gris con el estado.
- Botones **Editar** y **Eliminar** en cada tarjeta.
- Botón flotante **+** para crear.

**¿Cómo se crea un estudiante?**
En la base de datos, un estudiante **no es una persona nueva**: es una persona que ya existe (en `T_PERSONA`) y a la que se le da el rol de estudiante. Por eso el formulario:

1. Consulta `/personas` y `/estudiantes`.
2. Quita de la lista las personas que ya tienen estudiante asignado.
3. Muestra un desplegable con las que quedan libres.
4. Al guardar, envía `POST /estudiantes` con `EST_PER_ID` y `EST_ESTADO_INSTITUCIONAL`.

En modo creación el estado se pone **Activo automáticamente** (no se le pregunta al usuario). En modo edición la persona queda fija y solo se puede cambiar el estado.

**¿Cómo se elimina?**
Pide confirmación y hace `DELETE /estudiantes/{uuid}`. Si MySQL responde con un error de *clave foránea* (porque el estudiante ya tiene matrículas o historial), la app no muestra el error técnico: explica en español que no se puede eliminar por tener registros vinculados.

### 5.2 Profesores

**Pantalla:** `TeachersPage` → `Directorio de Profesores`

Funciona igual que Estudiantes, con las mismas reglas y la misma experiencia, pero sobre las tablas `T_DOCENTE` y los endpoints `/docentes`. El formulario también filtra a las personas que ya son docentes para no duplicar roles. El estado se crea en **Activo**.

### 5.3 Cursos

**Pantalla:** `CoursesPage` → `Estructura de Cursos`

Un curso aquí es un **grupo** dentro de un grado y una vigencia (por ejemplo, "10° - Grupo A"). Por eso el BLoC cruza `/cursos-vigencia` con `/grados` para mostrar el nombre real del grado y no un número suelto.

El formulario permite elegir:

- El **grado**.
- La **letra** del grupo.
- La **vigencia** (año).

**Validación importante:** antes de guardar revisa que no exista ya ese mismo grado con esa misma letra. Si existe, muestra un aviso naranja ("Ya existe un curso con el Grupo A para este grado") y no llama al servidor. En edición se ignora el registro que se está editando para no marcarlo como duplicado de sí mismo.

### 5.4 Inicio

`HomePage` solo presenta las tres tarjetas y navega con `Navigator.push`. Cada tarjeta recibe el `ApiClient` y se lo pasa al módulo correspondiente, de modo que toda la app comparte la misma configuración de red.

---

## 6. Cómo se comunican la app y el backend

Todo pasa por `lib/core/api/api_client.dart`, que ofrece cuatro métodos:

| Método | Uso | Ejemplo |
|---|---|---|
| `getList(endpoint)` | Traer una lista | `getList('/estudiantes')` |
| `post(endpoint, body)` | Crear | `post('/docentes', {...})` |
| `put(endpoint, body)` | Actualizar | `put('/estudiantes/$uuid', {...})` |
| `delete(endpoint)` | Eliminar | `delete('/cursos-vigencia/$uuid')` |

Detalles que conviene conocer:

- Todas las peticiones tienen un **tiempo máximo de 10 segundos**. Si el servidor no responde, se lanza un error que el BLoC convierte en `...Error` y la pantalla ofrece **Reintentar**.
- Se envía y recibe **JSON en UTF-8**, para que tildes y eñes se vean correctamente.
- Los `PUT` y `DELETE` usan el **UUID** del registro, no el ID numérico.

### Endpoints usados

| Endpoint | Módulo |
|---|---|
| `/personas` | Estudiantes y Profesores (datos personales) |
| `/estudiantes` | Estudiantes |
| `/docentes` | Profesores |
| `/cursos-vigencia` | Cursos |
| `/grados` | Cursos (nombre del grado) |

### ¿A qué dirección se conecta?

El `ApiClient` usa por defecto `http://10.0.2.2:3000`.

- `10.0.2.2` es una **dirección especial del emulador de Android** que apunta a la computadora donde estás corriendo el backend. `localhost` dentro del emulador sería el propio teléfono virtual, y ahí no hay nada.
- Si corres en **Linux/escritorio**, usa `127.0.0.1`.
- Si usas un **celular físico**, usa la IP de tu PC en la red local.
- Puedes cambiarla sin tocar el código:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.50:3000
```

El proyecto también incluye la configuración de Android necesaria (permiso de `INTERNET` y `usesCleartextTraffic`) para poder conectarse a un servidor HTTP local sin HTTPS durante el desarrollo.

---

## 7. Cómo ejecutar el proyecto

### Requisitos

- **Flutter** instalado (el proyecto usa Dart `^3.13.7`).
- El **backend Flask** corriendo en el puerto `3000` con la base de datos MySQL.
- Un emulador de Android, un dispositivo o Linux/escritorio.

### Pasos

```bash
# 1. Descargar las dependencias
flutter pub get

# 2. (Opcional) apuntar a tu backend si no es el puerto por defecto
# flutter run --dart-define=API_BASE_URL=http://127.0.0.1:3000

# 3. Ejecutar
flutter run
```

### Comprobar que todo está bien

```bash
flutter analyze        # revisa avisos y errores de estilo
flutter test           # ejecuta las pruebas
flutter run -d linux   # (ejemplo) correr en escritorio
```

La prueba existente (`test/widget_test.dart`) verifica que la pantalla de inicio carga y muestra el título y el módulo de Estudiantes.

---

## 8. Avances y correcciones realizadas

El historial de commits cuenta la evolución del proyecto:

**Base del proyecto**
- Estructura de carpetas por features y configuración de dependencias (`http`, `flutter_bloc`).
- `ApiClient` con soporte para `GET`, `POST`, `PUT` y `DELETE`.
- Tema institucional azul/blanco, widgets reutilizables de carga y error, y pantalla de inicio.

**Módulo de Estudiantes**
- `StudentModel` con `fromMaps`, que combina `T_ESTUDIANTE` y `T_PERSONA`.
- `StudentsBloc` con eventos, estados y cruce de datos.
- Pantalla con buscador, insignias de estado y CRUD completo.

**Módulo de Profesores**
- CRUD completo con el mismo patrón BLoC y cruce con `T_PERSONA`.

**Módulo de Cursos**
- CRUD completo, cruce con `T_GRADO` y nombre legible tipo "10° - Grupo A".

**Correcciones y calidad**
- Validación de **unicidad** en cursos (mismo grado + misma letra).
- Manejo amigable del **error de clave foránea** al intentar eliminar estudiantes con historial.
- Prevención de **clave duplicada**: al editar se muestra la persona fija y al crear solo aparecen las personas sin rol.
- Formularios simplificados: al crear un estudiante o profesor el estado queda **Activo** automáticamente.
- Configuración de Android para conectar con el backend local.
- Limpieza de avisos del linter y formato del código.

---

## 9. Qué sigue (pendientes)

Ideas para las próximas iteraciones. **Nada de esto está implementado todavía**:

- Módulo de **matrículas** (relación estudiante ↔ curso ↔ vigencia).
- Módulo de **acudientes**.
- **Asistencia** y **notas** por periodo.
- **Autenticación** de usuarios (roles: administrador, docente, acudiente).
- Persistencia local para poder consultar datos sin internet.
- Pruebas unitarias para los BLoC y los modelos.

---

## 10. Glosario rápido

| Término | Qué significa |
|---|---|
| **Widget** | Pieza básica de la interfaz en Flutter. Todo lo que se ve es un widget. |
| **StatelessWidget** | Widget que no cambia por sí mismo; solo dibuja. |
| **StatefulWidget** | Widget que guarda datos y puede cambiar (ej. el texto del buscador). |
| **Estado** | La información que la pantalla necesita para dibujarse ahora. |
| **Evento** | Aviso que le manda la pantalla al BLoC pidiendo una acción. |
| **BLoC** | Cerebro que recibe eventos, hace el trabajo y emite estados. |
| **`BlocProvider`** | Widget que crea el BLoC y lo pone disponible para los widgets hijos. |
| **`BlocBuilder`** | Widget que se vuelve a dibujar cada vez que el BLoC emite un estado. |
| **`context.read`** | Manera de enviar un evento al BLoC desde un botón. |
| **Modelo** | Clase de Dart que representa un dato del servidor de forma limpia. |
| **`factory` / `fromMaps`** | Constructor especial que construye el modelo a partir de los mapas JSON. |
| **Endpoint** | Dirección de la API (ej. `/estudiantes`). |
| **UUID** | Identificador único de un registro, usado para editar y eliminar sin exponer el ID numérico. |
| **Clave foránea (FK)** | Regla de la base de datos que impide borrar algo que otro registro aún usa. |
| **SnackBar** | Mensaje corto que aparece abajo de la pantalla. |

---

Proyecto formativo **ADSO · SENA** — Colegio Madre Marcelina.
