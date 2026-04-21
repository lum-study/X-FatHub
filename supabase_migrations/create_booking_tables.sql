CREATE TABLE IF NOT EXISTS public.packages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  price NUMERIC NOT NULL,
  sessions_count INTEGER NOT NULL,
  badge TEXT,
  is_featured BOOLEAN NOT NULL DEFAULT FALSE,
  icon_name TEXT NOT NULL DEFAULT 'fitness_center',
  allowed_class_names TEXT[] NOT NULL DEFAULT '{}'
);

CREATE TABLE IF NOT EXISTS public.gyms (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  venue TEXT,
  address TEXT,
  status TEXT NOT NULL DEFAULT 'active',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT gyms_status_check CHECK (status = ANY (ARRAY['active', 'inactive']))
);

CREATE TABLE IF NOT EXISTS public.package_gyms (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  package_id UUID NOT NULL REFERENCES public.packages(id) ON DELETE CASCADE,
  gym_id UUID NOT NULL REFERENCES public.gyms(id) ON DELETE CASCADE,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT package_gyms_unique_package_gym UNIQUE (package_id, gym_id)
);

CREATE TABLE IF NOT EXISTS public.gym_slots (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  gym_id UUID NOT NULL REFERENCES public.gyms(id) ON DELETE CASCADE,
  start_time TIMESTAMPTZ NOT NULL,
  end_time TIMESTAMPTZ NOT NULL,
  class_name TEXT NOT NULL,
  coach_name TEXT,
  location TEXT,
  total_spots INTEGER NOT NULL DEFAULT 20,
  occupied_spots INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT gym_slots_time_check CHECK (end_time > start_time),
  CONSTRAINT gym_slots_capacity_check CHECK (occupied_spots >= 0 AND occupied_spots <= total_spots)
);

CREATE TABLE IF NOT EXISTS public.bookings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  package_id UUID REFERENCES public.packages(id),
  slot_id UUID REFERENCES public.gym_slots(id),
  booking_date TIMESTAMPTZ NOT NULL DEFAULT now(),
  status TEXT NOT NULL DEFAULT 'upcoming',
  total_paid NUMERIC,
  session_number INTEGER NOT NULL DEFAULT 1,
  CONSTRAINT bookings_status_check CHECK (
    status = ANY (
      ARRAY[
        'upcoming'::TEXT,
        'completed'::TEXT,
        'cancelled'::TEXT,
        'pendingRefund'::TEXT
      ]
    )
  )
);

CREATE INDEX IF NOT EXISTS package_gyms_package_idx ON public.package_gyms(package_id);
CREATE INDEX IF NOT EXISTS package_gyms_gym_idx ON public.package_gyms(gym_id);
CREATE INDEX IF NOT EXISTS gym_slots_gym_time_idx ON public.gym_slots(gym_id, start_time);
CREATE INDEX IF NOT EXISTS bookings_user_booking_date_idx ON public.bookings(user_id, booking_date DESC);