# Kebijakan Privasi Daisth

**Status:** draf sumber untuk dipublikasikan. Dokumen ini belum menjadi URL kebijakan publik.  
**Tanggal berlaku:** USER INPUT REQUIRED — tetapkan saat kebijakan dipublikasikan.  
**Pengembang/pihak yang bertanggung jawab:** USER INPUT REQUIRED — nama hukum atau identitas pengembang yang benar.  
**Kontak privasi:** USER INPUT REQUIRED — alamat atau mekanisme kontak yang benar-benar dipantau.

Daisth adalah pendamping rutinitas Muslim dengan prinsip lokal terlebih dahulu. Anda dapat menggunakan fitur utama tanpa membuat akun. Sinkronisasi akun adalah pilihan dan hanya aktif setelah Anda memilih penyedia akun, menyetujui penautan, dan mengaktifkan sinkronisasi.

## Data yang diproses

### Data akun

Jika Anda masuk, Firebase Authentication memproses pengenal Firebase UID serta informasi profil yang tersedia dari penyedia, seperti alamat email, nama tampilan, dan URL foto profil. Android menyediakan Google Sign-In. iOS menyediakan Google Sign-In; Sign in with Apple telah diimplementasikan tetapi penggunaannya dalam produksi bergantung pada konfigurasi Apple Developer dan Firebase yang belum diverifikasi. Informasi yang dibagikan penyedia dapat berbeda menurut akun dan pilihan Anda.

### Data aplikasi dan sinkronisasi

Secara lokal, Daisth menyimpan data seperti definisi rutinitas, catatan penyelesaian dan checklist, pengaturan, riwayat, serta Reflection harian. Rutinitas salat dan ibadah dapat mengungkapkan keyakinan agama. Jika Anda secara terpisah mengaktifkan sinkronisasi akun, definisi rutinitas, status/riwayat, checklist, dan data Reflection (ritme dan catatan opsional) disinkronkan ke Cloud Firestore di bawah UID akun Firebase Anda. Ini mencakup catatan Reflection yang Anda tulis. Daisth tidak menggunakan Firebase Analytics.

Dokumen sinkronisasi juga memuat metadata untuk menjaga konsistensi, seperti tanggal data, waktu pembaruan, ID instalasi sumber, versi skema, dan penanda penghapusan. ID instalasi dibuat secara acak untuk logika sinkronisasi. ID ini bukan IMEI, Android ID, IDFA, atau advertising ID, dan tidak disebut anonim karena dapat dikaitkan dengan dataset akun yang disinkronkan.

Tema, status izin notifikasi, kemampuan exact-alarm, status snooze/follow-up runtime, status onboarding, status izin lokasi, serta status timezone runtime disimpan lokal dan bukan bagian dari data sinkronisasi akun. Daisth menjadwalkan pengingat pada perangkat; isi pengingat tidak dikirim ke server Daisth. Catatan Reflection tidak dimasukkan ke payload notifikasi.

### Lokasi

