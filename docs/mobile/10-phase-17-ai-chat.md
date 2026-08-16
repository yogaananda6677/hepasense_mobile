# Mobile Phase 17 — Tanya AI

## Status

Tanya AI menggantikan halaman sementara **Segera Hadir** dan terhubung hanya ke API HepaSense yang terautentikasi. Aplikasi Flutter tidak menghubungi provider AI secara langsung dan tidak menyimpan secret provider.

Referensi visual menggunakan layar Stitch **Asisten Nara** dan **AI Assistant Voice Interface** untuk hierarki, proporsi bubble, composer, serta empty state. Branding, voice behavior, dan warna referensi tidak disalin; palette final HepaSense tetap digunakan.

## Kontrak API

- `POST /api/v1/assistant/conversations/` membuat percakapan.
- `GET /api/v1/assistant/conversations/?page={page}` memuat riwayat berhalaman.
- `GET /api/v1/assistant/conversations/{id}/` memuat detail dan pesan.
- `POST /api/v1/assistant/conversations/{id}/messages/` mengirim body `{"message": "..."}`.
- `DELETE /api/v1/assistant/conversations/{id}/` menghapus percakapan setelah konfirmasi.

Respons `503` ditampilkan sebagai provider belum tersedia, `429` sebagai batas penggunaan sementara, `404` sebagai percakapan tidak tersedia, dan kegagalan koneksi sebagai masalah jaringan yang terpisah. Pesan teknis backend tidak ditampilkan kepada pasien.

## Perilaku dan keamanan

- Riwayat, detail percakapan, pengiriman pesan, pagination, retry, loading, dan penghapusan tersedia.
- Bubble pengguna dan asisten dibedakan secara visual; composer membatasi input hingga 2.000 karakter dan menolak pesan kosong.
- Informasi AI diberi penjelasan bahwa hasil bersifat edukatif dan tidak menggantikan tenaga kesehatan.
- Transkrip hanya berada dalam state memori selama sesi aplikasi; tidak ada persistence lokal.
- Perubahan status autentikasi membangun ulang state AI sehingga data akun sebelumnya tidak terbawa.
- Identitas pasien, hasil skrining, dan konteks klinis tidak diinjeksi otomatis.
- Tidak ada API key, provider authorization header, atau konfigurasi provider di aplikasi.

## Navigasi

Lima tujuan tetap: **Beranda, Riwayat, Gizi, Chat AI, Akun**. Halaman Tanya AI dan detail percakapan memakai direct/no-transition navigation tanpa animasi geser horizontal.

## Batas validasi provider

Backend saat ini menggunakan `AI_PROVIDER=none`, sehingga respons generasi nyata belum dapat divalidasi dan perilaku yang diharapkan adalah safe `503`. End-to-end respons AI nyata memerlukan konfigurasi satu provider OpenAI-compatible di backend; tidak diperlukan perubahan secret pada Flutter.
