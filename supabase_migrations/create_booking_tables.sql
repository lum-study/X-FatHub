create table public.packages (
  id uuid not null default gen_random_uuid (),
  name text not null,
  description text null,
  price numeric not null,
  sessions_count integer not null,
  badge text null,
  is_featured boolean null default false,
  icon_name text null default 'fitness_center'::text,
  allowed_class_names text[] not null default '{}',
  constraint packages_pkey primary key (id)
) TABLESPACE pg_default;

create table public.gym_slots (
  id uuid not null default gen_random_uuid (),
  start_time timestamp with time zone not null,
  end_time timestamp with time zone not null,
  class_name text not null,
  coach_name text null,
  location text null,
  total_spots integer null default 20,
  occupied_spots integer null default 0,
  constraint gym_slots_pkey primary key (id)
) TABLESPACE pg_default;

create table public.bookings (
  id uuid not null default gen_random_uuid (),
  user_id uuid not null,
  package_id uuid null,
  slot_id uuid null,
  booking_date timestamp with time zone null default now(),
  status text null,
  total_paid numeric null,
  session_number integer null default 1,
  constraint bookings_pkey primary key (id),
  constraint bookings_package_id_fkey foreign KEY (package_id) references packages (id),
  constraint bookings_slot_id_fkey foreign KEY (slot_id) references gym_slots (id),
  constraint bookings_user_id_fkey foreign KEY (user_id) references auth.users (id),
  constraint bookings_status_check check (
    (
      status = any (
        array[
          'upcoming'::text,
          'completed'::text,
          'cancelled'::text,
          'pendingRefund'::text
        ]
      )
    )
  )
) TABLESPACE pg_default;