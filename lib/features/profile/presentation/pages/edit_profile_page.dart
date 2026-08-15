import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../data/profile_providers.dart';
import '../../domain/account_profile.dart';
import '../../domain/profile_state.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _phone = TextEditingController();
  final _birth = TextEditingController();
  bool _initialized = false;

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _phone.dispose();
    _birth.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileControllerProvider);
    if (state case ProfileLoaded(:final profile)) {
      if (!_initialized) {
        _initialized = true;
        _first.text = profile.firstName;
        _last.text = profile.lastName;
        _phone.text = profile.phoneNumber;
        _birth.text = profile.dateOfBirth ?? '';
      }
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Ubah Biodata')),
      body: SafeArea(
        child: state is! ProfileLoaded
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        initialValue: state.profile.email,
                        enabled: false,
                        decoration: const InputDecoration(labelText: 'Email'),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        label: 'Nama Depan',
                        controller: _first,
                        textInputAction: TextInputAction.next,
                        validator: _required,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        label: 'Nama Belakang',
                        controller: _last,
                        textInputAction: TextInputAction.next,
                        validator: _required,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        label: 'Nomor Telepon',
                        controller: _phone,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        validator: _required,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        label: 'Tanggal Lahir',
                        hint: 'YYYY-MM-DD',
                        controller: _birth,
                        textInputAction: TextInputAction.done,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AppButton(
                        text: 'Simpan',
                        isLoading: state.isSaving,
                        onPressed: state.isSaving ? null : _save,
                      ),
                      if (state.message != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(state.message!, textAlign: TextAlign.center),
                      ],
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Wajib diisi' : null;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final current = ref.read(profileControllerProvider);
    if (current is! ProfileLoaded) return;
    await ref
        .read(profileControllerProvider.notifier)
        .save(
          AccountProfileUpdate(
            firstName: _first.text.trim(),
            lastName: _last.text.trim(),
            phoneNumber: _phone.text.trim(),
            dateOfBirth: _birth.text.trim().isEmpty ? null : _birth.text.trim(),
            gender: current.profile.gender,
          ),
        );
  }
}
