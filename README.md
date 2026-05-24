# GestiON — Sistema de Gestión para Pequeños Negocios

> **Proyecto de Fin de Ciclo · Desarrollo de Aplicaciones Multiplataforma (DAM)**  
> **Ayoub Chahour · CEAC FP Madrid · 2025–2026**

---

## 📋 Descripción

**GestiON** es una aplicación móvil/web desarrollada con Flutter que proporciona a pequeños negocios (tiendas, talleres, peluquerías, etc.) un sistema completo de gestión en tiempo real. Integra punto de venta (TPV), inventario, historial de ventas, gestión de clientes y métricas de negocio en una única aplicación multiplataforma.

El proyecto demuestra el uso de tecnologías modernas en la nube combinadas con almacenamiento local, ofreciendo una experiencia funcional incluso **sin conexión a internet**.

---

## 🎯 Objetivos del Proyecto

| Objetivo | Descripción |
|----------|-------------|
| **Funcional** | Digitalizar la gestión de un pequeño negocio: ventas, stock, clientes y estadísticas |
| **Técnico** | Aplicar arquitectura cliente-servidor con sincronización offline/online |
| **UX/UI** | Diseño moderno tipo Power BI con navegación intuitiva en Material 3 |
| **Cloud** | Persistencia en la nube con Firebase (Auth + Firestore) |
| **Offline** | Funcionamiento sin red mediante SQLite local como primera capa de datos |

---

## 🏗️ Arquitectura

```
┌─────────────────────────────────────────────────────┐
│                    Flutter App                       │
│                                                     │
│  ┌──────────┐  ┌──────────┐  ┌──────────────────┐  │
│  │  Screens │→ │Providers │→ │    Services       │  │
│  │  (UI)    │  │ (State)  │  │                  │  │
│  │          │  │          │  │ ┌──────────────┐ │  │
│  │Dashboard │  │Inventario│  │ │FirestoreServ.│ │  │
│  │Inventario│  │Provider  │  │ │AuthService   │ │  │
│  │TPV       │  │Ventas    │  │ │LocalDatabase │ │  │
│  │Historial │  │Provider  │  │ │(SQLite)      │ │  │
│  │Clientes  │  │Clientes  │  │ └──────────────┘ │  │
│  │Perfil    │  │Provider  │  └──────────────────┘  │
│  └──────────┘  └──────────┘                        │
└─────────────────────────────────────────────────────┘
         ↕ offline-first          ↕ sync
   ┌──────────────┐         ┌─────────────────┐
   │  SQLite      │         │    Firebase      │
   │  (Local)     │         │  ┌───────────┐  │
   │  - productos │         │  │Firestore  │  │
   │  - clientes  │         │  │Auth       │  │
   │  - ventas    │         │  └───────────┘  │
   └──────────────┘         └─────────────────┘
```

### Patrón Offline-First

Todos los providers siguen el mismo patrón de inicialización:

1. **Carga inmediata desde SQLite** → la UI responde al instante, sin esperar red
2. **Escucha en tiempo real de Firestore** → sincroniza cuando hay conexión
3. **Operaciones de escritura** → persisten en SQLite primero, luego suben a Firestore en background

---

## 🗂️ Estructura de Carpetas

```
lib/
├── core/
│   └── theme.dart              # Tokens de diseño: colores, tipografía
├── models/
│   ├── producto.dart           # Modelo de producto con stock
│   ├── cliente.dart            # Modelo de cliente con puntos de fidelización
│   └── venta.dart              # Modelo de venta + líneas de ticket
├── providers/
│   ├── inventario_provider.dart # Estado del inventario (ChangeNotifier)
│   ├── clientes_provider.dart  # Estado de clientes (ChangeNotifier)
│   └── ventas_provider.dart    # Estado de ventas + carrito (ChangeNotifier)
├── screens/
│   ├── login_screen.dart       # Login / Registro / Recuperar contraseña
│   ├── home_screen.dart        # Shell con NavigationBar (5 módulos)
│   ├── dashboard_screen.dart   # Métricas y gráficos (estilo Power BI)
│   ├── inventario_screen.dart  # CRUD de productos con buscador
│   ├── tpv_screen.dart         # Punto de venta con carrito
│   ├── historial_screen.dart   # Historial de ventas con filtros
│   ├── clientes_screen.dart    # Gestión de clientes + fidelización
│   └── perfil_screen.dart      # Perfil del negocio y ajustes
├── services/
│   ├── auth_service.dart       # Firebase Auth (login/registro/reset)
│   ├── firestore_service.dart  # CRUD Firestore (productos/clientes/ventas)
│   └── local_database.dart     # SQLite — persistencia offline
└── widgets/
    └── common_widgets.dart     # Widgets reutilizables (formatEuro, etc.)
```

