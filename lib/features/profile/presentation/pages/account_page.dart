import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/routes.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/widgets/state_view.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../patient/data/patient_providers.dart';
import '../../../patient/domain/patient_state.dart';
import '../../../push/data/push_providers.dart';
import '../../data/profile_providers.dart';
import '../../domain/account_profile.dart';
import '../../domain/profile_state.dart';

class AccountPage extends ConsumerStatefulWidget {
  const AccountPage({super.key});

  @override
  ConsumerState<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends ConsumerState<AccountPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(profileControllerProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Akun')),
      body: SafeArea(
        child: switch (state) {
          ProfileInitial() || ProfileLoading() => const StateView(
            state: ViewState.loading,
            loadingMessage: 'Memuat profil...',
          ),
          ProfileFailure(:final message) => StateView(
            state: ViewState.error,
            errorMessage: message,
            onRetry: () => ref.read(profileControllerProvider.notifier).load(),
          ),
          ProfileLoaded(:final profile) => _content(profile),
        },
      ),
    );
  }

  Widget _content(AccountProfile profile) {
    final patient = ref.watch(patientControllerProvider);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text(
          profile.fullName.isEmpty ? 'Profil akun' : profile.fullName,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(profile.email),
        const SizedBox(height: AppSpacing.lg),
        _row('Nomor telepon', profile.phoneNumber),
        _row('Tanggal lahir', profile.dateOfBirth ?? 'Belum diisi'),
        _row(
          'Data pasien',
          patient is PatientLinked
              ? patient.patient.patientCode
              : patient is PatientUnlinked
              ? 'Belum terhubung'
              : 'Sedang dimuat',
        ),
        const Divider(height: AppSpacing.xl),
        ListTile(
          leading: const Icon(Icons.edit_outlined),
          title: const Text('Ubah biodata'),
          onTap: () => context.push(AppRoutes.editProfile),
        ),
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('Keluar'),
          onTap: () async {
            await ref.read(pushCoordinatorProvider).onLogout();
            await ref.read(authControllerProvider.notifier).logout();
          },
        ),
      ],
    );
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        Text(value.isEmpty ? 'Belum diisi' : value),
      ],
    ),
  );
}
