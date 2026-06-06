# FinanceDesk — Setup Guide

A lightweight startup finance app hosted on **GitHub Pages** with **Supabase** backend.

---

## Features
- **Receipts** — Create, edit, delete with auto-numbered `REC-YYYY-NNNN` IDs and file attachments
- **Vouchers** — Same for `VCH-YYYY-NNNN`
- **Search** — Look up any document by number to retrieve details + attachment
- **Employees** — Full employee directory with card/list views
- **Salary Slips** — Generate PDF slips via jsPDF, email via EmailJS

---

## Step 1 — Supabase Project

1. Go to [https://supabase.com](https://supabase.com) → **New Project**
2. Note your **Project URL** and **Anon/Public API Key** (Settings → API)
3. Open **SQL Editor** and paste the entire contents of `supabase_schema.sql` → **Run**
4. Go to **Storage** → **New Bucket**
   - Name: `attachments`
   - Toggle **Public bucket** ON
   - Click **Create bucket**
5. In Storage → Policies, add:
   - **INSERT** policy: `auth.role() = 'authenticated'`
   - **SELECT** policy: `true` (public read for attachment URLs)

---

## Step 2 — Configure the App

Open `js/supabase.js` and replace the top two lines:

```js
const SUPABASE_URL      = 'https://YOUR_PROJECT.supabase.co';
const SUPABASE_ANON_KEY = 'YOUR_ANON_KEY';
```

Open `pages/salary.html` and fill in your company details near the top of the script:

```js
const COMPANY_NAME    = 'Your Company Pvt. Ltd.';
const COMPANY_ADDRESS = 'Your Address, City, State';
```

---

## Step 3 — EmailJS Setup (for Salary Slip emails)

1. Sign up at [https://emailjs.com](https://emailjs.com)
2. Connect an email service (Gmail works fine)
3. Create an **Email Template** with these variables:

   ```
   To: {{to_email}}
   Subject: Salary Slip for {{month}} — {{to_name}}

   Body:
   Dear {{to_name}},
   Please find your salary slip for {{month}} attached.

   Employee Code : {{emp_code}}
   Designation   : {{designation}}
   Gross Earnings: {{gross}}
   Deductions    : {{deductions}}
   Net Payable   : {{net}}

   Regards,
   {{company}}
   ```

   For PDF attachment: add `{{pdf_attachment}}` as an attachment variable in the EmailJS template settings.

4. In `pages/salary.html`, replace:

```js
const EMAILJS_PUBLIC_KEY  = 'YOUR_EMAILJS_PUBLIC_KEY';
const EMAILJS_SERVICE_ID  = 'YOUR_EMAILJS_SERVICE_ID';
const EMAILJS_TEMPLATE_ID = 'YOUR_EMAILJS_TEMPLATE_ID';
```

---

## Step 4 — GitHub Pages Deployment

1. Create a new **GitHub repository** (public or private with Pages enabled)
2. Upload all files maintaining this structure:

```
/
├── index.html
├── dashboard.html
├── css/
│   └── app.css
├── js/
│   └── supabase.js
├── pages/
│   ├── receipts.html
│   ├── vouchers.html
│   ├── search.html
│   ├── employees.html
│   └── salary.html
└── README.md
```

3. Go to repository **Settings → Pages**
4. Source: **Deploy from a branch** → `main` → `/ (root)` → **Save**
5. Your app will be live at `https://YOUR-USERNAME.github.io/YOUR-REPO/`

---

## Step 5 — Supabase Auth Settings

In Supabase Dashboard → **Authentication → URL Configuration**:

- **Site URL**: `https://YOUR-USERNAME.github.io/YOUR-REPO`
- **Redirect URLs**: add `https://YOUR-USERNAME.github.io/YOUR-REPO/dashboard.html`

For Google OAuth (optional):
- Authentication → Providers → Google → enable and add OAuth credentials

---

## Auto-Number Format

| Type    | Format          | Example         |
|---------|-----------------|-----------------|
| Receipt | `REC-YYYY-NNNN` | `REC-2026-0042` |
| Voucher | `VCH-YYYY-NNNN` | `VCH-2026-0011` |
| Employee| `EMP-NNNN`      | `EMP-0007`      |

Numbers reset per year for receipts/vouchers.

---

## File Size Limits

- Max attachment size: **5MB** per file
- Accepted types: PDF, JPG, JPEG, PNG
- Supabase Storage free tier: **1GB** total

---

## Tech Stack

| Layer       | Technology          |
|-------------|---------------------|
| Hosting     | GitHub Pages        |
| Database    | Supabase (PostgreSQL)|
| Auth        | Supabase Auth       |
| File Storage| Supabase Storage    |
| PDF         | jsPDF 2.5           |
| Email       | EmailJS             |
| Frontend    | Vanilla HTML/CSS/JS |

No build step. No Node.js. No npm. Deploy by drag-and-drop.
