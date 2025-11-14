-- ============================================
-- VERIFICAR Y REPARAR SECUENCIA DE APPOINTMENT_NUMBER
-- ============================================

-- 1. Verificar si la secuencia existe
SELECT
  'Verificando secuencia...' as status,
  EXISTS (
    SELECT 1
    FROM pg_sequences
    WHERE schemaname = 'public'
    AND sequencename = 'citas_medicas_appointment_number_seq'
  ) as secuencia_existe;

-- 2. Crear la secuencia si no existe
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_sequences
    WHERE schemaname = 'public'
    AND sequencename = 'citas_medicas_appointment_number_seq'
  ) THEN
    CREATE SEQUENCE public.citas_medicas_appointment_number_seq
      START WITH 1
      INCREMENT BY 1
      NO MAXVALUE
      NO MINVALUE
      CACHE 1;

    RAISE NOTICE 'Secuencia creada exitosamente';
  ELSE
    RAISE NOTICE 'La secuencia ya existe';
  END IF;
END $$;

-- 3. Verificar si appointment_number tiene el DEFAULT correcto
SELECT
  'Verificando columna appointment_number...' as status,
  column_name,
  data_type,
  column_default,
  is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'citas_medicas'
  AND column_name = 'appointment_number';

-- 4. Asignar el DEFAULT a la columna si no lo tiene
DO $$
BEGIN
  -- Verificar si la columna tiene DEFAULT
  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'citas_medicas'
      AND column_name = 'appointment_number'
      AND column_default LIKE '%nextval%'
  ) THEN
    -- Asignar DEFAULT a la columna
    ALTER TABLE public.citas_medicas
      ALTER COLUMN appointment_number SET DEFAULT nextval('public.citas_medicas_appointment_number_seq'::regclass);

    RAISE NOTICE 'DEFAULT asignado a appointment_number';
  ELSE
    RAISE NOTICE 'appointment_number ya tiene DEFAULT configurado';
  END IF;
END $$;

-- 5. Si hay registros sin appointment_number, asignarlos
DO $$
DECLARE
  registros_sin_numero INTEGER;
BEGIN
  SELECT COUNT(*) INTO registros_sin_numero
  FROM public.citas_medicas
  WHERE appointment_number IS NULL;

  IF registros_sin_numero > 0 THEN
    -- Asignar números a registros existentes
    WITH citas_ordenadas AS (
      SELECT id, ROW_NUMBER() OVER (ORDER BY created_at ASC) as nuevo_numero
      FROM public.citas_medicas
      WHERE appointment_number IS NULL
    )
    UPDATE public.citas_medicas c
    SET appointment_number = co.nuevo_numero
    FROM citas_ordenadas co
    WHERE c.id = co.id;

    RAISE NOTICE 'Se asignaron números a % registros', registros_sin_numero;
  ELSE
    RAISE NOTICE 'Todos los registros ya tienen appointment_number';
  END IF;
END $$;

-- 6. Ajustar la secuencia al último número usado
DO $$
DECLARE
  max_numero BIGINT;
BEGIN
  SELECT COALESCE(MAX(appointment_number), 0) INTO max_numero
  FROM public.citas_medicas;

  IF max_numero > 0 THEN
    PERFORM setval('public.citas_medicas_appointment_number_seq', max_numero);
    RAISE NOTICE 'Secuencia ajustada al número %', max_numero;
  END IF;
END $$;

-- 7. Verificación final
SELECT
  'Estado final de la tabla' as info,
  (SELECT COUNT(*) FROM public.citas_medicas) as total_citas,
  (SELECT COUNT(*) FROM public.citas_medicas WHERE appointment_number IS NULL) as citas_sin_numero,
  (SELECT MAX(appointment_number) FROM public.citas_medicas) as ultimo_numero,
  (SELECT last_value FROM public.citas_medicas_appointment_number_seq) as siguiente_numero;

-- 8. Mostrar estructura de la columna
SELECT
  'Estructura de appointment_number' as info,
  column_name,
  data_type,
  column_default,
  is_nullable,
  character_maximum_length
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'citas_medicas'
  AND column_name = 'appointment_number';

-- 9. Probar que la secuencia funciona (solo consulta, no inserta)
SELECT
  'Prueba de secuencia' as info,
  nextval('public.citas_medicas_appointment_number_seq') as proximo_numero;

-- IMPORTANTE: El nextval() anterior consumió un número de la secuencia.
-- Si no deseas esto, puedes resetear manualmente:
-- SELECT setval('public.citas_medicas_appointment_number_seq', (SELECT MAX(appointment_number) FROM public.citas_medicas));
