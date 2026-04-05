# 9. 技术架构（Technical Architecture）

---

### **A. 技术栈总览**

| **层级** | **技术选型** | **说明** |
| --- | --- | --- |
| **前端框架** | Flutter + Dart | 跨平台 UI 框架，一套代码支持 iOS + Android |
| **UI 组件库** | Material 3 + Cupertino | 自动适配 iOS/Android 原生风格 |
| **本地存储** | Isar | 高性能本地 NoSQL 数据库 |
| **后端服务** | Supabase | BaaS 服务，提供认证、数据库、API |
| **验证逻辑** | Cloudflare Workers | Serverless 函数，处理订阅验证 |
| **支付接入** | in_app_purchase + 支付宝/微信 | iOS 内购 + 国内支付 |

---

### **B. 架构设计**

`┌────────────────────────────────────────────────────────────┐
│                     用户设备 (Flutter App)                  │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │  核心数据   │  │  UI 渲染层   │  │   订阅状态缓存      │  │
│  │  (Isar)     │  │  (Flutter)  │  │   (Secure Storage)  │  │
│  │  - 决定     │  │             │  │                     │  │
│  │  - 选项组   │  │             │  │                     │  │
│  │  - 历史记录 │  │             │  │                     │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                              ↕
                    (加密 HTTPS 通信)
                              ↕
        ┌─────────────────────────┴─────────────────────────┐
       ↕                                                  ↕
┌───────────────────────┐                   ┌───────────────────────┐
│      Supabase         │                   │   Cloudflare Workers  │
├───────────────────────┤                   ├───────────────────────┤
│  ┌─────────────────┐  │                   │  ┌─────────────────┐  │
│  │  Authentication │  │                   │  │  订阅验证 API   │  │
│  │  (用户账号)     │  │                   │  │  - 收据验证     │  │
│  └─────────────────┘  │                   │  │  - 状态查询     │  │
│  ┌─────────────────┐  │                   │  │  - 购买记录     │  │
│  │  PostgreSQL     │  │                   │  └─────────────────┘  │
│  │  (购买记录)     │  │
│  └─────────────────┘  │
└───────────────────────┘`

---

### **C. 数据存储策略**

| **数据类型** | **存储位置** | **说明** |
| --- | --- | --- |
| **决定数据** | 本地 (Isar) | 所有用户创建的决策数据，不上传云端 |
| **选项组/选项** | 本地 (Isar) | 选项组、选项内容、权重设置 |
| **历史记录** | 本地 (Isar) | 判决历史、点赞点踩记录 |
| **订阅状态** | 本地 + 云端验证 | 本地缓存 + 定期向服务器验证 |
| **用户账号** | Supabase Auth | 手机号/邮箱/Apple ID，用于跨设备恢复订阅 |
| **购买记录** | Supabase PostgreSQL | 订单号、支付渠道、订阅类型、有效期 |
| **设置偏好** | 本地 (SharedPreferences) | UI 设置、主题偏好等 |

---

### **D. 用户认证系统**

### **登录方式**

| **方式** | **说明** | **优先级** |
| --- | --- | --- |
| **手机号 + 短信验证码** | 中国大陆用户最常用 | ⭐⭐⭐⭐⭐ |
| **邮箱 + 密码** | 国际用户/备用方式 | ⭐⭐⭐⭐ |
| **Apple ID 登录** | iOS 原生一键登录 | ⭐⭐⭐⭐ |

### **认证流程**

`1. 用户打开 App
       ↓
2. 选择登录方式（手机号/邮箱/Apple ID）
       ↓
3. Supabase Auth 处理认证
       ↓
4. 获取 JWT Token，存储于本地
       ↓
5. 后续请求自动携带 Token
       ↓
6. 用户登出时清除 Token`

---

### **E. 订阅验证流程**

`1. 用户选择订阅方案并支付
       ↓
2. iOS: Apple 返回购买收据 (Receipt)
   Android: 支付宝/微信返回支付凭证
       ↓
3. App 将收据/凭证发送至 Cloudflare Workers
       ↓
4. Workers 验证：
   - iOS: 向 Apple 验证收据有效性
   - Android: 验证支付宝/微信支付凭证
       ↓
5. 验证通过后，Workers 更新 Supabase 订阅记录
       ↓
6. 返回订阅状态给 App
       ↓
7. App 本地解锁付费功能，状态存入安全存储
       ↓
8. 每次启动 App 时，定期 (每 7 天) 重新验证订阅状态`

---