---

## 📱 Módulos de la Aplicación

### 1. 🔐 Autenticación (`login_screen.dart`)
- Inicio de sesión y registro con **Firebase Auth** (email + contraseña)
- **Recuperación de contraseña** por email desde la pantalla de login
- Validación de errores con mensajes localizados en español
- La sesión persiste entre reinicios (Firebase maneja el token automáticamente)

### 2. 📊 Dashboard (`dashboard_screen.dart`)
- **4 KPIs** en tiempo real: ventas del día, ingresos, ticket medio, productos vendidos
- **Gráfico de barras** animado con 3 rangos: Hoy (por horas) · Semana (por días) · Mes (por semanas)
- **Métodos de pago** con barras de progreso proporcionales
- **Top 5 productos** más vendidos con medallas 🥇🥈🥉
- Datos calculados dinámicamente desde el historial de ventas

### 3. 📦 Inventario (`inventario_screen.dart`)
- Listado de productos con buscador en tiempo real
- **Añadir / Editar / Eliminar** productos (nombre, precio, stock, categoría)
- Indicadores de **stock bajo** (≤ 5 uds) con alerta visual en rojo
- Sincronización bidireccional Firestore ↔ SQLite

### 4. 💰 TPV — Punto de Venta (`tpv_screen.dart`)
- Búsqueda de productos y adición al carrito con control de cantidad
- **Asociar cliente** al ticket (con búsqueda en la lista de clientes)
- **Datos de comprador** opcionales cuando no hay cliente registrado
- Selección de método de pago: Efectivo · Tarjeta · Bizum
- Confirmación con ticket visual y desglose de IVA (21%)
- Descuento de stock automático al confirmar la venta

### 5. 📋 Historial de Ventas (`historial_screen.dart`)
- Lista completa de ventas ordenada por fecha
- **Filtros** rápidos: Todas · Hoy · Semana · Este mes
- **Buscador** por cliente, método de pago, producto o ID de ticket
- Detalle completo de cada venta en bottom sheet (líneas + IVA + total)
- Estadísticas del filtro activo: número de ventas e ingresos totales

### 6. 👥 Clientes (`clientes_screen.dart`)
- CRUD completo de clientes (nombre, email, teléfono)
- **Sistema de puntos de fidelización** — se acumulan automáticamente con cada compra
- Contador de compras realizadas por cliente
- Buscador por nombre o email

### 7. ⚙️ Perfil y Ajustes (`perfil_screen.dart`)
- Nombre del negocio editable (guardado en SharedPreferences)
- Avatar generado con la inicial del email del usuario
- **Mini-estadísticas** del negocio: total productos, clientes y ventas
- Cambio de contraseña vía email
- Información de la app: versión, base de datos, proyecto Firebase
- Cierre de sesión con confirmación

---

## 🛠️ Stack Tecnológico

| Capa | Tecnología | Versión |
|------|-----------|---------|
| Framework | Flutter | ≥ 3.0 |
| Lenguaje | Dart | ≥ 3.0 |
| Autenticación | Firebase Auth | ^4.17.8 |
| Base de datos cloud | Cloud Firestore | ^4.15.8 |
| Base de datos local | SQLite (sqflite) | ^2.3.2 |
| Gestión de estado | Provider | ^6.1.2 |
| Preferencias locales | Shared Preferences | ^2.2.2 |
| Internacionalización | intl | ^0.19.0 |
| IDs únicos | uuid | ^4.3.3 |
| UI | Material Design 3 | — |

---

## 🔥 Configuración de Firebase

### Proyecto Firebase
- **Nombre del proyecto**: `gestion-b8736`
- **Servicios activos**: Authentication · Cloud Firestore

### Colecciones Firestore

Cada usuario tiene su propia subcolección aislada bajo `/usuarios/{uid}/`:

```
/usuarios/{uid}/
  productos/{productoId}
    ├── nombre: String
    ├── precio: double
    ├── stock: int
    └── categoria: String

  clientes/{clienteId}
    ├── nombre: String
    ├── email: String
    ├── telefono: String
    ├── puntos: int
    └── compras: int

  ventas/{ventaId}
    ├── fecha: Timestamp
    ├── total: double
    ├── metodoPago: String
    ├── clienteId: String
    ├── clienteNombre: String
    └── lineas: Array<{nombre, precio, cantidad, subtotal}>
```

