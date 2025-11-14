# 📤 Guía para Subir el Proyecto a GitHub

## ✅ Checklist Pre-Commit

Antes de subir, verifica:

- [x] **.env está en .gitignore** ✅
- [x] **.env.example tiene solo placeholders** ✅
- [x] **README.md está actualizado** ✅
- [x] **Documentación completa** ✅
- [x] **No hay credenciales hardcodeadas** ✅
- [x] **.gitignore configurado correctamente** ✅

---

## 🚀 Pasos para Subir a GitHub

### 1. Inicializar Git (si no está inicializado)

```bash
cd odonto-system
git init
```

### 2. Verificar Estado

```bash
# Ver qué archivos se subirán
git status

# Verificar que .env NO aparece en la lista
# Si aparece, asegúrate de que está en .gitignore
```

### 3. Verificar .gitignore

```bash
# Verificar que .env está ignorado
cat .gitignore | grep .env

# Debe mostrar:
# .env
# .env.local
# .env.production
# etc.
```

### 4. Agregar Archivos

```bash
# Agregar todos los archivos (excepto los del .gitignore)
git add .

# Verificar nuevamente
git status
```

### 5. Hacer el Primer Commit

```bash
git commit -m "Initial commit: Sistema de Gestión Odontológica

- Sistema de autenticación con Supabase
- Gestión de clientes (CRUD completo)
- Gestión de citas con calendario
- Dashboard con gráficos y notificaciones
- Panel de recordatorios
- Diseño responsive con Bootstrap 5
"
```

### 6. Crear Repositorio en GitHub

