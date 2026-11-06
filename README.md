# -GuiadoTesting

# Task Manager Application & QA Test Suite

Este proyecto implementa la aplicación completa **Task Manager** y resuelve de manera integral los **15 ejercicios prácticos** descritos en el documento:
> **"Become a Better Application Tester: A Hands-On Task Manager Guide"**

---

## 🚀 Arquitectura del Proyecto

```
DMI/
├── backend/                             # API REST en Node.js/Express
│   ├── src/
│   │   ├── app.js                       # Endpoints /api/v1 y /health
│   │   ├── auth.js                      # Autenticación JWT y Refresh Tokens
│   │   ├── db.js                        # Almacén de datos y aislamiento PostgreSQL
│   │   ├── server.js                    # Servidor Express (Puerto 3000)
│   │   └── tasks/
│   │       └── validation.js            # Validación de título (1-120 caracteres)
│   ├── test/
│   │   ├── validation.test.js           # Pruebas unitarias con Jest (Ejercicio 4)
│   │   └── taskApi.test.js              # Pruebas de integración, seguridad y OWASP (Ejercicios 6 y 9)
│   ├── k6/
│   │   └── health-test.js               # Script de carga y estrés con umbrales (Ejercicio 10)
│   └── package.json
│
├── mobile/                              # Aplicación móvil en Flutter
│   ├── lib/
│   │   ├── main.dart                    # App con login, lista de tareas y visor interactivo de ejercicios
│   │   ├── task.dart                    # Modelo Task con validación y serialización JSON
│   │   ├── task_list_panel.dart         # Widget de estados (loading, empty, error con retry, datos)
│   │   └── api_service.dart             # Cliente API (Remote HTTP & In-Memory Mock)
│   ├── test/
│   │   ├── task_model_test.dart         # Pruebas unitarias de modelo en Dart (Ejercicio 4)
│   │   ├── task_list_panel_test.dart    # Pruebas de widgets y botón retry (Ejercicio 5)
│   │   ├── user_journey_test.dart       # Recorrido E2E completo: login, add, complete, logout (Ejercicio 7)
│   │   └── mock_vs_real_test.dart       # Comparativa Mocks vs Integración Real (Ejercicio 15)
│   └── pubspec.yaml
│
├── docs/
│   └── EXERCISES_COMPREHENSIVE_GUIDE.md # Resolución formal y detallada de los 15 ejercicios del PDF
│
└── .github/
    └── workflows/
        └── tests.yml                    # Pipeline de Integración Continua (CI) (Ejercicio 14)
```

---

## 🧪 Ejecución de Pruebas Automatizadas

### 1. Pruebas de Backend (Jest & Supertest)
```bash
cd backend
npm test
```
*Ejecuta 16 pruebas automatizadas: validaciones de cadenas, límites de 120 caracteres, 401 sin auth, 400 por título vacío, aislamiento cross-user y prevención de vulnerabilidades OWASP.*

### 2. Pruebas de Frontend Móvil (Flutter)
```bash
cd mobile
flutter test
```
*Ejecuta 11 pruebas de widgets, unitarias y flujos E2E: validación de parsing, estados del widget con botón de reintento, y el journey completo del usuario con cierre de sesión.*

---

## 📱 Cómo Ejecutar la Aplicación

### Iniciar el Servidor Backend:
```bash
cd backend
npm start
```
*API disponible en `http://localhost:3000` (Endpoint de salud: `http://localhost:3000/health`).*

### Iniciar la App Móvil Flutter:
```bash
cd mobile
flutter run
```
*O seleccionar dispositivo Chrome, Windows Desktop o Emulador Android en tu entorno de desarrollo.*

---

## 📋 Mapeo de los 15 Ejercicios de la Guía

| # | Ejercicio del Documento | Ubicación en el Código / Documentación |
| :---: | :--- | :--- |
| **1** | Criterios de Aceptación (Task creation) | `docs/EXERCISES_COMPREHENSIVE_GUIDE.md#ejercicio-1` |
| **2** | Reporte de Bug (Tarea desaparece al completarse) | `docs/EXERCISES_COMPREHENSIVE_GUIDE.md#ejercicio-2` |
| **3** | Pruebas Exploratorias con Charter (15 min) | `docs/EXERCISES_COMPREHENSIVE_GUIDE.md#ejercicio-3` |
| **4** | Pruebas Unitarias aisladas (Jest & Dart) | `backend/test/validation.test.js` & `mobile/test/task_model_test.dart` |
| **5** | Botón Retry en Estado de Error (Flutter Widget) | `mobile/lib/task_list_panel.dart` & `mobile/test/task_list_panel_test.dart` |
| **6** | Pruebas API REST (Supertest: ID inválido, sin título, cross-user) | `backend/test/taskApi.test.js` |
| **7** | Recorrido E2E (Complete task + Log out + Login screen) | `mobile/test/user_journey_test.dart` |
| **8** | Particiones de Equivalencia y Límites (Password) | `docs/EXERCISES_COMPREHENSIVE_GUIDE.md#ejercicio-8` |
| **9** | Seguridad OWASP (Mass assignment en ownerId, SQLi, XSS) | `backend/test/taskApi.test.js` & `backend/src/db.js` |
| **10** | Pruebas de Carga y Rendimiento (k6) | `backend/k6/health-test.js` |
| **11** | Accesibilidad y Usabilidad (A11y, Semantics, Text scale) | `mobile/lib/main.dart` |
| **12** | Matriz de Compatibilidad de Dispositivos y Tamaños | `docs/EXERCISES_COMPREHENSIVE_GUIDE.md#ejercicio-12` |
| **13** | Checklist de Pruebas de Regresión | `docs/EXERCISES_COMPREHENSIVE_GUIDE.md#ejercicio-13` |
| **14** | Pipeline de CI con GitHub Actions | `.github/workflows/tests.yml` |
| **15** | Comparativa Mocks vs. Integración Real | `mobile/test/mock_vs_real_test.dart` & `docs/EXERCISES_COMPREHENSIVE_GUIDE.md#ejercicio-15` |
