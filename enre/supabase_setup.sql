-- One-time setup for the ENRE dashboard's "Saved runs" (Supabase SQL editor -> Run).
-- Anyone with the page can add a run and read all runs; nobody can edit or delete
-- through the public key (do that from the Supabase dashboard).

create table if not exists public.runs (
  id         bigint generated always as identity primary key,
  created_at timestamptz not null default now(),
  name       text not null check (char_length(name) between 1 and 80),
  note       text check (char_length(note) <= 500),
  file_name  text check (char_length(file_name) <= 200),
  path       text not null unique check (path ~ '^[0-9a-z_-]+\.csv$'),
  n_rows     int,
  models     jsonb  -- {model: {mae, rmse, f1, winkler, cov}} over the last 182 forecast days, 48 h
);
alter table public.runs enable row level security;
create policy "anyone reads runs" on public.runs for select to anon using (true);
create policy "anyone adds runs"  on public.runs for insert to anon with check (true);

-- Full CSVs live in a public bucket, 10 MB cap, CSV only, insert-only for the public key.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('enre-uploads', 'enre-uploads', true, 10485760, array['text/csv'])
on conflict (id) do nothing;
create policy "anyone uploads csv" on storage.objects for insert to anon
  with check (bucket_id = 'enre-uploads');

-- Newer projects do not grant table access to anon by default; RLS above still limits it to read + insert.
grant select, insert on public.runs to anon;
grant usage on sequence public.runs_id_seq to anon;
