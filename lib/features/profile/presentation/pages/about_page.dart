import 'package:flutter/material.dart';

import '../../../../core/theme/spacing.dart';

class AboutHepaSensePage extends StatelessWidget {
  const AboutHepaSensePage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Tentang HepaSense')),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        children: [
          CircleAvatar(
            radius: 42,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Icon(
              Icons.monitor_heart_outlined,
              size: 42,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'HepaSense',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const Text('Versi 1.0.0 (1)', textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.xl),
          const Text(
            'HepaSense adalah sistem pendukung skrining awal non-invasif yang membantu pasien melihat hasil pemeriksaan dan informasi pendukung melalui aplikasi.',
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'Hasil HepaSense bukan diagnosis penyakit dan tidak menggantikan pemeriksaan atau konsultasi dengan tenaga kesehatan.',
          ),
        ],
      ),
    ),
  );
}