### Reglas de Seguridad Firestore

```js
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /usuarios/{userId}/{document=**} {
      allow read, write: if request.auth != null
                         && request.auth.uid == userId;
    }
  }
}
```

> Cada negocio solo puede leer y escribir sus propios datos.

---

## 🗄️ Base de Datos Local (SQLite)

La base de datos local actúa como caché offline y primera fuente de verdad para la UI.

**Tablas:**

| Tabla | Campos principales |
|-------|-------------------|
| `productos` | id, nombre, precio, stock, categoria |
| `clientes` | id, nombre, email, telefono, puntos, compras |
| `ventas` | id, fecha, lineas (JSON), total, metodoPago, clienteId, clienteNombre, **sincronizado** |

El campo `sincronizado` (0/1) permite reenviar a Firestore las ventas registradas offline cuando se recupera la conexión.

---

## 🚀 Instalación y Ejecución

### Prerrequisitos
- Flutter SDK ≥ 3.0 instalado y en el PATH
- Dart SDK ≥ 3.0
- Android Studio / VS Code con extensión Flutter

### Pasos

```bash
# 1. Clonar el repositorio
git clone https://github.com/ayoubchahour2001/GestiON
cd gestion_app

# 2. Instalar dependencias
flutter pub get

# 3. Ejecutar en web (desarrollo)
flutter run -d chrome

# 4. Ejecutar en Android
flutter run -d <device-id>

# 5. Compilar APK de release
flutter build apk --release
```

> **Primera vez:** arranca en la pantalla de login. Pulsa **"¿No tienes cuenta? Regístrate"** para crear la cuenta de tu negocio.

### Regenerar configuración Firebase (si se clona en otro equipo)

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

Esto sobrescribirá `lib/firebase_options.dart` con las credenciales del proyecto.

---

## ✅ Funcionalidades Implementadas

- [x] Autenticación Firebase (login / registro / recuperar contraseña)
- [x] Inventario completo con CRUD y alertas de stock bajo
- [x] TPV con carrito, búsqueda de clientes y selección de método de pago
- [x] Confirmación de cobro con ticket desglosado (IVA 21%)
- [x] Historial de ventas con filtros por fecha y buscador
- [x] Dashboard con KPIs, gráfico de barras y top productos
- [x] Gestión de clientes con puntos de fidelización automáticos
- [x] Perfil del negocio con estadísticas y ajustes
- [x] Almacenamiento offline con SQLite (carga instantánea sin red)
- [x] Sincronización Firestore en tiempo real
- [x] Reintento de ventas offline pendientes al reconectar
- [x] Diseño Material 3 con tema oscuro consistente

---

## 📐 Decisiones de Diseño

### Offline-First
La prioridad es que la app funcione sin internet. SQLite carga los datos al instante y Firestore sincroniza en segundo plano sin bloquear la UI.

### Fire-and-forget en operaciones no críticas
Las operaciones como `descontarStock` y `registrarCompra` en Firestore se ejecutan sin `await` para evitar que el usuario espere en el TPV. Si fallan, se recuperan en la próxima sincronización.

### `BuildContext.mounted` en todos los callbacks async
Todos los métodos asíncronos verifican `if (mounted)` antes de llamar a `setState` o mostrar SnackBars, evitando errores de contexto inválido.

### IndexedStack para la navegación principal
Mantiene el estado de cada pantalla en memoria al cambiar de módulo, evitando recargas innecesarias de datos.

---

## 🔒 Seguridad

- Las reglas de Firestore garantizan que cada usuario solo accede a sus propios datos (`request.auth.uid == userId`).
- Las credenciales de Firebase (`firebase_options.dart`) no deben subirse a repositorios públicos — añadir al `.gitignore`.
- Las contraseñas nunca se almacenan localmente; Firebase Auth gestiona el ciclo de vida de los tokens.

---

## 👤 Autor

| Campo | Valor |
|-------|-------|
| **Nombre** | Ayoub Chahour |
| **Ciclo** | Desarrollo de Aplicaciones Multiplataforma (DAM) |
| **Centro** | CEAC FP Madrid |
| **Año** | 2025–2026 |
| **GitHub** | [@ayoubchahour2001](https://github.com/ayoubchahour2001) |

---

## 📄 Licencia

Proyecto académico — todos los derechos reservados. No se permite su redistribución sin autorización del autor.
