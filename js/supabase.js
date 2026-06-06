// js/supabase.js — Supabase client + shared helpers

// ─── CONFIG ─────────────────────────────────────────────────────────────────
// Replace these with your actual Supabase project values
const SUPABASE_URL = 'https://YOUR_PROJECT.supabase.co';
const SUPABASE_ANON_KEY = 'YOUR_ANON_KEY';

// ─── CLIENT ─────────────────────────────────────────────────────────────────
const { createClient } = supabase;
const db = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

// ─── AUTH ────────────────────────────────────────────────────────────────────
async function getSession() {
  const { data: { session } } = await db.auth.getSession();
  return session;
}

async function requireAuth() {
  const session = await getSession();
  if (!session) {
    window.location.href = '/index.html';
    return null;
  }
  return session;
}

async function signOut() {
  await db.auth.signOut();
  window.location.href = '/index.html';
}

// ─── AUTO-NUMBER GENERATION ──────────────────────────────────────────────────
// Generates REC-YYYY-NNNN or VCH-YYYY-NNNN
async function generateDocNumber(type) {
  const prefix = type === 'receipt' ? 'REC' : 'VCH';
  const table  = type === 'receipt' ? 'receipts' : 'vouchers';
  const col    = type === 'receipt' ? 'receipt_no' : 'voucher_no';
  const year   = new Date().getFullYear();

  const { data, error } = await db
    .from(table)
    .select(col)
    .like(col, `${prefix}-${year}-%`)
    .order(col, { ascending: false })
    .limit(1);

  if (error) throw error;

  let seq = 1;
  if (data && data.length > 0) {
    const last = data[0][col]; // e.g. REC-2026-0042
    seq = parseInt(last.split('-')[2]) + 1;
  }
  return `${prefix}-${year}-${String(seq).padStart(4, '0')}`;
}

// ─── FILE UPLOAD ─────────────────────────────────────────────────────────────
async function uploadAttachment(file, bucket, folder) {
  const ext  = file.name.split('.').pop();
  const name = `${folder}/${Date.now()}.${ext}`;
  const { data, error } = await db.storage.from(bucket).upload(name, file, {
    cacheControl: '3600', upsert: false
  });
  if (error) throw error;
  const { data: { publicUrl } } = db.storage.from(bucket).getPublicUrl(name);
  return publicUrl;
}

// ─── TOAST ───────────────────────────────────────────────────────────────────
function toast(msg, type = 'info') {
  let container = document.querySelector('.toast-container');
  if (!container) {
    container = document.createElement('div');
    container.className = 'toast-container';
    document.body.appendChild(container);
  }
  const t = document.createElement('div');
  const icons = { success: '✓', error: '✕', info: 'ℹ' };
  t.className = `toast toast-${type}`;
  t.innerHTML = `<span style="font-size:16px">${icons[type]||'ℹ'}</span><span>${msg}</span>`;
  container.appendChild(t);
  setTimeout(() => t.remove(), 3500);
}

// ─── MODAL HELPERS ───────────────────────────────────────────────────────────
function openModal(id) {
  document.getElementById(id).classList.add('open');
}
function closeModal(id) {
  document.getElementById(id).classList.remove('open');
}

// Close modal on backdrop click
document.addEventListener('click', e => {
  if (e.target.classList.contains('modal-backdrop')) {
    e.target.classList.remove('open');
  }
});

// ─── INITIALS ────────────────────────────────────────────────────────────────
function initials(name = '') {
  return name.split(' ').map(n => n[0]).join('').toUpperCase().slice(0, 2);
}

// ─── AVATAR COLOR ────────────────────────────────────────────────────────────
const AVATAR_COLORS = [
  ['#E6F1FB','#185FA5'], ['#EEEDFE','#534AB7'], ['#E1F5EE','#0F6E56'],
  ['#FAEEDA','#854F0B'], ['#FAECE7','#993C1D'], ['#EAF3DE','#3B6D11'],
];
function avatarColor(name = '') {
  const i = name.charCodeAt(0) % AVATAR_COLORS.length;
  return AVATAR_COLORS[i];
}

// ─── FORMAT DATE ─────────────────────────────────────────────────────────────
function fmtDate(iso) {
  if (!iso) return '—';
  return new Date(iso).toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' });
}

// ─── FORMAT CURRENCY ─────────────────────────────────────────────────────────
function fmtINR(n) {
  return '₹' + Number(n || 0).toLocaleString('en-IN');
}

// ─── SET ACTIVE NAV ──────────────────────────────────────────────────────────
function setActiveNav(page) {
  document.querySelectorAll('.nav-link').forEach(el => {
    el.classList.toggle('active', el.dataset.page === page);
  });
}
