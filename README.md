# HydroGami - Integration of IoT and Gamification on Hydroponic Plants

HydroGami adalah sistem monitoring tanaman hidroponik berbasis Internet of Things (IoT) yang dilengkapi dengan elemen gamifikasi untuk meningkatkan pengalaman pengguna.

## Fitur Utama
- Monitoring real-time parameter hidroponik (TDS, suhu, pH, kelembapan, intensitas cahaya)
- Sistem gamifikasi dengan misi harian/mingguan
- Leaderboard dan reward system
- Kontrol pompa hidroponik otomatis/manual
- Panduan perawatan tanaman
- Penukaran poin

## Instalasi

### Prasyarat
- Flutter SDK (versi 3.5.3 atau lebih baru)
- Dart SDK (versi 2.17.0 atau lebih baru)
- Android Studio (untuk emulator)

### Langkah-langkah Instalasi
1. **Clone repository**
   ```bash
   git clone https://github.com/CLINTON1233/PBL-IF-16-Hydrogami-Integrasi-IoT-dan-Gamifikasi-Pada-Tanaman-Hidroponik.git
   cd hydrogami

2. **Install dependencies**
   flutter pub get

3. **Jalankan aplikasi**
   flutter run


## Panduan Penggunaan
### 1. Registrasi Akun Baru
1. Buka aplikasi HydroGami
2. Pilih "Daftar" di halaman Landing Page
3. Isi formulir registrasi dengan:
   - Username
   - Email
   - Password
4. Klik tombol "Daftar"


### 2. Login ke Aplikasi
1. Masukkan email dan password yang terdaftar
2. Klik tombol "Login"


### 3. Memilih Tanaman dan Skala
1. Pilih jenis tanaman dari opsi yang tersedia (contoh: Pakcoy)
2. Pilih skala hidroponik:
   - High (untuk pengalaman lanjutan)
   - Medium (untuk menengah)
   - Easy (untuk pemula)
3. Konfirmasi pilihan dengan menekan "Ya"


### 4. Dashboard Utama
Fitur yang tersedia:
- **Ringkasan Informasi Tanaman**:
  - Status nutrisi
  - Progress pertumbuhan
  - Kondisi lingkungan

- **Menu Navigasi**:
  - Monitoring: Pantau parameter hidroponik real-time
  - Gamifikasi: Progress level dan misi
  - Reward: Spin wheel dan penukaran poin
  - Panduan: Petunjuk perawatan tanaman
  - Notifikasi: Peringatan sistem


### 5. Monitoring Real-Time
Sistem indikator warna:
- Hijau: Kondisi normal
- Kuning: Perlu perhatian
- Merah: Kondisi kritis

Fitur tambahan:
- Notifikasi otomatis saat parameter melebihi batas normal


### 6. Fitur Gamifikasi
#### Misi Harian/Mingguan:
1. Buka halaman Gamifikasi
2. Pilih tab:
   - "Harian" untuk misi sehari-hari
   - "Mingguan" untuk misi jangka panjang
3. Klaim reward setelah menyelesaikan misi

#### Leaderboard:
1. Akses halaman Leaderboard
2. Lihat peringkat berdasarkan:
   - Total poin
   - Level pengguna
3. Tingkatkan aktivitas untuk naik peringkat


### 7. Sistem Reward
#### Spin Wheel:
1. Buka halaman Reward
2. Pastikan memiliki minimal 10 koin
3. Klik "Putar Roda" untuk mendapatkan hadiah acak

#### Penukaran Poin:
1. Pilih nominal penukaran yang tersedia
2. Klik "Tukar Koin"
3. Ikuti instruksi untuk proses penukaran


### 8. Kontrol Manual Pompa
1. Navigasi ke halaman Gamifikasi
2. Untuk kontrol manual:
   - Aktifkan/matikan tombol pompa sesuai kebutuhan
3. Untuk kontrol otomatis:
   - Gunakan switch "Otomatis" untuk sistem kontrol mandiri

