-- ============================================
-- SCRIPT DE REPARACIÓN URGENTE
-- Soluciona el error: null value in column "appointment_number"
-- ============================================

-- OPCIÓN 1: Si NO tienes datos importantes, ejecuta esto (MÁS SIMPLE)
-- ============================================
-- Descomentar las siguientes líneas si quieres borrar todo y empezar de cero:

/*
DROP TABLE IF EXISTS public.citas_medicas CASCADE;

-- Crear secuencia para appointment_number
CREATE SEQUENCE public.citas_medicas_appointment_number_seq
  START WITH 1
  INCREMENT BY 1
  NO MAXVALUE
  NO MINVALUE
  CACHE 1;

CREATE TABLE public.citas_medicas (
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
  FOREIGN KEY (client_id_number) REFERENCES public.clientes(id_number) ON DELETE CASCADE
);

-- Habilitar RLS
ALTER TABLE public.citas_medicas ENABLE ROW LEVEL SECURITY;

-- Políticas de seguridad
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

-- Índices
CREATE INDEX idx_citas_medicas_id ON public.citas_medicas(id);
CREATE INDEX idx_citas_medicas_appointment_number ON public.citas_medicas(appointment_number);
CREATE INDEX idx_citas_medicas_appointment_at ON public.citas_medicas(appointment_at);
CREATE INDEX idx_citas_medicas_client_id_number ON public.citas_medicas(client_id_number);
CREATE INDEX idx_citas_medicas_date ON public.citas_medicas(DATE(appointment_at));

-- Índice único para evitar citas duplicadas
CREATE UNIQUE INDEX idx_citas_medicas_unique_datetime
  ON public.citas_medicas(DATE(appointment_at), EXTRACT(HOUR FROM appointment_at));

-- Trigger para updated_at
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS on_citas_medicas_updated ON public.citas_medicas;
CREATE TRIGGER on_citas_medicas_updated
  BEFORE UPDATE ON public.citas_medicas
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- Función de validación de horarios
CREATE OR REPLACE FUNCTION public.validate_appointment_time()
RETURNS TRIGGER AS $$
DECLARE
  existing_appointment_count INTEGER;
BEGIN
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

DROP TRIGGER IF EXISTS validate_appointment_time_trigger ON public.citas_medicas;
CREATE TRIGGER validate_appointment_time_trigger
  BEFORE INSERT OR UPDATE ON public.citas_medicas
  FOR EACH ROW EXECUTE FUNCTION public.validate_appointment_time();
*/

-- ============================================
-- OPCIÓN 2: Si TIENES datos que quieres conservar
-- ============================================
-- Ejecuta este bloque completo:

DO $$
BEGIN
  -- 1. Verificar si la tabla existe y tiene la estructura antigua
  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_name = 'citas_medicas'
    AND column_name = 'appointment_number'
    AND data_type = 'uuid'
  ) THEN

    -- La tabla tiene la estructura antigua, necesitamos migrar

    -- 2. Crear secuencia
    CREATE SEQUENCE IF NOT EXISTS public.citas_medicas_appointment_number_seq
      START WITH 1
      INCREMENT BY 1;

    -- 3. Crear tabla nueva con estructura correcta
    CREATE TABLE public.citas_medicas_temp (
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
      FOREIGN KEY (client_id_number) REFERENCES public.clientes(id_number) ON DELETE CASCADE
    );

    -- 4. Copiar datos existentes (el appointment_number se genera automáticamente)
    INSERT INTO public.citas_medicas_temp (
      client_name,
      client_id_number,
      appointment_at,
      reason,
      cost,
      attending_doctor,
      notes,
      created_at,
      updated_at
    )
    SELECT
      client_name,
      client_id_number,
      appointment_at,
      reason,
      cost,
      attending_doctor,
      notes,
      created_at,
      updated_at
    FROM public.citas_medicas
    ORDER BY created_at ASC;

    -- 5. Eliminar tabla antigua
    DROP TABLE public.citas_medicas CASCADE;

    -- 6. Renombrar tabla temporal
    ALTER TABLE public.citas_medicas_temp RENAME TO citas_medicas;

    -- 7. Recrear políticas RLS
    ALTER TABLE public.citas_medicas ENABLE ROW LEVEL SECURITY;

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

    -- 8. Crear índices
    CREATE INDEX idx_citas_medicas_id ON public.citas_medicas(id);
    CREATE INDEX idx_citas_medicas_appointment_number ON public.citas_medicas(appointment_number);
    CREATE INDEX idx_citas_medicas_appointment_at ON public.citas_medicas(appointment_at);
    CREATE INDEX idx_citas_medicas_client_id_number ON public.citas_medicas(client_id_number);
    CREATE INDEX idx_citas_medicas_date ON public.citas_medicas(DATE(appointment_at));

    CREATE UNIQUE INDEX idx_citas_medicas_unique_datetime
      ON public.citas_medicas(DATE(appointment_at), EXTRACT(HOUR FROM appointment_at));

    -- 9. Crear triggers
    CREATE OR REPLACE FUNCTION public.handle_updated_at()
    RETURNS TRIGGER AS $func$
    BEGIN
      NEW.updated_at = NOW();
      RETURN NEW;
    END;
    $func$ LANGUAGE plpgsql;

    DROP TRIGGER IF EXISTS on_citas_medicas_updated ON public.citas_medicas;
    CREATE TRIGGER on_citas_medicas_updated
      BEFORE UPDATE ON public.citas_medicas
      FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

    CREATE OR REPLACE FUNCTION public.validate_appointment_time()
    RETURNS TRIGGER AS $func$
    DECLARE
      existing_appointment_count INTEGER;
    BEGIN
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
    $func$ LANGUAGE plpgsql;

    DROP TRIGGER IF EXISTS validate_appointment_time_trigger ON public.citas_medicas;
    CREATE TRIGGER validate_appointment_time_trigger
      BEFORE INSERT OR UPDATE ON public.citas_medicas
      FOR EACH ROW EXECUTE FUNCTION public.validate_appointment_time();

    RAISE NOTICE 'Migración completada exitosamente. Datos preservados.';

  ELSE
    RAISE NOTICE 'La tabla ya tiene la estructura correcta o no existe.';
  END IF;
END $$;

-- Verificar resultado
SELECT
  'Estado de la tabla' as info,
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_name = 'citas_medicas'
ORDER BY ordinal_position;
