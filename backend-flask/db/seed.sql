-- this file was manually created
INSERT INTO public.users (display_name, handle, email, cognito_user_id)
VALUES
  ('Sunyoung Park', 'Sunyoung' , 'scarlettp0420@gmail.com', 'MOCK'),
  ('Scarlett Park', 'Scarlett', 'scarlett.p42094@gmail.com', 'MOCK'),
  ('Londo Mollari', 'londo', 'lmollari@centari.com', 'MOCK');

INSERT INTO public.activities (user_uuid, message, expires_at)
VALUES
  (
    (SELECT uuid from public.users WHERE users.handle = 'Sunyoung' LIMIT 1),
    'This was imported as seed data!',
    current_timestamp + interval '10 day'
  )