### **F. 后端数据库结构 (Supabase PostgreSQL)**

`-- 订阅记录表`

`create table subscriptions (`

  `id uuid primary key default gen_random_uuid(),`

  `user_id uuid references auth.users(id) not null,`

  `product_id text not null,`

  `product_type text not null, -- 'monthly' / 'yearly' / 'lifetime'`

  `amount numeric not null,`

  `currency text default 'CNY',`

  `payment_channel text not null, -- 'apple_iap' / 'alipay' / 'wechat'`

  `transaction_id text unique,`

  `receipt_data text,`

  `status text default 'pending', - 'pending' / 'completed' / 'failed' / 'refunded'`

  `starts_at timestamptz,`

  `expires_at timestamptz,`

  `auto_renew boolean default false,`

  `created_at timestamptz default now(),`

  `verified_at timestamptz`

`);`

`-- 索引`

`create index idx_subscriptions_user_id on subscriptions(user_id);`

`create index idx_subscriptions_transaction_id on subscriptions(transaction_id);`

`create index idx_subscriptions_status on subscriptions(status);`

`-- RLS 策略 (Row Level Security)alter table subscriptions enable row level security;`

`-- 用户只能查看自己的订阅记录`

`create policy "Users can view own subscriptions"`

  `on subscriptions for select`

  `using (auth.uid() = user_id);`

---

### **G. 核心 API 接口 (Cloudflare Workers)**

| **接口** | **方法** | **说明** |
| --- | --- | --- |
| **`/verify`** | POST | 验证购买收据，更新订阅状态 |
| **`/status`** | GET | 查询当前用户订阅状态 |
| **`/restore`** | POST | 恢复历史购买记录 |

---

### **H. 隐私保护策略**

| **措施** | **说明** |
| --- | --- |
| **最小化数据收集** | 仅存储订阅验证必需的用户标识和购买记录 |
| **本地优先** | 所有决策数据、历史记录均存储于用户设备，不上传云端 |
| **密码加密** | Supabase Auth 使用 BCrypt 加密存储用户密码 |
| **加密传输** | 所有网络通信使用 HTTPS + TLS 1.3 |
| **手机号脱敏** | 数据库中手机号部分掩码存储 |
| **匿名分析** | 如收集使用数据，需用户明确同意，且数据脱敏匿名 |
| **数据导出** | 用户可随时导出并删除本地所有数据 |
| **合规性** | 遵循中国个人信息保护法 (PIPL)、网络安全法 |

---

### **I. 服务器成本估算**

| **服务** | **免费额度** | **付费后成本** | **说明** |
| --- | --- | --- | --- |
| **Supabase** | 500MB 数据库 + 5 万月活 | $25/月 | 初期免费额度够用 |
| **Cloudflare Workers** | 10 万请求/天 | $5/100 万请求 | 初期免费 |
| **短信服务** | - | ¥0.04/条 | 阿里云/腾讯云，按量计费 |
| **域名 + SSL** | - | ¥100/年 | 已注册域名 |
| **合计 (初期)** | **¥0-100/月** | 仅短信费用 | 可支撑数万用户 |

---

### **J. 开发周期估算**

| **阶段** | **工作量** | **说明** |
| --- | --- | --- |
| **Flutter App 开发** | 1-2 周 | UI 组件 + 业务逻辑 + 本地存储 |
| **Supabase 配置** | 1-2 天 | 数据库结构、RLS 策略、Auth 配置 |
| **Cloudflare Workers** | 1-2 天 | 验证 API 开发 |
| **支付接入** | 2-4 天 | iOS 内购 + 支付宝/微信 |
| **测试调试** | 1 周 | 功能测试、上架审核 |
| **合计** | **3-4 周** | 约 1.5-2 个月完成 MVP |

---

### **K. 项目核心优势**

| **优势** | **说明** |
| --- | --- |
| **隐私优先** | 核心决策数据 100% 本地存储，不上传云端 |
| **自主可控** | 自建登录和支付验证系统，不依赖 Google 服务 |
| **国内合规** | 使用 Supabase + Cloudflare，符合 PIPL 等法规要求 |
| **跨平台支持** | iOS + Android 双端，订阅状态可跨设备恢复 |
| **原生体验** | Flutter 渲染，流畅原生交互 |
| **低运营成本** | 服务器月成本<¥100（初期免费），可持续运营 |

---

![image.png](9%20%E6%8A%80%E6%9C%AF%E6%9E%B6%E6%9E%84%EF%BC%88Technical%20Architecture%EF%BC%89/image.png)