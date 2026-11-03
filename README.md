# DODIGI


![DODIGI](docs/screenshots/banner.png)

Aplikasi pencatatan keuangan pribadi berbasis Flutter. Catat pemasukan dan pengeluaran, atur anggaran, pantau tagihan, dan capai target tabungan dalam satu aplikasi.

## Fitur

- **Autentikasi**: login dengan akun Google
- **Dompet**: kelola beberapa dompet (tunai, bank, e-wallet)
- **Transaksi**: catat pemasukan dan pengeluaran per kategori, lengkap dengan riwayat
- **Anggaran (Budget)**: batasi pengeluaran per kategori
- **Tagihan**: pengingat tagihan rutin
- **Target**: target tabungan dengan progres dan setor/tarik dana
- **Laporan & Analitik**: ringkasan dan grafik keuangan
- **Notifikasi**: pengingat yang bisa diatur
- **Tema**: mode terang dan gelap

## Tech Stack

- [Flutter](https://flutter.dev) (Dart)
- [Supabase](https://supabase.com) (auth dan database)
- [Riverpod](https://riverpod.dev) (state management)
- [GoRouter](https://pub.dev/packages/go_router) (navigasi)

## Struktur Project

```
lib/
├── config/      # router dan konfigurasi Supabase
├── core/        # tema, konstanta, utilitas
├── features/    # auth, wallet, transaction, budget, tagihan, target, analytics, notification, dll.
└── shared/      # model dan widget yang dipakai bersama
```

## Cara Menjalankan

### Prasyarat

- Flutter SDK (disarankan versi stable terbaru)
- Akun [Supabase](https://supabase.com) dengan project sendiri

### Langkah

1. Clone repository
   ```bash
   git clone https://github.com/faril123/DIDIGO---Aplikasi-Pencatatan-Keuangan..git
   cd DIDIGO---Aplikasi-Pencatatan-Keuangan.
   ```

2. Salin file environment lalu isi dengan key Supabase milikmu
   ```bash
   cp .env.example .env
   ```
   ```env
   SUPABASE_URL=https://xxxx.supabase.co
   SUPABASE_ANON_KEY=your-anon-key
   ```
   Di Windows PowerShell gunakan `copy .env.example .env`.

3. Install dependencies
   ```bash
   flutter pub get
   ```

4. Jalankan aplikasi
   ```bash
   flutter run
   ```

> File `.env` tidak disertakan di repository. Pastikan tabel database di Supabase sudah disiapkan sesuai kebutuhan aplikasi.

## Pembuat

Faril Rahman ([@faril123](https://github.com/faril123))
