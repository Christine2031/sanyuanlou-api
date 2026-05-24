-- ============================================================
-- 三元楼 1846 — 在 halfsphere-db 里只需新增这一张表
-- 在 Supabase Dashboard → SQL Editor 里执行
--
-- 不要动现有的表：
--   registration_requests  (Halfsphere 注册审批队列)
--   user_tiers             (Halfsphere 平台 tier)
--   auth.users             (Supabase Auth 主身份)
-- ============================================================

-- 三元楼 VIP 专属数据表 (通过 user_id 挂到 auth.users)
create table if not exists sanyuanlou_members (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid references auth.users(id) on delete set null, -- Halfsphere 身份
  email         text not null unique,   -- 冗余存储，方便快速查询
  phone         text,
  cid           text unique not null,   -- 三元楼专属编号 SYL-1846-XXXX-BLA
  tier          text not null check (tier in ('Gold','Platinum','BlackCard')),
  brand_tags    text[] default array['三元楼_1846']::text[],
  registered_at date default current_date,
  created_at    timestamptz default now()
);

-- 索引
create index if not exists idx_syl_members_user_id on sanyuanlou_members(user_id);
create index if not exists idx_syl_members_cid     on sanyuanlou_members(cid);
create index if not exists idx_syl_members_email   on sanyuanlou_members(email);

-- RLS (后端用 service_role key，不受限制)
alter table sanyuanlou_members enable row level security;

-- ============================================================
-- Tier 映射说明 (写入 user_tiers 时用)
--   三元楼 Gold       → Halfsphere tier: 'bronze'
--   三元楼 Platinum   → Halfsphere tier: 'silver'
--   三元楼 BlackCard  → Halfsphere tier: 'gold'
-- ============================================================
