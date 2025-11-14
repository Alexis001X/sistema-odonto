# 🔒 Guía de Seguridad

## ⚠️ IMPORTANTE: Antes de Subir a GitHub

### ✅ Checklist de Seguridad

Antes de hacer `git push`, verifica que:

- [x] El archivo `.env` NO está en el repositorio (está en `.gitignore`)
- [x] Las credenciales de Supabase están solo en `.env` (no en el código)
- [x] El archivo `.env.example` solo tiene placeholders
- [x] No hay claves API hardcodeadas en ningún archivo `.js` o `.jsx`
- [x] No hay contraseñas en comentarios del código
- [x] Los archivos de build (`dist/`, `node_modules/`) están ignorados

---

## 🔐 Variables de Entorno

### ❌ NUNCA Hagas Esto:

```javascript
// ❌ MAL - No hardcodear credenciales
const supabaseUrl = 'https://ifrrkexqcdgfcnyzpojg.supabase.co'
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...'
```

### ✅ Siempre Haz Esto:

```javascript
// ✅ BIEN - Usar variables de entorno
const supabaseUrl = import.meta.env.VITE_SUPABASE_URL
const supabaseKey = import.meta.env.VITE_SUPABASE_ANON_KEY
```

---

## 📁 Archivos Protegidos

Los siguientes archivos están en `.gitignore` y **NUNCA** deben subirse a GitHub:

```
.env
.env.local
.env.production
.env.development
*.pem
*.key
*.cert
supabase-credentials.json
```

---

## 🛡️ Seguridad de Supabase

### Row Level Security (RLS)

**SIEMPRE** habilita RLS en tus tablas:

```sql
ALTER TABLE public.clientes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.citas_medicas ENABLE ROW LEVEL SECURITY;
```

### Políticas de Acceso

Las políticas actuales permiten acceso solo a usuarios autenticados:

```sql
CREATE POLICY "clientes_select_authenticated"
  ON public.clientes FOR SELECT
  TO authenticated
  USING (true);
```

### Tipos de Claves en Supabase

| Clave | Uso | Seguridad |
|-------|-----|-----------|
| `anon` (public) | Frontend público | ✅ Seguro para GitHub |
| `service_role` | Backend/Admin | ❌ NUNCA exponer |

---

## 🚨 Qué Hacer Si Expones Credenciales

Si accidentalmente subes el archivo `.env` a GitHub:

### 1. Eliminar Inmediatamente

```bash
# Eliminar archivo del historial de git
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch .env" \
  --prune-empty --tag-name-filter cat -- --all

# Forzar push
git push origin --force --all
```

### 2. Rotar Credenciales en Supabase

1. Ve a Supabase Dashboard
2. **Settings** → **API**
3. **Reset** la clave anon
4. Actualiza tu `.env` local
5. Actualiza las variables en Vercel/Netlify

### 3. Revisar Accesos

1. **Supabase** → **Auth** → **Users**
2. Revisa usuarios no autorizados
3. Elimina sesiones activas sospechosas

---

## 🔍 Auditoría de Código

### Buscar Credenciales Hardcodeadas

```bash
# Buscar URLs de Supabase
grep -r "supabase.co" src/

# Buscar tokens JWT
grep -r "eyJ" src/

# Buscar claves API
grep -r "ANON_KEY" src/
```

Si encuentras coincidencias, asegúrate de que sean solo variables de entorno.

---

## 🌐 Seguridad en Producción

### Vercel/Netlify

1. **Nunca** expongas las variables de entorno en logs
2. Usa el dashboard para configurar variables
3. No uses `console.log()` con datos sensibles en producción

### Headers de Seguridad

Considera agregar en `vercel.json`:

```json
{
  "headers": [
    {
      "source": "/(.*)",
      "headers": [
        {
          "key": "X-Frame-Options",
          "value": "DENY"
        },
        {
          "key": "X-Content-Type-Options",
          "value": "nosniff"
        },
        {
          "key": "Referrer-Policy",
          "value": "strict-origin-when-cross-origin"
        }
      ]
    }
  ]
}
```

---

## 👥 Autenticación de Usuarios

### Contraseñas

- ✅ Supabase maneja el hashing automáticamente
- ✅ Usa contraseñas fuertes (mínimo 8 caracteres)
- ✅ Implementa recuperación de contraseña

### Sesiones

- Las sesiones expiran automáticamente
- Supabase maneja tokens JWT
- Implementa logout correcto

---

## 📊 Monitoreo

### Supabase Dashboard

Revisa regularmente:

1. **Auth** → Usuarios activos
2. **Database** → Logs de queries
3. **API** → Uso de endpoints
4. **Storage** → Archivos subidos

### Alertas

Considera configurar alertas para:
- Múltiples intentos de login fallidos
- Acceso desde IPs inusuales
- Picos de tráfico anormales

---

## 🚫 Datos Sensibles

### NO Almacenar en la Base de Datos:

- ❌ Números de tarjetas de crédito completos
- ❌ Contraseñas en texto plano
- ❌ Información médica sin encriptar (HIPAA)
- ❌ Datos personales sensibles sin consentimiento

### SÍ Almacenar:

- ✅ Hashes de contraseñas (automático en Supabase)
- ✅ Tokens de sesión encriptados
- ✅ Referencias a archivos (no los archivos directamente)

---

## 📝 Mejores Prácticas

### 1. Principio de Menor Privilegio

```sql
-- Usuarios solo pueden ver SUS propios datos
CREATE POLICY "users_view_own_data"
  ON public.profiles FOR SELECT
  USING (auth.uid() = id);
```

### 2. Validación en Ambos Lados

- Frontend: Validación UX
- Backend/RLS: Validación de seguridad

### 3. Sanitización de Inputs

```javascript
// Siempre valida y sanitiza
const sanitizedInput = input.trim().replace(/[<>]/g, '')
```

### 4. HTTPS Obligatorio

- Supabase usa HTTPS por defecto
- Vercel/Netlify fuerzan HTTPS

---

## 🔄 Actualizar Dependencias

Mantén las dependencias actualizadas:

```bash
# Revisar vulnerabilidades
npm audit

# Actualizar automáticamente
npm audit fix

# Actualizar manualmente
npm update
```

---

## 📞 Reporte de Vulnerabilidades

Si encuentras una vulnerabilidad de seguridad:

1. **NO** la publiques en Issues públicos
2. Envía un email privado al mantenedor
3. Espera respuesta antes de divulgar

---

## ✅ Resumen Final

Antes de cada commit:

```bash
# 1. Verificar que .env no está staged
git status

# 2. Revisar cambios
git diff

# 3. Buscar credenciales accidentales
grep -r "eyJ" src/
grep -r "supabase.co" src/

# 4. Si todo está bien, commit
git add .
git commit -m "mensaje"
git push
```

---

## 🛡️ Mantente Seguro

- Revisa el `.gitignore` regularmente
- Audita el código antes de commits importantes
- Usa autenticación de dos factores en GitHub y Supabase
- Mantén las dependencias actualizadas
- Monitorea logs de acceso

---

**Última actualización**: Enero 2025
