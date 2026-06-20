# Manual Book: Aplikasi Mobile Rumah Laundry

Selamat datang di Panduan Penggunaan dan Dokumentasi Teknis untuk Aplikasi **Rumah Laundry**. Dokumen ini dibuat untuk membantu pengguna, administrator, dan pengembang (developer) dalam memahami alur kerja, arsitektur kode, konfigurasi, serta cara menjalankan aplikasi berbasis Flutter ini.

---

## Daftar Isi
1. [Pendahuluan & Gambaran Umum](#1-pendahuluan--gambaran-umum)
2. [Persyaratan Sistem & Instalasi](#2-persyaratan-sistem--instalasi)
3. [Arsitektur & Struktur Folder Projek](#3-arsitektur--struktur-folder-projek)
4. [Konfigurasi Jaringan & Koneksi API](#4-konfigurasi-jaringan--koneksi-api)
5. [Panduan Penggunaan Fitur Aplikasi](#5-panduan-penggunaan-fitur-aplikasi)
    - 5.1 [Autentikasi (Pendaftaran & Masuk)](#51-autentikasi-pendaftaran--masuk)
    - 5.2 [Beranda (Dashboard & Informasi Ringkas)](#52-beranda-dashboard--informasi-ringkas)
    - 5.3 [Pencarian & Informasi Layanan](#53-pencarian--informasi-layanan)
    - 5.4 [Proses Pemesanan Laundry (Order)](#54-proses-pemesanan-laundry-order)
    - 5.5 [Halaman Checkout & Pengiriman](#55-halaman-checkout--pengiriman)
    - 5.6 [Pelacakan Cucian & Unggah Bukti Bayar](#56-pelacakan-cucian--unggah-bukti-bayar)
    - 5.7 [Pengaturan Profil & Statistik Pengguna](#57-pengaturan-profil--statistik-pengguna)
6. [Manajemen State (State Management)](#6-manajemen-state-state-management)
7. [Penanganan Masalah (Troubleshooting & FAQ)](#7-penanganan-masalah-troubleshooting--faq)

---

## 1. Pendahuluan & Gambaran Umum

**Rumah Laundry** adalah aplikasi mobile-first (responsif dengan batas lebar maksimal 500px agar tampil sempurna di web maupun perangkat mobile) yang dirancang untuk memudahkan pelanggan dalam memesan layanan laundry secara online. 

### Fitur Utama:
*   **Autentikasi Pengguna**: Login, registrasi, dan penyimpanan sesi otomatis menggunakan token lokal.
*   **Pemesanan Fleksibel**: Memilih berbagai layanan laundry per-kilo (kg) maupun per-potong (pcs).
*   **Layanan Antar-Jemput**: Pengantaran dan pengambilan pakaian dengan penyesuaian biaya pengiriman otomatis.
*   **Metode Pembayaran Ganda**: Dukungan pembayaran tunai (Cash/COD) atau nontunai (Transfer Bank/E-Wallet).
*   **Pelacakan Cucian Real-Time**: Status pengerjaan yang transparan melalui stepper interaktif (*Baru* $\rightarrow$ *Cuci* $\rightarrow$ *Proses* $\rightarrow$ *Selesai* $\rightarrow$ *Diambil*).
*   **Unggah Bukti Bayar**: Pelanggan dapat mengunggah foto bukti pembayaran langsung dari galeri ponsel.
*   **Integrasi WhatsApp**: Hubungan langsung ke Customer Service admin Rumah Laundry untuk konfirmasi cepat.

---

## 2. Persyaratan Sistem & Instalasi

Untuk menjalankan atau mengembangkan aplikasi ini, pastikan sistem Anda telah memenuhi kriteria berikut:

### Persyaratan Pengembangan (Developer):
1.  **Flutter SDK**: Versi `^3.11.4` atau lebih tinggi.
2.  **Dart SDK**: Sesuai dengan bawaan Flutter SDK yang digunakan.
3.  **Android Studio / VS Code**: Terinstal plugin **Flutter** dan **Dart**.
4.  **Java Development Kit (JDK)**: Versi 11 atau 17 (untuk kompilasi Android).
5.  **Emulator atau Perangkat Fisik**: Android (OS 5.0 Lollipop+) atau iOS (OS 12.0+).

### Langkah-langkah Instalasi Projek:

1.  **Kloning Repositori**:
    ```bash
    git clone <url-repositori-rumah-laundry>
    cd rumah_laundry_mobile
    ```

2.  **Instalasi Dependensi**:
    Jalankan perintah berikut di terminal root projek untuk mengunduh semua paket yang tercantum di [pubspec.yaml](file:///d:/rumah_laundry_mobile/pubspec.yaml):
    ```bash
    flutter pub get
    ```

3.  **Menjalankan Aplikasi**:
    *   Menggunakan VS Code: Tekan `F5` atau pilih menu *Run and Debug*.
    *   Menggunakan Terminal:
        ```bash
        flutter run
        ```

---

## 3. Arsitektur & Struktur Folder Projek

Projek ini menerapkan struktur direktori modular yang bersih untuk memisahkan logika bisnis, tampilan visual, serta model data:

```text
lib/
├── core/                   # Konfigurasi global & tema aplikasi
│   ├── api_constants.dart  # Endpoint API & utilitas URL
│   ├── app_colors.dart     # Palette warna (Primary Green, Secondary, dll.)
│   └── app_theme.dart      # Konfigurasi tema global MaterialApp
├── data/                   # Data layer (Model, layanan jaringan)
│   ├── models/             # Representasi objek JSON ke Dart
│   │   ├── payment_account_model.dart
│   │   ├── service_model.dart
│   │   ├── transaction_model.dart
│   │   └── user_model.dart
│   └── services/           # Penghubung HTTP request ke server Backend
│       ├── auth_service.dart
│       └── laundry_service.dart
├── providers/              # State Management menggunakan Provider
│   ├── auth_provider.dart  # Mengelola status login, token, & otorisasi user
│   └── dashboard_provider.dart # Mengelola data keranjang, transaksi, & profil
├── ui/                     # Interface / Halaman Visual (UI)
│   └── screens/
│       ├── auth/           # LoginScreen & RegisterScreen
│       ├── dashboard/      # LayananTab, OrderTab, OrdersTab, ProfileTab, CheckoutScreen, dll.
│       └── home/           # HomeScreen dasar / Gerbang pembuka
└── main.dart               # Entry point utama aplikasi & pendaftaran Providers
```

---

## 4. Konfigurasi Jaringan & Koneksi API

Aplikasi mobile ini terhubung dengan backend (Laravel API). Alamat IP server didefinisikan pada file [api_constants.dart](file:///d:/rumah_laundry_mobile/lib/core/api_constants.dart).

```dart
static const String baseUrl = kIsWeb
    ? 'http://127.0.0.1:8000/api'
    : 'http://192.168.100.102:8000/api';
```

> [!IMPORTANT]  
> **Petunjuk Akses dari Perangkat Fisik (HP Android/iOS):**
> *   Jika Anda menguji aplikasi menggunakan HP fisik, pastikan laptop/komputer Anda dan HP terhubung pada **jaringan Wi-Fi yang sama**.
> *   Cari tahu IP lokal PC Anda (di Windows: jalankan perintah `ipconfig` di command prompt).
> *   Ganti alamat IP `'192.168.100.102'` pada variabel `baseUrl` di file [api_constants.dart](file:///d:/rumah_laundry_mobile/lib/core/api_constants.dart) dengan IP lokal PC Anda saat ini.
> *   Pastikan server Laravel API berjalan dengan perintah `php artisan serve --host=0.0.0.0 --port=8000`.

---

## 5. Panduan Penggunaan Fitur Aplikasi

### 5.1 Autentikasi (Pendaftaran & Masuk)
*   **Splash Gate**: Saat aplikasi dibuka, sistem memeriksa sesi login yang tersimpan di memori perangkat (`shared_preferences`). Jika token masih aktif, pengguna langsung diarahkan ke Beranda. Jika tidak, halaman Login akan terbuka.
*   **Masuk (Login)**: Pengguna memasukkan alamat email yang valid dan password minimal 6 karakter.
*   **Daftar (Register)**: Pengguna baru dapat mendaftar dengan melengkapi:
    1. Nama Lengkap
    2. Alamat Email
    3. Nomor HP/WhatsApp Aktif
    4. Alamat Lengkap Penjemputan
    5. Kata Sandi (Password)

---

### 5.2 Beranda (Dashboard & Informasi Ringkas)
Setelah login, pengguna disambut oleh halaman Beranda:
*   **Informasi Status**: Menampilkan nama depan pelanggan serta ringkasan jumlah pesanan aktif, pesanan selesai, dan jumlah layanan laundry yang tersedia di outlet.
*   **Pencarian Cepat**: Terdapat bilah pencarian yang ketika diklik akan mengarahkan pengguna ke tab *Layanan*.
*   **Layanan Unggulan**: Ditampilkan dalam bentuk kartu grid yang menarik. Menekan salah satu kartu layanan akan memicu sistem untuk menambahkan item tersebut ke keranjang pesanan.

---

### 5.3 Pencarian & Informasi Layanan
Pada tab **Layanan** (Tab ke-2), pelanggan dapat mengeksplorasi opsi laundry:
*   **Pencarian & Kategori**: Pelanggan dapat mengetikkan kata kunci layanan pada kolom pencarian dan memfilter berdasarkan kategori tertentu (misalnya: *Kiloan*, *Satuan*, *Karpet*, dll.).
*   **Daftar Layanan**: Terdapat nama layanan, deskripsi lengkap, serta harga per unit yang tercantum jelas.

---

### 5.4 Proses Pemesanan Laundry (Order)
Pada tab **Order** (Tab ke-3 / Tombol Bulat Hijau di Tengah):
*   Aplikasi menampilkan daftar seluruh layanan lengkap dengan tombol stepper kuantitas (tambah `+` dan kurang `-`).
*   **Kuantitas Pintar**:
    *   Jika unit adalah **kg**, kuantitas akan bertambah/berkurang dengan kelipatan **0.5 kg** (contoh: 1.0, 1.5, 2.0).
    *   Jika unit adalah **pcs** (satuan), kuantitas bertambah/berkurang per **1 pcs**.
*   **Ringkasan Keranjang**: Di bagian bawah layar akan muncul panel melayang yang mengalkulasi subtotal harga dan jumlah layanan terpilih secara dinamis. Pelanggan dapat menekan tombol **Checkout** untuk melanjutkan.

---

### 5.5 Halaman Checkout & Pengiriman
Pada halaman Checkout, pelanggan melengkapi detail transaksi:
*   **Metode Pengantaran**:
    *   Mengaktifkan *Layanan Antar-Jemput* akan menambahkan biaya pengiriman flat sebesar **Rp 10.000**. Sistem kemudian meminta alamat lengkap penjemputan.
    *   Mematikan switch berarti pelanggan membawa cucian sendiri ke toko (*Bawa Sendiri ke Toko*, tanpa biaya tambahan).
*   **Kontak HP & Catatan**: Kolom nomor telepon terisi otomatis sesuai profil, beserta kolom catatan opsional (misalnya: *"Pakaian putih tolong dipisah"*).
*   **Metode Pembayaran**:
    *   **Cash**: Pembayaran tunai saat cucian diserahkan/diambil.
    *   **Transfer Bank / E-Wallet**: Menampilkan detail rekening (nomor akun, atas nama) sesuai pilihan bank/dompet digital yang didukung. Terdapat tombol salin nomor rekening secara instan.
*   **Konfirmasi**: Pengguna menekan tombol "Checkout" dan meninjau kembali via dialog pop-up konfirmasi dari `QuickAlert` sebelum pesanan dikirim ke server backend.

---

### 5.6 Pelacakan Cucian & Unggah Bukti Bayar
Setelah transaksi berhasil dibuat, pelanggan diarahkan ke halaman **Detail Pesanan**:
*   **Invoice & Salin**: Menampilkan kode invoice unik (contoh: `INV-20260611-0001`) beserta tombol salin instan.
*   **Peta Stepper Kemajuan**: Menggambarkan tahap pemrosesan cucian secara dinamis menggunakan ikon dan status pengerjaan visual:
    1.  **Baru (Menunggu)**: Pesanan terdaftar di sistem.
    2.  **Cuci (Dicuci)**: Pakaian sedang dicuci.
    3.  **Proses (Diproses)**: Pakaian dalam tahap pengeringan/penyetrikaan.
    4.  **Selesai**: Pakaian selesai dipacking & siap diambil/dikirim.
    5.  **Diambil**: Cucian telah selesai dan diterima kembali oleh pelanggan.
*   **Unggah Bukti Transfer**: Untuk pembayaran nontunai, tombol "Pilih & Unggah Bukti Pembayaran" akan muncul. Pelanggan dapat memilih gambar resi transfer bank dari galeri ponsel dan mengunggahnya. Admin akan melakukan verifikasi di sistem backend.
*   **Layanan Pelanggan (CS WhatsApp)**: Tombol melayang *Chat CS* di kanan bawah terintegrasi untuk langsung mengirim pesan WhatsApp ke admin berisi format otomatis yang mencantumkan kode invoice.

---

### 5.7 Pengaturan Profil & Statistik Pengguna
Pada tab **Profil** (Tab ke-5):
*   **Statistik Pengguna**: Menampilkan total transaksi yang pernah dilakukan, pesanan aktif saat ini, dan total nominal rupiah yang telah dibelanjakan di Rumah Laundry.
*   **Edit Profil**: Mengubah nama lengkap, email, nomor HP, dan alamat pengiriman default.
*   **Ubah Foto Profil**: Pelanggan dapat menekan avatar foto profil saat mode edit aktif untuk memilih foto baru dari galeri.
*   **Pusat Bantuan & Logout**: Tombol hubungi Customer Service, informasi lisensi aplikasi (Tentang Aplikasi), serta opsi keluar dengan aman.

---

## 6. Manajemen State (State Management)

Aplikasi ini menggunakan paket **Provider** untuk mengelola aliran data (state) secara reaktif di seluruh halaman:

1.  **AuthProvider** (`lib/providers/auth_provider.dart`)
    *   Mengontrol sesi login pelanggan.
    *   Menyimpan token autentikasi (Bearer Token) ke `shared_preferences`.
    *   Mengatur profil `UserModel` yang sedang masuk.
2.  **DashboardProvider** (`lib/providers/dashboard_provider.dart`)
    *   Memuat data katalog layanan (`ServiceModel`).
    *   Mengelola riwayat transaksi (`TransactionModel`).
    *   Mengelola daftar belanja/keranjang (*cart*) sementara sebelum checkout.
    *   Mengirim data pesanan baru, unggah bukti pembayaran, dan perubahan profil ke layanan `laundry_service`.

---

## 7. Penanganan Masalah (Troubleshooting & FAQ)

#### **1. Mengapa Aplikasi Menampilkan Pesan "Gagal memuat data / Sesi Berakhir"?**
*   **Penyebab**: Koneksi internet tidak stabil, token kedaluwarsa, atau backend server tidak aktif.
*   **Solusi**: 
    1. Tekan tombol "Coba Lagi" pada layar.
    2. Jika muncul pesan "Sesi telah berakhir", tekan "Login Ulang" untuk masuk kembali guna memperbarui token keamanan.
    3. Cek kembali file [api_constants.dart](file:///d:/rumah_laundry_mobile/lib/core/api_constants.dart) dan pastikan alamat IP komputer server sesuai dengan jaringan Wi-Fi saat ini.

#### **2. Mengapa Gambar Bukti Pembayaran Tidak Bisa Diunggah?**
*   **Penyebab**: Aplikasi belum mendapatkan izin akses galeri gambar di perangkat, ukuran gambar terlalu besar, atau koneksi terputus.
*   **Solusi**: 
    1. Pastikan Anda mengizinkan akses galeri foto (*storage permissions*) saat pop-up sistem operasi muncul.
    2. Aplikasi sudah otomatis membatasi ukuran gambar maks 512x512 piksel dengan kompresi 85% untuk mempercepat unggahan, namun pastikan kualitas internet memadai selama proses transfer data.

#### **3. Apakah Data Alamat yang Diedit di Profil Otomatis Tersimpan saat Checkout?**
*   **Jawaban**: Ya, saat Anda melakukan edit profil dan menekan tombol simpan, data alamat dan nomor telepon akan disinkronisasikan ke database sehingga saat Anda masuk ke halaman checkout berikutnya, formulir penjemputan akan langsung terisi secara otomatis.

---
*Dokumentasi ini diperbarui pada Juni 2026 untuk Rumah Laundry Mobile App versi 1.0.0.*
