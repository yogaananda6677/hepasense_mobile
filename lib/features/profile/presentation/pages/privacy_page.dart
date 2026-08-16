import 'package:flutter/material.dart';

import '../../../../core/theme/spacing.dart';

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Privasi')),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: const [
          _InfoSection(
            icon: Icons.health_and_safety_outlined,
            title: 'Informasi kesehatan',
            body:
                'Data skrining merupakan informasi sensitif terkait kesehatan. Aplikasi menampilkan data hanya untuk akun pasien yang terhubung sesuai akses dari layanan HepaSense.',
          ),
          _InfoSection(
            icon: Icons.lock_outline,
            title: 'Keamanan sesi',
            body:
                'Token sesi dikelola melalui penyimpanan yang sesuai dengan arsitektur aplikasi. Password tidak disimpan oleh aplikasi.',
          ),
          _InfoSection(
            icon: Icons.notifications_none,
            title: 'Notifikasi',
            body:
                'Notifikasi di dalam aplikasi merupakan sumber informasi utama. Pesan push hanya memberi tahu adanya pembaruan dan aplikasi mengambil isi resmi setelah sesi terautentikasi.',
          ),
          _InfoSection(
            icon: Icons.info_outline,
            title: 'Batas penggunaan',
            body:
                'HepaSense adalah alat bantu skrining awal non-invasif dan bukan pengganti diagnosis atau konsultasi tenaga kesehatan.',
          ),
          Text(
            'Halaman ini berisi ringkasan informasi produk dan bukan dokumen kebijakan hukum yang telah ditinjau secara terpisah.',
          ),
        ],
      ),
    ),
  );
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({
    required this.icon,
    required this.title,
    required this.body,
  });
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(body),
            ],
          ),
        ),
      ],
    ),
  );
}
