# 🦷 Sistema de Gestión Odontológica

Sistema completo de gestión para clínicas dentales con autenticación, gestión de citas, clientes y panel de control interactivo con conexión a Supabase.

![React](https://img.shields.io/badge/React-19-blue?logo=react)
![Supabase](https://img.shields.io/badge/Supabase-Backend-green?logo=supabase)
![Bootstrap](https://img.shields.io/badge/Bootstrap-5-purple?logo=bootstrap)
![Vite](https://img.shields.io/badge/Vite-Build-yellow?logo=vite)

---

## 📋 Tabla de Contenidos

- [Características](#-características)
- [Tecnologías](#-tecnologías)
- [Instalación](#-instalación)
- [Configuración](#-configuración)
- [Uso](#-uso)
- [Estructura del Proyecto](#-estructura-del-proyecto)
- [Despliegue](#-despliegue)
- [Credenciales de Prueba](#-credenciales-de-prueba)
- [Roadmap](#-roadmap)
- [Licencia](#-licencia)

---

## ✨ Características

### 🔐 Autenticación
- ✅ Login con email y contraseña
- ✅ Recuperación de contraseña por email
- ✅ Autenticación segura con Supabase Auth
- ✅ Protección de rutas privadas
- ✅ Gestión de sesiones

### 👥 Gestión de Clientes
- ✅ Registro completo de pacientes
- ✅ CRUD de clientes (Crear, Leer, Actualizar, Eliminar)
- ✅ Validación de cédula única
- ✅ Búsqueda y filtrado de clientes
- ✅ Interfaz de dos columnas responsive

### 📅 Gestión de Citas
- ✅ Registro de citas médicas
- ✅ Vista de calendario interactivo
- ✅ Vista de lista completa
- ✅ Validación de citas duplicadas por hora
- ✅ Asignación de doctor encargado
- ✅ Numeración automática de citas (0001, 0002...)
- ✅ Manejo correcto de zonas horarias

### 📊 Dashboard Interactivo
- ✅ Gráfico de barras de citas semanales (Lun-Vie)
- ✅ Tarjetas de estadísticas en tiempo real
- ✅ Panel de próximas citas con sistema de urgencia por colores
- ✅ Recordatorios para el personal
- ✅ Actualización automática de datos

### 🔔 Sistema de Notificaciones
- ✅ Alertas de citas próximas
- ✅ Código de colores por urgencia:
  - 🔴 Hoy
  - 🟠 Mañana
  - 🟡 2-3 días
  - 🔵 4+ días

---

## 🛠 Tecnologías

| Tecnología | Uso |
|-----------|-----|
| **React 19** | Framework frontend |
| **Vite** | Build tool y dev server |
| **Supabase** | Backend as a Service (Base de datos PostgreSQL + Auth) |
| **Bootstrap 5** | Framework CSS responsive |
| **Bootstrap Icons** | Iconografía |
| **React Router DOM** | Navegación entre páginas |
| **JavaScript ES6+** | Lenguaje de programación |

---

## 📦 Instalación

### Prerequisitos

- Node.js 18+ instalado
- npm o yarn
- Cuenta en [Supabase](https://supabase.com) (gratis)

### Pasos

1. **Clonar el repositorio**

```bash
git clone <url-del-repositorio>
cd odonto-system
```

2. **Instalar dependencias**

```bash
npm install
```

3. **Configurar variables de entorno**

Copia el archivo de ejemplo y configura tus credenciales:

```bash
cp .env.example .env
```

Edita `.env` con tus credenciales de Supabase:

```env
VITE_SUPABASE_URL=https://tu-proyecto.supabase.co
VITE_SUPABASE_ANON_KEY=tu_clave_anonima_aqui
```

> ⚠️ **IMPORTANTE**: Nunca subas el archivo `.env` a GitHub. Ya está incluido en `.gitignore`.

---

## ⚙️ Configuración

### 1. Configurar Supabase

#### A. Crear Proyecto
1. Ve a [Supabase](https://supabase.com)
2. Crea un nuevo proyecto
3. Espera a que se complete la configuración (2-3 minutos)

#### B. Obtener Credenciales
1. Ve a **Settings** → **API**
2. Copia:
   - **Project URL** → `VITE_SUPABASE_URL`
   - **anon/public key** → `VITE_SUPABASE_ANON_KEY`

#### C. Ejecutar Scripts SQL

En el **SQL Editor** de Supabase, ejecuta en orden:

1. **Schema completo**: `supabase-schema.sql`
2. **Secuencia de números de cita**: `verify-and-fix-sequence.sql`

Estos scripts crearán:
- Tabla `clientes`
- Tabla `citas_medicas`
- Tabla `doctors` (opcional)
- Políticas de seguridad RLS
- Funciones y triggers automáticos

### 2. Configurar Zona Horaria (Opcional)

Si las horas se guardan incorrectamente, ejecuta en Supabase SQL Editor:

```sql
-- Para Ecuador/Colombia/Perú (UTC-5)
ALTER DATABASE postgres SET timezone TO 'America/Guayaquil';

-- Para México
ALTER DATABASE postgres SET timezone TO 'America/Mexico_City';
```

Ver documentación completa en: [`SOLUCION-ZONA-HORARIA.md`](SOLUCION-ZONA-HORARIA.md)

---

## 🚀 Uso

### Desarrollo Local

```bash
npm run dev
```

La aplicación estará disponible en: `http://localhost:5173`

### Build para Producción

```bash
npm run build
```

Los archivos optimizados se generarán en la carpeta `dist/`.

### Preview de Producción

```bash
npm run preview
```

---

## 📂 Estructura del Proyecto

```
odonto-system/
├── src/
│   ├── components/
│   │   ├── Login.jsx              # Autenticación
│   │   ├── Dashboard.jsx          # Layout principal
│   │   ├── DashboardHome.jsx      # Panel de control
│   │   ├── Clientes.jsx           # Gestión de clientes
│   │   ├── Citas.jsx              # Gestión de citas
│   │   └── *.css                  # Estilos de componentes
│   ├── context/
│   │   └── AuthContext.jsx        # Context de autenticación
│   ├── lib/
│   │   └── supabaseClient.js      # Cliente de Supabase
│   ├── App.jsx
│   └── main.jsx
├── docs/                          # Documentación adicional
│   ├── DASHBOARD-FEATURES.md      # Características del dashboard
│   ├── SOLUCION-ZONA-HORARIA.md   # Guía de zonas horarias
│   └── INSTRUCCIONES-FINALES.md   # Instrucciones generales
├── *.sql                          # Scripts de base de datos
├── .env.example                   # Plantilla de variables
├── .gitignore                     # Archivos ignorados por git
├── package.json
├── vite.config.js
└── README.md
```

---

## 🌐 Despliegue

### Vercel (Recomendado)

#### Opción 1: Interfaz Web

1. **Sube tu código a GitHub**
2. Ve a [Vercel](https://vercel.com)
3. Haz clic en **Import Project**
4. Selecciona tu repositorio
5. Configura las **Environment Variables**:
   ```
   VITE_SUPABASE_URL = tu_url_de_supabase
   VITE_SUPABASE_ANON_KEY = tu_clave_anonima
   ```
6. Haz clic en **Deploy**

#### Opción 2: CLI

```bash
# Instalar Vercel CLI
npm i -g vercel

# Login
vercel login

# Desplegar
vercel

# Configurar variables
vercel env add VITE_SUPABASE_URL
vercel env add VITE_SUPABASE_ANON_KEY

# Deploy a producción
vercel --prod
```

### Netlify

1. Conecta tu repositorio de GitHub
2. Configura el build:
   - **Build command**: `npm run build`
   - **Publish directory**: `dist`
3. Agrega las variables de entorno
4. Deploy

---

## 🔑 Credenciales de Prueba

Para probar el sistema sin crear una cuenta:

```
Email: usertest@gmail.com
Contraseña: test12345
```

> 📝 **Nota**: Estas credenciales deben crearse manualmente en Supabase Authentication antes de usarlas.

### Crear Usuario de Prueba

1. Ve a Supabase Dashboard
2. **Authentication** → **Users**
3. Clic en **Add user**
4. Email: `usertest@gmail.com`
5. Password: `test12345`
6. Confirma

---

## 🗺 Roadmap

### ✅ Completado
- [x] Sistema de autenticación
- [x] Gestión de clientes
- [x] Gestión de citas con calendario
- [x] Dashboard con gráficos
- [x] Notificaciones de citas próximas
- [x] Recordatorios

### 🚧 En Desarrollo
- [ ] Módulo de pagos
- [ ] Historial médico de pacientes
- [ ] Tratamientos y procedimientos
- [ ] Inventario de materiales
- [ ] Reportes en PDF/Excel
- [ ] Notificaciones por email
- [ ] Envío de recordatorios por WhatsApp
- [ ] Gestión de múltiples doctores
- [ ] Calendario compartido
- [ ] Modo oscuro

### 🔮 Futuro
- [ ] App móvil (React Native)
- [ ] Sistema de facturación
- [ ] Integración con sistemas de pago
- [ ] Portal del paciente
- [ ] Telemedicina básica
- [ ] Analytics avanzados

---

## 📄 Documentación Adicional

- [**DASHBOARD-FEATURES.md**](DASHBOARD-FEATURES.md) - Características detalladas del dashboard
- [**SOLUCION-ZONA-HORARIA.md**](SOLUCION-ZONA-HORARIA.md) - Solución a problemas de zonas horarias
- [**INSTRUCCIONES-FINALES.md**](INSTRUCCIONES-FINALES.md) - Guía de uso del sistema de citas

---

## 🐛 Solución de Problemas

### Error: "null value in column 'appointment_number'"
Ejecuta el script: `verify-and-fix-sequence.sql`

### Las horas se guardan incorrectamente
Consulta: `SOLUCION-ZONA-HORARIA.md`

### Problemas con Bootstrap Icons
Ya está configurado en `vite.config.js` para permitir servir archivos externos.

---

## 🤝 Contribuciones

Las contribuciones son bienvenidas. Por favor:

1. Fork el proyecto
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

---

## 📞 Soporte

Si tienes preguntas o problemas:

1. Revisa la [documentación](#-documentación-adicional)
2. Abre un [Issue](../../issues) en GitHub
3. Consulta la [documentación de Supabase](https://supabase.com/docs)

---

## 📝 Licencia

Este proyecto está bajo la Licencia MIT. Ver el archivo `LICENSE` para más detalles.

---

## 👨‍💻 Desarrollado con ❤️

Sistema de Gestión Odontológica - Desarrollado con React, Supabase y Bootstrap 5

**Versión**: 1.0.0
**Última actualización**: Enero 2025

---

<div align="center">

### ⭐ Si te gusta este proyecto, ¡dale una estrella en GitHub! ⭐

</div>
