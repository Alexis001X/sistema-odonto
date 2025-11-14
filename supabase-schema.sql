-- ============================================
-- SCHEMA PARA SISTEMA DE GESTIÓN ODONTOLÓGICA
-- ============================================

-- Tabla de perfiles de usuarios (extendida de auth.users)
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID REFERENCES auth.users(id) PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  full_name TEXT,
  role TEXT DEFAULT 'user',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Habilitar RLS (Row Level Security)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Políticas de seguridad para profiles
CREATE POLICY "Los usuarios pueden ver su propio perfil"
  ON public.profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Los usuarios pueden actualizar su propio perfil"
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id);

-- Función para crear perfil automáticamente al registrar usuario
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name)
  VALUES (NEW.id, NEW.email, NEW.raw_user_meta_data->>'full_name');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger para crear perfil
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================
-- TABLA DE CLIENTES
-- ============================================

CREATE TABLE IF NOT EXISTS public.clientes (
  id_cliente UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  id_number TEXT UNIQUE NOT NULL,
  phone TEXT,
  email TEXT,
  direccion TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Habilitar RLS para clientes
ALTER TABLE public.clientes ENABLE ROW LEVEL SECURITY;

-- Políticas de seguridad para clientes
-- Los usuarios autenticados pueden ver todos los clientes
CREATE POLICY "Usuarios autenticados pueden ver clientes"
  ON public.clientes FOR SELECT
  TO authenticated
  USING (true);

-- Los usuarios autenticados pueden insertar clientes
CREATE POLICY "Usuarios autenticados pueden crear clientes"
  ON public.clientes FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- Los usuarios autenticados pueden actualizar clientes
CREATE POLICY "Usuarios autenticados pueden actualizar clientes"
  ON public.clientes FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- Los usuarios autenticados pueden eliminar clientes
CREATE POLICY "Usuarios autenticados pueden eliminar clientes"
  ON public.clientes FOR DELETE
  TO authenticated
  USING (true);

-- Índices para mejorar rendimiento
CREATE INDEX IF NOT EXISTS idx_clientes_id_number ON public.clientes(id_number);
CREATE INDEX IF NOT EXISTS idx_clientes_name ON public.clientes(name);
CREATE INDEX IF NOT EXISTS idx_clientes_created_at ON public.clientes(created_at DESC);

-- Función para actualizar updated_at automáticamente
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger para actualizar updated_at en clientes
DROP TRIGGER IF EXISTS on_clientes_updated ON public.clientes;
CREATE TRIGGER on_clientes_updated
  BEFORE UPDATE ON public.clientes
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ============================================
-- TABLA DE CITAS MÉDICAS
-- ============================================

-- Crear secuencia para appointment_number
CREATE SEQUENCE IF NOT EXISTS public.citas_medicas_appointment_number_seq
  START WITH 1
  INCREMENT BY 1
  NO MAXVALUE
  NO MINVALUE
  CACHE 1;

CREATE TABLE IF NOT EXISTS public.citas_medicas (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  appointment_number BIGINT DEFAULT nextval('public.citas_medicas_appointment_number_seq'::regclass) UNIQUE NOT NULL,
  client_name TEXT NOT NULL,
  client_id_number TEXT NOT NULL,
  appointment_at TIMESTAMP WITH TIME ZONE NOT NULL,
  reason TEXT NOT NULL,
  cost DECIMAL(10, 2),
  attending_doctor TEXT,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  -- Referencia a clientes
  FOREIGN KEY (client_id_number) REFERENCES public.clientes(id_number) ON DELETE CASCADE
);

-- Habilitar RLS para citas_medicas
ALTER TABLE public.citas_medicas ENABLE ROW LEVEL SECURITY;

-- Políticas de seguridad para citas_medicas
CREATE POLICY "citas_medicas_select_authenticated"
  ON public.citas_medicas FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "citas_medicas_insert_authenticated"
  ON public.citas_medicas FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "citas_medicas_update_authenticated"
  ON public.citas_medicas FOR UPDATE
  TO authenticated
  USING (true);

CREATE POLICY "citas_medicas_delete_authenticated"
  ON public.citas_medicas FOR DELETE
  TO authenticated
  USING (true);

-- Índices para mejorar rendimiento
CREATE INDEX IF NOT EXISTS idx_citas_medicas_id ON public.citas_medicas(id);
CREATE INDEX IF NOT EXISTS idx_citas_medicas_appointment_number ON public.citas_medicas(appointment_number);
CREATE INDEX IF NOT EXISTS idx_citas_medicas_appointment_at ON public.citas_medicas(appointment_at);
CREATE INDEX IF NOT EXISTS idx_citas_medicas_client_id_number ON public.citas_medicas(client_id_number);
CREATE INDEX IF NOT EXISTS idx_citas_medicas_date ON public.citas_medicas(DATE(appointment_at));
CREATE INDEX IF NOT EXISTS idx_citas_medicas_attending_doctor ON public.citas_medicas(attending_doctor);

-- Índice único para evitar citas duplicadas en la misma hora del mismo día
CREATE UNIQUE INDEX IF NOT EXISTS idx_citas_medicas_unique_datetime
  ON public.citas_medicas(DATE(appointment_at), EXTRACT(HOUR FROM appointment_at));

-- Trigger para actualizar updated_at en citas_medicas
DROP TRIGGER IF EXISTS on_citas_medicas_updated ON public.citas_medicas;
CREATE TRIGGER on_citas_medicas_updated
  BEFORE UPDATE ON public.citas_medicas
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- Función para validar que no haya citas duplicadas en la misma hora
CREATE OR REPLACE FUNCTION public.validate_appointment_time()
RETURNS TRIGGER AS $$
DECLARE
  existing_appointment_count INTEGER;
BEGIN
  -- Contar citas existentes en la misma fecha y hora
  SELECT COUNT(*)
  INTO existing_appointment_count
  FROM public.citas_medicas
  WHERE DATE(appointment_at) = DATE(NEW.appointment_at)
    AND EXTRACT(HOUR FROM appointment_at) = EXTRACT(HOUR FROM NEW.appointment_at)
    AND id != COALESCE(NEW.id, gen_random_uuid());

  IF existing_appointment_count > 0 THEN
    RAISE EXCEPTION 'Ya existe una cita programada para esta hora. Por favor seleccione otra hora.';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger para validar antes de insertar o actualizar
DROP TRIGGER IF EXISTS validate_appointment_time_trigger ON public.citas_medicas;
CREATE TRIGGER validate_appointment_time_trigger
  BEFORE INSERT OR UPDATE ON public.citas_medicas
  FOR EACH ROW EXECUTE FUNCTION public.validate_appointment_time();
