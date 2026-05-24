-- ============================================================
-- 三元楼 × 半球 共享会员库  (Supabase / PostgreSQL)
-- 在 Supabase Dashboard → SQL Editor 里执行此文件
-- ============================================================

-- 核心会员表 (halfsphere.com 和所有旗下品牌共用)
create table if not exists members (
  id            uuid primary key default gen_random_uuid(),
  email         text unique not null,          -- 跨平台身份主键
  name          text not null,
  phone         text,
  created_at    timestamptz default now(),
  updated_at    timestamptz default now()
);

-- 三元楼专属会员数据 (通过 email 关联 members 表)
create table if not exists sanyuanlou_members (
  id              uuid primary key default gen_random_uuid(),
  email           text not null references members(email) on update cascade,
  cid             text unique not null,        -- SYL-1846-XXXX-BLA
  tier            text not null check (tier in ('Gold','Platinum','BlackCard')),
  registered_at   date default current_date,
  brand_tags      text[] default array['三元楼']::text[],
  created_at      timestamptz default now()
);

-- 快速查询索引
create index if not exists idx_members_email          on members(email);
create index if not exists idx_sanyuanlou_members_cid on sanyuanlou_members(cid);
create index if not exists idx_sanyuanlou_members_email on sanyuanlou_members(email);

-- 自动更新 updated_at
create or replace function set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create or replace trigger members_updated_at
  before update on members
  for each row execute function set_updated_at();

-- ============================================================
-- Row Level Security (可选，后端用 service_role_key 绕过)
-- ============================================================
alter table members           enable row level security;
alter table sanyuanlou_members enable row level security;

-- service_role key 有完全权限，以下策略仅对 anon/authenticated 生效
-- (后端 API 用 service_role key，不受此限制)
