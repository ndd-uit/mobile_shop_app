# Supabase setup

1. Create a Supabase project.
2. Open **SQL Editor** and run `schema.sql`.
3. In **Authentication > Providers > Email**, disable **Confirm email**. The app maps phone numbers to internal email aliases so users can sign in with phone + password.
4. Copy the Project URL and anon key from **Project Settings > API** into `.env`:

```env
SUPABASE_URL=https://your-project-ref.supabase.co
SUPABASE_ANON_KEY=eyJ...
```

Never put the service-role key in the Flutter app.
