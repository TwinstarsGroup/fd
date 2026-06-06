-- FinanceDesk — Supabase Schema
-- Run this entire file in your Supabase SQL Editor

-- ─────────────────────────────────────────────────────────────────────────────
-- TABLES
-- ─────────────────────────────────────────────────────────────────────────────

create table if not exists receipts (
  id             uuid primary key default gen_random_uuid(),
  receipt_no     text unique not null,          -- e.g. REC-2026-0042
  description    text not null,
  amount         numeric(12,2) not null,
  date           date not null,
  status         text not null default 'pending'
                   check (status in ('pending','approved','rejected')),
  category       text default 'general',
  notes          text,
  attachment_url text,
  created_by     uuid references auth.users(id),
  created_at     timestamptz default now(),
  updated_at     timestamptz default now()
);

create table if not exists vouchers (
  id             uuid primary key default gen_random_uuid(),
  voucher_no     text unique not null,          -- e.g. VCH-2026-0011
  description    text not null,
  amount         numeric(12,2) not null,
  date           date not null,
  type           text not null default 'payment'
                   check (type in ('payment','receipt','journal','cash','contra')),
  party          text,
  notes          text,
  attachment_url text,
  created_by     uuid references auth.users(id),
  created_at     timestamptz default now(),
  updated_at     timestamptz default now()
);

create table if not exists employees (
  id             uuid primary key default gen_random_uuid(),
  emp_code       text unique,                   -- e.g. EMP-0001
  name           text not null,
  email          text not null,
  phone          text,
  department     text,
  role           text,
  doj            date,                          -- date of joining
  status         text not null default 'active'
                   check (status in ('active','inactive')),
  basic_salary   numeric(12,2),
  bank_account   text,
  pan            text,
  pf_account     text,
  created_at     timestamptz default now(),
  updated_at     timestamptz default now()
);

create table if not exists salary_slips (
  id                uuid primary key default gen_random_uuid(),
  employee_id       uuid not null references employees(id),
  month             text not null,              -- format: YYYY-MM
  working_days      int default 26,
  basic             numeric(12,2) default 0,
  hra               numeric(12,2) default 0,
  special_allowance numeric(12,2) default 0,
  other_allowance   numeric(12,2) default 0,
  pf                numeric(12,2) default 0,
  esi               numeric(12,2) default 0,
  tds               numeric(12,2) default 0,
  other_deductions  numeric(12,2) default 0,
  gross             numeric(12,2) generated always as
                      (basic + hra + special_allowance + other_allowance) stored,
  total_deductions  numeric(12,2) generated always as
                      (pf + esi + tds + other_deductions) stored,
  net               numeric(12,2) generated always as
                      (basic + hra + special_allowance + other_allowance
                       - pf - esi - tds - other_deductions) stored,
  emailed_at        timestamptz,
  created_at        timestamptz default now(),
  unique (employee_id, month)
);

-- ─────────────────────────────────────────────────────────────────────────────
-- INDEXES
-- ─────────────────────────────────────────────────────────────────────────────

create index if not exists idx_receipts_no      on receipts(receipt_no);
create index if not exists idx_receipts_date    on receipts(date desc);
create index if not exists idx_vouchers_no      on vouchers(voucher_no);
create index if not exists idx_vouchers_date    on vouchers(date desc);
create index if not exists idx_employees_code   on employees(emp_code);
create index if not exists idx_salary_emp_month on salary_slips(employee_id, month);

-- ─────────────────────────────────────────────────────────────────────────────
-- AUTO-UPDATE updated_at
-- ─────────────────────────────────────────────────────────────────────────────

create or replace function update_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_receipts_updated_at  on receipts;
drop trigger if exists trg_vouchers_updated_at  on vouchers;
drop trigger if exists trg_employees_updated_at on employees;

create trigger trg_receipts_updated_at  before update on receipts  for each row execute function update_updated_at();
create trigger trg_vouchers_updated_at  before update on vouchers  for each row execute function update_updated_at();
create trigger trg_employees_updated_at before update on employees for each row execute function update_updated_at();

-- ─────────────────────────────────────────────────────────────────────────────
-- ROW-LEVEL SECURITY (RLS)
-- All operations require authentication. Adjust policies as needed.
-- ─────────────────────────────────────────────────────────────────────────────

alter table receipts     enable row level security;
alter table vouchers     enable row level security;
alter table employees    enable row level security;
alter table salary_slips enable row level security;

-- Allow any authenticated user to read all rows
create policy "auth read receipts"     on receipts     for select using (auth.role() = 'authenticated');
create policy "auth read vouchers"     on vouchers     for select using (auth.role() = 'authenticated');
create policy "auth read employees"    on employees    for select using (auth.role() = 'authenticated');
create policy "auth read salary_slips" on salary_slips for select using (auth.role() = 'authenticated');

-- Allow any authenticated user to insert/update/delete
create policy "auth write receipts"     on receipts     for all using (auth.role() = 'authenticated');
create policy "auth write vouchers"     on vouchers     for all using (auth.role() = 'authenticated');
create policy "auth write employees"    on employees    for all using (auth.role() = 'authenticated');
create policy "auth write salary_slips" on salary_slips for all using (auth.role() = 'authenticated');

-- ─────────────────────────────────────────────────────────────────────────────
-- STORAGE BUCKET
-- Run this separately in Supabase Dashboard > Storage > New Bucket
-- OR uncomment and run via SQL:
-- ─────────────────────────────────────────────────────────────────────────────

-- insert into storage.buckets (id, name, public)
-- values ('attachments', 'attachments', true)
-- on conflict do nothing;

-- create policy "auth upload attachments"
--   on storage.objects for insert
--   with check (bucket_id = 'attachments' and auth.role() = 'authenticated');

-- create policy "public read attachments"
--   on storage.objects for select
--   using (bucket_id = 'attachments');
