UPDATE public.users
SET role = 'ADMIN', status = 'ACTIVE'
WHERE id = '32c01c9f-8777-4c8d-87bd-17d27e543dae' OR lower(email) = 'admin@gmail.com';

