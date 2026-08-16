import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/routes.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_bottom_navigation.dart';
import '../../../../core/widgets/app_card.dart';
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
  bool _loggingOut = false;

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
      bottomNavigationBar: const AppBottomNavigation(selectedIndex: 4),
    );
  }

  Widget _content(AccountProfile profile) {
    final patient = ref.watch(patientControllerProvider);
    final linked = patient is PatientLinked;
    final name = profile.fullName.trim().isEmpty
        ? 'Pengguna HepaSense'
        : profile.fullName.trim();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        AppCard(
          emphasized: true,
          child: Column(
            children: [
              CircleAvatar(
                radius: 42,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Text(
                  _initials(profile),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Semantics(
                header: true,
                child: Text(
                  name,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Chip(
                avatar: Icon(linked ? Icons.link : Icons.link_off, size: 18),
                label: Text(
                  linked ? 'Data pasien terhubung' : 'Belum terhubung',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _section('Informasi Pribadi', [
          _SettingItem(
            icon: Icons.badge_outlined,
            label: 'Biodata',
            value: profile.phoneNumber.isEmpty
                ? 'Lengkapi informasi akun'
                : profile.phoneNumber,
            onTap: () => context.push(AppRoutes.editProfile),
          ),
          _SettingItem(
            icon: Icons.email_outlined,
            label: 'Email',
            value: profile.email,
          ),
          _SettingItem(
            icon: Icons.cake_outlined,
            label: 'Tanggal lahir',
            value: profile.dateOfBirth ?? 'Belum diisi',
          ),
        ]),
        const SizedBox(height: AppSpacing.lg),
        _section('Keamanan', [
          _SettingItem(
            icon: Icons.lock_outline,
            label: 'Ubah Password',
            onTap: () => context.push(AppRoutes.changePassword),
          ),
        ]),
        const SizedBox(height: AppSpacing.lg),
        _section('Informasi & Bantuan', [
          _SettingItem(
            icon: Icons.privacy_tip_outlined,
            label: 'Privasi',
            onTap: () => context.push(AppRoutes.privacy),
          ),
          _SettingItem(
            icon: Icons.help_outline,
            label: 'Bantuan',
            onTap: () => context.push(AppRoutes.help),
          ),
          _SettingItem(
            icon: Icons.info_outline,
            label: 'Tentang HepaSense',
            onTap: () => context.push(AppRoutes.about),
          ),
        ]),
        const SizedBox(height: AppSpacing.xl),
        AppButton(
          text: 'Keluar',
          icon: Icons.logout,
          variant: AppButtonVariant.outline,
          isLoading: _loggingOut,
          onPressed: _loggingOut ? null : _confirmLogout,
        ),
      ],
    );
  }

  Widget _section(String title, List<_SettingItem> items) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: const EdgeInsets.only(
          left: AppSpacing.xs,
          bottom: AppSpacing.sm,
        ),
        child: Semantics(
          header: true,
          child: Text(title, style: Theme.of(context).textTheme.titleSmall),
        ),
      ),
      AppCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            for (var index = 0; index < items.length; index++) ...[
              items[index],
              if (index < items.length - 1)
                const Divider(height: 1, indent: 56),
            ],
          ],
        ),
      ),
    ],
  );

  String _initials(AccountProfile profile) {
    final values = [profile.firstName, profile.lastName]
        .where((value) => value.trim().isNotEmpty)
        .map((value) => value.trim()[0].toUpperCase())
        .join();
    return values.isEmpty ? 'H' : values;
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar dari akun?'),
        content: const Text(
          'Anda perlu login kembali untuk mengakses data HepaSense.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _loggingOut = true);
    await ref.read(pushCoordinatorProvider).onLogout();
    await ref.read(authControllerProvider.notifier).logout();
  }
}

class _SettingItem extends StatelessWidget {
  const _SettingItem({
    required this.icon,
    required this.label,
    this.value,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: onTap != null,
    label: value == null ? label : '$label, $value',
    child: ListTile(
      minVerticalPadding: 12,
      leading: Icon(icon, size: 22),
      title: Text(label),
      subtitle: value == null
          ? null
          : Text(value!, maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: onTap == null
          ? null
          : const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    ),
  );
}