Saat digunakan untuk menghitung jadwal salat, lokasi diproses di perangkat untuk kalkulasi; Daisth tidak mengirim lokasi kalkulasi salat ke Firestore. Saat Anda memakai Nearby Mosque, koordinat perangkat dikirim melalui HTTPS dalam permintaan pencarian ke salah satu endpoint publik Overpass yang dikonfigurasi (`overpass-api.de` atau `overpass.private.coffee`) untuk mencari data OpenStreetMap. Hasil tempat dan kunci area pencarian yang dibulatkan disimpan sementara dalam cache memori aplikasi; cache tidak ditulis ke SQLite atau Firestore dan dianggap kedaluwarsa setelah lima menit, meski entri kedaluwarsa dapat tetap berada di memori sampai diganti atau proses aplikasi berakhir. Daisth tidak menyimpan koordinat pencarian ke penyimpanan persisten atau Firestore. Kebijakan ini tidak membuat klaim tentang apakah atau berapa lama penyedia Overpass menyimpan log permintaan; pemrosesan dan retensi pihak tersebut perlu ditinjau sebelum pengungkapan toko difinalkan. Daisth mempertahankan atribusi OpenStreetMap yang diwajibkan. Baca [Kebijakan Privasi OpenStreetMap Foundation](https://wiki.osmfoundation.org/wiki/Privacy_Policy).

Jika Anda menekan tindakan navigasi untuk suatu tempat, koordinat tujuan tempat itu disertakan dalam tautan Google Maps yang dibuka di aplikasi/browser eksternal. Penggunaan layanan eksternal tunduk pada kebijakan penyedianya.

### Notifikasi dan izin perangkat

Pengingat merupakan notifikasi lokal yang dijadwalkan pada perangkat. Sistem operasi menangani izin notifikasi dan alarm. Daisth dapat membaca status izin/kesiapan yang dibutuhkan untuk menjelaskan atau mengatur pengingat. Data runtime tersebut tidak disinkronkan ke Firestore.

## Cara data digunakan dan penyedia layanan

Daisth menggunakan data untuk menjalankan fitur yang Anda minta: autentikasi, sinkronisasi opsional, riwayat/rutinitas lokal, kalkulasi jadwal, pencarian masjid sekitar, dan pengingat lokal. Firebase Authentication dan Cloud Firestore merupakan layanan Google Firebase yang digunakan untuk akun dan sinkronisasi. Google dan Apple juga menangani alur autentikasi sesuai pilihan Anda. OpenStreetMap/Overpass menerima permintaan lokasi untuk pencarian masjid; Google Maps menerima koordinat tujuan jika Anda meminta navigasi.

Daisth tidak dengan sengaja menggunakan iklan atau pelacakan lintas aplikasi/situs untuk iklan tertarget atau pengukuran iklan. Daisth tidak menyertakan Firebase Analytics. Jangan menganggap pernyataan ini sebagai klaim bahwa layanan pihak ketiga tidak memproses data teknisnya sendiri; lihat kebijakan penyedia masing-masing.

## Penyimpanan, keamanan, dan retensi

Data lokal tetap berada dalam penyimpanan aplikasi sampai diubah/dihapus melalui aplikasi atau terpengaruh oleh siklus penyimpanan sistem/aplikasi. Daisth tidak menetapkan jangka waktu retensi lokal. Sinkronisasi menggunakan koneksi HTTPS/TLS. Aturan Firestore yang ada di source proyek dirancang untuk membatasi dokumen akun ke UID yang cocok; pengembang harus memastikan aturan tersebut telah diterapkan pada proyek Firebase produksi sebelum rilis. Aturan ini dan kontrol platform tidak menjamin keamanan sempurna. Daisth tidak mengklaim enkripsi end-to-end atau zero-knowledge.

Data cloud yang disinkronkan tetap ada sampai Anda mengubah/menghapusnya atau menghapus akun Daisth. Penanda penghapusan sinkronisasi (tombstone) dapat ada selama akun aktif agar perangkat lain tidak memulihkan data lama. Ketika penghapusan akun berhasil, Daisth menghapus data cloud Daisth yang diketahui dan akun Firebase Authentication terkait. Jika penghapusan cloud, autentikasi ulang, pencabutan token penyedia, atau penghapusan akun Firebase gagal, proses tidak dinyatakan berhasil dan Anda mungkin perlu mencoba kembali atau menghubungi dukungan; data cloud bisa sudah dibersihkan sebelum kegagalan lanjutan tersebut. Penghapusan akun **tidak** menghapus SQLite yang sudah tersimpan di perangkat fisik ini; Anda dapat terus menggunakan aplikasi dalam mode lokal. Kelola data perangkat secara terpisah jika Anda ingin menghapusnya.

Untuk akun yang dibuat dengan Sign in with Apple, implementasi penghapusan meminta pencabutan token otorisasi Apple setelah konfigurasi Apple produksi tersedia dan teruji. Kami tidak menyatakan bahwa alur produksi tersebut telah diuji.

## Pilihan dan hak Anda

- Gunakan fitur utama tanpa masuk dan tanpa mengaktifkan sinkronisasi.
- Kelola data rutinitas dan Reflection melalui aplikasi.
- Keluar dari akun tanpa menghapus data lokal.
- Mulai penghapusan akun melalui **Settings → Account / Data & Privacy → Delete Account** di dalam Daisth. Penghapusan cloud dan akun dilakukan setelah autentikasi ulang dan konfirmasi berhasil. Data SQLite lokal tetap ada.
- Untuk permintaan privasi, hubungi: **USER INPUT REQUIRED — kontak privasi yang dipantau**.

Belum ada jalur permintaan penghapusan melalui web yang dapat dipastikan saat draf ini dibuat. Sebelum rilis, pengembang harus menyediakan mekanisme eksternal yang benar-benar menerima permintaan penghapusan, termasuk saat aplikasi sudah tidak terpasang.

## Layanan pihak ketiga

- [Firebase Privacy and Security](https://firebase.google.com/support/privacy) — autentikasi dan sinkronisasi Firestore.
- [Google Privacy Policy](https://policies.google.com/privacy) — layanan Google dan Google Sign-In.
- [Apple Privacy Policy](https://www.apple.com/legal/privacy/) — Sign in with Apple jika digunakan.
- [OpenStreetMap Foundation Privacy Policy](https://wiki.osmfoundation.org/wiki/Privacy_Policy) — layanan data OpenStreetMap/Overpass.

## Perubahan dan kontak

Pengembang harus mengganti semua penanda **USER INPUT REQUIRED**, memeriksa kebijakan penyedia dan hukum yang berlaku, menetapkan tanggal berlaku, mempublikasikan URL HTTPS, serta menyediakan tautan kebijakan yang berfungsi dalam Daisth sebelum pengiriman toko. Untuk pertanyaan atau permintaan privasi: **USER INPUT REQUIRED — identitas pengembang dan mekanisme kontak**.
