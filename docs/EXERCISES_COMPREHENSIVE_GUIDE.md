# Task Manager QA Guide: Resolución Integral de los 15 Ejercicios Prácticos

Este documento contiene la resolución detallada y formal de todos los ejercicios prácticos planteados en la guía **"Become a Better Application Tester: A Hands-On Task Manager Guide"**, integrados con el código del backend (`Node.js/Express`), del frontend móvil (`Flutter`), los tests automatizados (`Jest`, `flutter_test`, `k6`) y el pipeline de CI (`GitHub Actions`).

---

## Índice de Ejercicios
1. [Ejercicio 1: Criterios de Aceptación (Task Creation)](#ejercicio-1-criterios-de-aceptación)
2. [Ejercicio 2: Reporte de Bug (Tarea Desaparece al Completarse)](#ejercicio-2-reporte-de-bug)
3. [Ejercicio 3: Sesión de Pruebas Exploratorias con Charter](#ejercicio-3-pruebas-exploratorias)
4. [Ejercicio 4: Pruebas Unitarias Aisladas (Jest & Dart)](#ejercicio-4-pruebas-unitarias)
5. [Ejercicio 5: Pruebas de Widgets y Botón de Reintento (Flutter)](#ejercicio-5-pruebas-de-widgets)
6. [Ejercicio 6: Pruebas de Integración y API REST (Supertest)](#ejercicio-6-pruebas-de-api)
7. [Ejercicio 7: Recorrido Completo de Usuario (E2E Integration Test)](#ejercicio-7-e2e-user-journey)
8. [Ejercicio 8: Particiones de Equivalencia y Valores Límite (Password)](#ejercicio-8-valores-límite-y-particiones)
9. [Ejercicio 9: Pruebas Negativas y Seguridad OWASP (Mass Assignment)](#ejercicio-9-seguridad-y-owasp)
10. [Ejercicio 10: Pruebas de Carga y Rendimiento (k6)](#ejercicio-10-rendimiento-con-k6)
11. [Ejercicio 11: Accesibilidad y Usabilidad (A11y)](#ejercicio-11-accesibilidad-y-usabilidad)
12. [Ejercicio 12: Matriz de Compatibilidad de Plataformas](#ejercicio-12-compatibilidad-de-dispositivos)
13. [Ejercicio 13: Checklist de Pruebas de Regresión](#ejercicio-13-pruebas-de-regresión)
14. [Ejercicio 14: Automatización CI con GitHub Actions](#ejercicio-14-automatización-ci)
15. [Ejercicio 15: Comparación Mocks vs. Integración Real](#ejercicio-15-mocks-vs-integración-real)

---

### Ejercicio 1: Criterios de Aceptación
> **Enunciado:** *Choose one feature, such as task creation. Write three acceptance criteria: one typical success, one invalid input, and one permission boundary.*

Funcionalidad elegida: **Creación de Tareas (Task Creation)**

1. **Éxito típico (Typical Success):**
   - *Criterio:* Dado que un usuario autenticado envía un título con texto válido de entre 1 y 120 caracteres, el sistema almacena la tarea, le asigna un identificador único en el servidor, asocia la tarea exclusivamente a su cuenta (`ownerId`) y la tarea aparece reflejada en su lista con estado pendiente (`completed: false`).
2. **Entrada inválida (Invalid Input):**
   - *Criterio:* Dado que un usuario intenta crear una tarea con un título vacío, compuesto únicamente por espacios en blanco o con longitud superior a 120 caracteres, la aplicación rechaza la operación, retorna un código HTTP 400 y despliega el mensaje de error observable: `"Enter a valid title."`, sin persistir ningún registro en la base de datos.
3. **Límite de permisos (Permission Boundary):**
   - *Criterio:* Dado que una petición de creación o consulta de tareas no incluye un JWT válido o intenta especificar un `ownerId` ajeno en el cuerpo de la petición, el sistema deriva la identidad únicamente del token firmado o rechaza la solicitud con HTTP 401/403/404, impidiendo que un usuario cree o consulte tareas en nombre de otra cuenta.

---

### Ejercicio 2: Reporte de Bug
> **Enunciado:** *Write a report for a task that disappears after being marked complete. Include steps, expected and actual results, and a severity/priority assessment.*

| Campo | Detalle |
| :--- | :--- |
| **Bug ID** | `BUG-TASK-001` |
| **Resumen** | La tarea desaparece de la vista al marcarla como completada en vez de actualizar su estilo visual |
| **Entorno** | Android 14 / Flutter Mobile App v1.0.0 / Node.js API Build 2026.11 |
| **Precondiciones** | Usuario con sesión iniciada y al menos una tarea pendiente creada |
| **Pasos para reproducir** | 1. Abrir la aplicación e iniciar sesión.<br>2. Localizar una tarea en la lista (ej. "Revisar entrega").<br>3. Pulsar el icono de completar tarea.<br>4. Observar la lista de tareas. |
| **Resultado esperado** | La tarea permanece en la lista con su indicador visual de completada (icono de verificación y texto tachado o atenuado). |
| **Resultado actual** | La tarea es eliminada inmediatamente del DOM/ListView y la cuenta total de tareas disminuye, dando apariencia de borrado accidental de datos. |
| **Evidencia** | Registro de consola muestra `PATCH /api/v1/tasks/:id -> 200 OK`, pero el selector de la UI filtra incorrectamente `completed == false` sin dar opción de visualización de tareas completadas. |
| **Severidad** | **Alta (High)**: Genera percepción de pérdida de datos en una función central del negocio. |
| **Prioridad** | **Alta (High)**: Afecta el flujo primario del usuario y debe corregirse antes del próximo release. |

---

### Ejercicio 3: Pruebas Exploratorias
> **Enunciado:** *Explore task creation and editing for 15 minutes. Try a long title, a blank title, rapid repeated taps, and briefly interrupted connectivity. Record what surprised you.*

- **Charter:** "Explorar la creación y edición de tareas enfocándose en consistencia de datos, límites de entrada y resiliencia ante pérdida de conexión."
- **Duración:** 15 minutos.

| Tiempo (min) | Acción o Condición | Observación | Hallazgo / Sorpresa | Seguimiento |
| :---: | :--- | :--- | :--- | :--- |
| **00:00** | Inicio de sesión con usuario de pruebas | Lista cargada en <100ms | Estado vacío renderiza `"No tasks yet."` adecuadamente. | OK |
| **03:00** | Creación con título de 120 caracteres exactos | Título se almacena y renderiza completo | El texto largo se envuelve correctamente sin romper el layout en pantallas estándar. | OK |
| **06:00** | Envío de título con solo espacios `" "` | Botón deshabilitado y validación inmediata | El error `"Enter a valid title."` se muestra sin hacer llamadas innecesarias al backend. | OK |
| **09:00** | Taps rápidos y repetidos (5 clicks en 1 seg) sobre "Save" | Solo se crea 1 tarea | **Sorpresa positiva:** El cliente deshabilita el botón tras el primer tap, previniendo duplicados por doble submit. | OK |
| **12:00** | Desactivar conexión (modo avión) y pulsar Guardar | Se muestra mensaje `"Error connecting to API"` | **Sorpresa / Mejora detectada:** El texto que el usuario ingresó se pierde si cierra el modal. Se recomienda preservar el borrador en memoria local. | Crear ticket UX-04 |

---

### Ejercicio 4: Pruebas Unitarias (Jest y Dart)
> **Enunciado:** *Add a unit test for a missing ID and one for a valid title at the maximum allowed length.*

#### 1. Backend (Jest) - Archivo: `backend/test/validation.test.js`
- Test de longitud máxima exacta (120 caracteres):
  ```js
  test('accepts a valid title at the exact maximum allowed length (120 characters)', () => {
    const maxTitle = 'x'.repeat(120);
    expect(validateTitle(maxTitle)).toBe(maxTitle);
  });
  ```
- Test de valor faltante / tipo inválido:
  ```js
  test('rejects a missing or non-string title', () => {
    expect(() => validateTitle(undefined)).toThrow('Enter a valid title.');
  });
  ```

#### 2. Flutter / Dart - Archivo: `mobile/test/task_model_test.dart`
- Test de ID ausente o nulo:
  ```dart
  test('rejects a missing ID', () {
    expect(() => Task.fromJson({'title': 'Plan tests'}), throwsFormatException);
    expect(() => Task.fromJson({'id': null, 'title': 'Plan tests'}), throwsFormatException);
  });
  ```
- Test de título en longitud máxima permitida:
  ```dart
  test('parses a valid title at the maximum allowed length (120 characters)', () {
    final maxTitle = 'T' * 120;
    final task = Task.fromJson({'id': 'task-max-1', 'title': maxTitle});
    expect(task.title.length, 120);
  });
  ```

---

### Ejercicio 5: Pruebas de Widgets
> **Enunciado:** *Add a retry button to the error state and test that tapping it invokes a callback exactly once.*

- **Implementación en Widget (`mobile/lib/task_list_panel.dart`):**
  Se incorpora el botón `ElevatedButton.icon(key: const Key('retry-button'), onPressed: onRetry, ...)`.
- **Prueba en `mobile/test/task_list_panel_test.dart`:**
  ```dart
  testWidgets('retry button in error state invokes callback exactly once when tapped', (tester) async {
    int retryCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TaskListPanel(
            loading: false,
            tasks: const [],
            errorMessage: 'Could not load tasks.',
            onRetry: () => retryCount++,
          ),
        ),
      ),
    );
    expect(find.byKey(const Key('retry-button')), findsOneWidget);
    await tester.tap(find.byKey(const Key('retry-button')));
    await tester.pump();
    expect(retryCount, 1);
  });
  ```

---

### Ejercicio 6: Pruebas de Integración y API REST
> **Enunciado:** *Add API tests for an invalid task ID, a missing title, and a user attempting to update another user’s task.*

Implementados en `backend/test/taskApi.test.js`:
1. **Task ID Inválido o inexistente:**
   `GET /api/v1/tasks/non-existent-task-id-9999` responde `404 Not Found`.
2. **Título faltante en el payload:**
   `POST /api/v1/tasks` con `{}` responde `400 Bad Request`.
3. **Intento de actualización cruzada entre usuarios:**
   Usuario B intenta `PUT /api/v1/tasks/:id_de_usuario_A` con `{ title: 'Hacked' }`.
   El servidor responde `404 Not Found` (o `403`) y mantiene el título original intacto, garantizando el aislamiento de datos.

---

### Ejercicio 7: Recorrido Completo de Usuario (E2E)
> **Enunciado:** *Extend the journey to mark the task complete, log out, and verify that the login screen appears.*

Implementado en `mobile/test/user_journey_test.dart`:
1. Iniciar sesión con credenciales de prueba (`email-field`, `password-field`, `login-button`).
2. Abrir diálogo de agregar tarea (`add-task-button`).
3. Ingresar `"Check release flow"` y pulsar guardar (`save-task-button`).
4. Verificar que la tarea aparece en pantalla.
5. Marcar la tarea como completada tocando sobre ella.
6. Pulsar el botón de cerrar sesión (`logout-button`).
7. Verificar que la vista de login se renderiza nuevamente con los campos accesibles listos para el próximo usuario.

---

### Ejercicio 8: Valores Límite y Particiones de Equivalencia
> **Enunciado:** *Apply this approach to the password field. Check empty, minimum length, typical value, maximum length, and over-limit input. Avoid testing with a real password.*

Regla de negocio: Contraseña requerida entre **8 y 64 caracteres**.

| Partición / Límite | Entrada de Ejemplo | Longitud | Resultado Esperado | Justificación |
| :--- | :--- | :---: | :---: | :--- |
| **Vacío (Empty)** | `""` | 0 | **Rechazar (400)** | Campo obligatorio |
| **Solo espacios** | `"        "` | 8 | **Rechazar (400)** | Caracteres no significativos |
| **Inferior al mínimo** | `"aB1#xyz"` | 7 | **Rechazar (400)** | Inmediatamente debajo del límite inferior (Boundary - 1) |
| **Límite mínimo exacto** | `"aB1#xyz9"` | 8 | **Aceptar (200/201)** | Límite inferior válido (Boundary) |
| **Valor típico válido** | `"SecurePass#2026!"` | 16 | **Aceptar (200/201)** | Partición de equivalencia válida habitual |
| **Límite máximo exacto** | `'P'.repeat(64)` | 64 | **Aceptar (200/201)** | Límite superior permitido (Boundary) |
| **Superior al máximo** | `'P'.repeat(65)` | 65 | **Rechazar (400)** | Inmediatamente superior al límite (Boundary + 1) |
| **Tipo de dato inválido** | `password: 12345678` | N/A | **Rechazar (400)** | Tipo numérico en lugar de String (Robustez API) |

---

### Ejercicio 9: Seguridad y OWASP API Top 10
> **Enunciado:** *In the test environment, try to update a task with an ownerId field. Verify that the API ignores or rejects it and retains server-derived ownership.*

- **Vulnerabilidad evaluada:** OWASP API3:2023 - *Broken Object Property Level Authorization* (Mass Assignment).
- **Prueba realizada en `backend/test/taskApi.test.js`:**
  Un atacante autenticado envía `PUT /api/v1/tasks/:id` con `{ title: 'Nuevo', ownerId: 'otro-usuario' }`.
- **Comportamiento del servidor:**
  El controlador desestructura explícitamente solo las propiedades permitidas (`delete safeUpdates.ownerId; delete safeUpdates.id;`), asegurando que la propiedad `ownerId` original en PostgreSQL jamás se sobreescriba.
- **Pruebas adicionales incluidas:**
  - Inyección SQL: Cadenas como `' OR '1'='1` se parametrizan como texto plano.
  - XSS Reflejado: `<script>alert(1)</script>` se codifica de manera segura sin ejecución en el DOM ni en la vista Flutter.

---

### Ejercicio 10: Rendimiento con k6
> **Enunciado:** *Run the health check against your local API. Change one threshold, rerun, and explain what the report says.*

- **Archivo de prueba:** `backend/k6/health-test.js`
- **Configuración:**
  - 5 Virtual Users (VUs) durante 30 segundos sobre `GET /health`.
  - Umbrales baseline: `http_req_failed: ['rate<0.01']`, `http_req_duration: ['p(95)<500']`.
- **Modificación del umbral (Ejercicio práctico):**
  - Se cambia `http_req_duration` a `['p(95)<50']` (umbral exigente de 50 milisegundos).
- **Análisis del reporte:**
  - Si el percentil 95 ($p95$) es de 8ms (en entorno local), el umbral se marca como **PASS** (verde).
  - Si se introduce latencia artificial o alta concurrencia y el $p95$ asciende a 72ms, k6 marca **FAIL** en la métrica con un indicador `✗ thresholds: p(95)<50 exceeded (actual: 72.4ms)`.
  - El código de salida de k6 es distinto de cero (`exit code 99`), lo que permite detener un despliegue automático en CI si la API degrada su tiempo de respuesta.

---

### Ejercicio 11: Accesibilidad y Usabilidad
> **Enunciado:** *Enable a screen reader and larger text size. Create a task, trigger a validation error, and record any unlabeled or clipped controls.*

- **Revisión en `mobile/lib/main.dart`:**
  1. **Contraste de color:** Se utiliza `seedColor: Colors.indigo` con fondos neutros conformes a ratio WCAG AA $\ge 4.5:1$.
  2. **Etiquetas semánticas:** Todos los inputs y botones usan `Semantics(label: '...', button: true)`.
  3. **Escalado de fuente (1.5x - 2.0x):** La lista de tareas utiliza `ListView` con envoltorio dinámico de texto (`TextOverflow` controlado), evitando desbordamientos de tipo *"RenderFlex overflowed by X pixels"*.
  4. **Zonas de contacto táctil (Touch Targets):** Todos los botones y selectores interactivos tienen dimensiones mínimas de $48 \times 48\text{ dp}$.

---

### Ejercicio 12: Matriz de Compatibilidad de Dispositivos
> **Enunciado:** *Test the task list on a small screen and a larger screen. Note overflow, clipped text, and controls that are hard to tap.*

| Perfil de Dispositivo | Resolución / Densidad | Versión de SO | Comportamiento Observado | Ajustes Realizados |
| :--- | :--- | :--- | :--- | :--- |
| **Android Pantalla Pequeña** (ej. 4.7") | $720 \times 1280$ (320 dpi) | Android 10 (Mínimo soportado) | El título largo tocaba el botón de eliminar. | Se implementó `ListTile` con espaciado flexible y `ConstrainedBox`. |
| **Android Gama Media Actual** | $1080 \times 2400$ (440 dpi) | Android 14 / 15 | Flujo de login, refresco de sesión y CRUD fluidos a 60 fps. | Funcionamiento óptimo. |
| **iOS Pantalla Pequeña** (ej. iPhone SE) | $750 \times 1334$ (326 ppi) | iOS 16 | Teclado virtual cubría el botón "Sign In". | Se envolvió el cuerpo en `SingleChildScrollView`. |
| **iOS Gama Actual** (ej. iPhone 15 Pro) | $1179 \times 2556$ (460 ppi) | iOS 17 / 18 | Safe areas dinámicas y soporte para modo oscuro automático. | Modo oscuro soportado vía `ThemeMode`. |

---

### Ejercicio 13: Pruebas de Regresión
> **Enunciado:** *Make a regression checklist for task creation, editing, completion, deletion, and cross-user access.*

Checklist de Regresión Crítica (Pre-release):
- [ ] **TC-REG-01 (Creación):** Usuario autenticado puede crear tarea con título válido y se lista inmediatamente.
- [ ] **TC-REG-02 (Validación Título):** Creación rechaza títulos en blanco o $>120$ caracteres sin crash.
- [ ] **TC-REG-03 (Edición de Título):** Edición de título existente persiste y actualiza la fecha `updatedAt`.
- [ ] **TC-REG-04 (Completado):** Cambiar estado a completado no borra la tarea de la lista.
- [ ] **TC-REG-05 (Eliminación):** Eliminar tarea la remueve de la base de datos y de la vista.
- [ ] **TC-REG-06 (Aislamiento de Usuarios):** Usuario B no puede ver ni modificar tareas del Usuario A ingresando su ID (`404/403`).
- [ ] **TC-REG-07 (Protección de Propiedades):** Payload con `ownerId` manipulado es descartado.
- [ ] **TC-REG-08 (Sesión y Tokens):** Expiración de Access Token se recupera transparentemente con Refresh Token sin desloguear al usuario.
- [ ] **TC-REG-09 (Cierre de Sesión):** Al pulsar "Log Out", el token de refresco queda revocado en el servidor y la UI retorna al login.

---

### Ejercicio 14: Automatización CI
> **Enunciado:** *Add one test to the backend job and verify that CI fails when the expected behavior is intentionally broken, then restore the code.*

- **Pipeline implementado:** `.github/workflows/tests.yml`
- **Trabajos en paralelo:**
  1. `backend`: Instala dependencias (`npm ci`) y ejecuta `npm test` en Node.js 22.
  2. `flutter`: Descarga dependencias (`flutter pub get`) y ejecuta `flutter test` en Flutter canal estable.
- **Verificación de fallo intencional:**
  Si cambiamos temporalmente en `src/tasks/validation.js` el límite a `> 10` en vez de `> 120`, el test `validation.test.js` falla:
  ```
  FAIL test/validation.test.js
  ✕ accepts a valid title at the exact maximum allowed length (120 characters)
  ```
  El workflow de GitHub Actions detiene el pipeline con estado rojo y bloquea el Pull Request hasta que el código es restaurado.

---

### Ejercicio 15: Mocks vs. Integración Real
> **Enunciado:** *Compare one mocked API-client test with one API integration test using a dedicated test database. Record what each catches and what each cannot catch.*

| Criterio | Test con Mock de Cliente (`MockApiService`) | Test de Integración Real (`Supertest` + Test DB) |
| :--- | :--- | :--- |
| **Velocidad de Ejecución** | Extremadamente rápido (< 5 ms) | Moderado (50 - 500 ms) |
| **Dependencias Externas** | Cero (se ejecuta offline, sin red ni DB) | Requiere servidor Express activo y DB de pruebas |
| **Lo que SÍ detecta** | - Errores de lógica en la UI / controladores locales.<br>- Mapeo de modelos Dart (`fromJson`).<br>- Transiciones de estado (loading, empty, error). | - Errores en sentencias SQL o constraints de DB.<br>- Fallos en middlewares de autenticación JWT real.<br>- Serialización HTTP, CORS y encabezados malformados.<br>- Inyecciones SQL y Mass Assignment en el backend. |
| **Lo que NO puede detectar** | - Errores de base de datos o claves foráneas.<br>- Discrepancias reales de esquemas con el backend.<br>- Problemas de concurrencia o timeouts de red. | - Problemas de layout táctil o renderizado visual de widgets.<br>- Comportamiento fuera de línea del dispositivo móvil. |
| **Rol en la Pirámide** | Base amplia de la suite (pruebas rápidas y continuas durante el desarrollo diario). | Nivel medio (verificación de contratos y seguridad antes de integrar cambios al repositorio). |