1. Ve a [GitHub](https://github.com)
2. Haz clic en **New repository**
3. Nombre: `sistema-gestion-odontologica` (o el que prefieras)
4. Descripción: "Sistema de gestión para clínicas dentales con React y Supabase"
5. **Público** o **Privado** (tú eliges)
6. **NO** marques "Initialize with README" (ya tienes uno)
7. Haz clic en **Create repository**

### 7. Conectar con GitHub

```bash
# Agregar remote (sustituye <tu-usuario> por tu usuario de GitHub)
git remote add origin https://github.com/<tu-usuario>/sistema-gestion-odontologica.git

# Verificar
git remote -v
```

### 8. Subir a GitHub

```bash
# Push inicial
git branch -M main
git push -u origin main
```

---

## 🔒 Verificación de Seguridad Post-Push

### 1. Verificar en GitHub

1. Ve a tu repositorio en GitHub
2. Revisa los archivos
3. **Busca `.env`** → No debe aparecer
4. Verifica que `.env.example` solo tiene placeholders

### 2. Buscar Credenciales Expuestas

En GitHub, usa la búsqueda:

```
repo:<tu-usuario>/<repo-name> "eyJ"
repo:<tu-usuario>/<repo-name> "supabase.co"
```

Si encuentras algo:
- Elimina las credenciales del historial
- Rota las claves en Supabase
- Ver: [SECURITY.md](SECURITY.md)

---

## 📝 Commits Futuros

### Para Cambios Normales

```bash
git add .
git commit -m "Descripción del cambio"
git push
```

### Para Cambios Importantes

```bash
git add .
git commit -m "feat: Agregar módulo de pagos

- Registro de pagos por cita
- Historial de pagos
- Reportes mensuales
"
git push
```

### Convención de Commits

```
feat: Nueva funcionalidad
fix: Corrección de bug
docs: Cambios en documentación
style: Cambios de formato (no código)
refactor: Refactorización de código
test: Agregar o modificar tests
chore: Mantenimiento (dependencias, config)
```

---

## 🔄 Workflow Recomendado

### Desarrollo con Ramas

```bash
# Crear rama para nueva feature
git checkout -b feature/modulo-pagos

# Hacer cambios...
git add .
git commit -m "feat: Implementar módulo de pagos"

# Push de la rama
git push -u origin feature/modulo-pagos

# En GitHub: Crear Pull Request
# Revisar → Merge → Eliminar rama
```

### Mantener Actualizado

```bash
# Actualizar desde GitHub
git pull origin main

# Ver cambios
git log --oneline
```

---

## 🌐 Configurar Vercel

### Opción 1: Interfaz Web

1. Ve a [Vercel](https://vercel.com)
2. **Import Git Repository**
3. Conecta con GitHub
4. Selecciona tu repo
5. Configura las variables:
   ```
   VITE_SUPABASE_URL = (tu URL de Supabase)
   VITE_SUPABASE_ANON_KEY = (tu clave anon)
   ```
6. Deploy

### Opción 2: Auto-Deploy

Vercel detectará automáticamente:
- Framework: Vite
- Build Command: `npm run build`
- Output Directory: `dist`

Cada push a `main` hará un deploy automático.

---

## 📊 Estructura Recomendada del Repositorio

```
sistema-gestion-odontologica/
├── .github/
│   └── workflows/          # CI/CD (opcional)
├── src/
├── public/
├── docs/                   # Documentación adicional
│   ├── DASHBOARD-FEATURES.md
│   ├── SOLUCION-ZONA-HORARIA.md
│   └── INSTRUCCIONES-FINALES.md
├── *.sql                   # Scripts de base de datos
├── .env.example            # Template de variables
├── .gitignore              # Archivos ignorados
├── README.md               # Documentación principal
├── SECURITY.md             # Guía de seguridad
├── LICENSE                 # Licencia (MIT recomendada)
└── package.json
```

---

## 📄 Agregar Licencia

Crea un archivo `LICENSE`:

```bash
# Crear archivo LICENSE con licencia MIT
cat > LICENSE << 'EOF'
MIT License

Copyright (c) 2025 [Tu Nombre]

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
EOF
```

---

## 🏷️ Tags y Releases

### Crear Tag de Versión

```bash
# Tag para la primera versión
git tag -a v1.0.0 -m "Release v1.0.0 - Sistema base completo"
git push origin v1.0.0
```

### Crear Release en GitHub

1. Ve a tu repo → **Releases**
2. **Draft a new release**
3. Tag: `v1.0.0`
4. Title: "v1.0.0 - Sistema Base Completo"
5. Descripción:
   ```markdown
   ## Características Principales

   - ✅ Autenticación con Supabase
   - ✅ Gestión de clientes
   - ✅ Gestión de citas con calendario
   - ✅ Dashboard interactivo
   - ✅ Panel de notificaciones

   ## Instalación

   Ver [README.md](README.md)
   ```
6. **Publish release**

---

## 📣 Promocionar el Proyecto

### README Badges

Agregar al inicio del README.md:

```markdown
![Status](https://img.shields.io/badge/Status-En%20Desarrollo-yellow)
![Version](https://img.shields.io/badge/Version-1.0.0-blue)
![License](https://img.shields.io/badge/License-MIT-green)
```

### Topics en GitHub

Agrega estos topics al repo:
- `react`
- `supabase`
- `bootstrap`
- `dental-clinic`
- `appointment-system`
- `healthcare`
- `odontology`
- `vite`

---

## 🐛 Troubleshooting

### Error: "src refspec main does not match any"

```bash
git branch -M main
git push -u origin main
```

### Error: "Permission denied (publickey)"

Configura SSH o usa HTTPS con token:

```bash
# Cambiar a HTTPS
git remote set-url origin https://github.com/<usuario>/<repo>.git
```

### Error: ".env appears in git status"

```bash
# Eliminar del index
git rm --cached .env

# Verificar que está en .gitignore
echo ".env" >> .gitignore

# Commit
git add .gitignore
git commit -m "fix: Asegurar que .env está ignorado"
```

---

## ✅ Checklist Final

Antes del primer push:

- [ ] `.env` NO aparece en `git status`
- [ ] README.md está completo
- [ ] SECURITY.md creado
- [ ] .gitignore configurado
- [ ] Archivos SQL incluidos
- [ ] Documentación en `/docs/` (opcional)
- [ ] LICENSE agregado (opcional)
- [ ] Credenciales de prueba en README
- [ ] Todo está committed

---

## 🎉 ¡Listo para Subir!

Si completaste todos los pasos:

```bash
git push -u origin main
```

Tu código ahora está en GitHub de forma segura. 🚀

---

**Última actualización**: Enero 2025
