import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class ChangePasswordScreen extends StatefulWidget {
  final VoidCallback onBack;

  const ChangePasswordScreen({super.key, required this.onBack});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final formKey = GlobalKey<FormState>();
  final passwordController = TextEditingController();
  final confirmationController = TextEditingController();
  bool obscurePassword = true;
  bool obscureConfirmation = true;
  bool submitting = false;

  @override
  void dispose() {
    passwordController.dispose();
    confirmationController.dispose();
    super.dispose();
  }

  bool get hasMinimumLength => passwordController.text.length >= 8;
  bool get hasLetter => RegExp(r'[A-Za-z]').hasMatch(passwordController.text);
  bool get hasNumber => RegExp(r'\d').hasMatch(passwordController.text);

  Future<void> changePassword() async {
    FocusScope.of(context).unfocus();
    if (!(formKey.currentState?.validate() ?? false)) return;

    setState(() => submitting = true);
    await Future<void>.delayed(const Duration(milliseconds: 550));
    if (!mounted) return;
    setState(() => submitting = false);

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: AppTheme.primary, size: 52),
        title: const Text('Đổi mật khẩu thành công'),
        content: const Text(
          'Mật khẩu mới đã được cập nhật cho tài khoản của bạn.',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hoàn tất'),
          ),
        ],
      ),
    );
    if (mounted) widget.onBack();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppTheme.surface,
        leading: IconButton(
          onPressed: widget.onBack,
          icon: const Icon(Icons.arrow_back),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 18),
            child: Center(
              child: Text(
                'Daisy Shop',
                style: TextStyle(
                  color: AppTheme.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 26, 20, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 88,
                        height: 88,
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryFixed,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.lock_reset,
                          color: AppTheme.primary,
                          size: 42,
                        ),
                      ),
                    ),
                    const SizedBox(height: 26),
                    const Text(
                      'Tạo mật khẩu mới',
                      style: TextStyle(
                        color: AppTheme.onSurface,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Mật khẩu mới cần có ít nhất 8 ký tự, bao gồm chữ cái và chữ số.',
                      style: TextStyle(
                        color: AppTheme.onSurfaceVariant,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'Mật khẩu mới',
                      style: TextStyle(
                        color: AppTheme.onSurfaceVariant,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: passwordController,
                      autofocus: true,
                      obscureText: obscurePassword,
                      textInputAction: TextInputAction.next,
                      onChanged: (_) => setState(() {}),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập mật khẩu mới';
                        }
                        if (!hasMinimumLength || !hasLetter || !hasNumber) {
                          return 'Mật khẩu chưa đáp ứng yêu cầu';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        hintText: 'Nhập mật khẩu mới',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: () => setState(
                            () => obscurePassword = !obscurePassword,
                          ),
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Xác nhận mật khẩu mới',
                      style: TextStyle(
                        color: AppTheme.onSurfaceVariant,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: confirmationController,
                      obscureText: obscureConfirmation,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => changePassword(),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập lại mật khẩu mới';
                        }
                        if (value != passwordController.text) {
                          return 'Mật khẩu xác nhận không khớp';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        hintText: 'Nhập lại mật khẩu mới',
                        prefixIcon: const Icon(Icons.lock_reset_outlined),
                        suffixIcon: IconButton(
                          onPressed: () => setState(
                            () => obscureConfirmation = !obscureConfirmation,
                          ),
                          icon: Icon(
                            obscureConfirmation
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          _RequirementRow(
                            passed: hasMinimumLength,
                            text: 'Ít nhất 8 ký tự',
                          ),
                          _RequirementRow(
                            passed: hasLetter,
                            text: 'Có ít nhất một chữ cái',
                          ),
                          _RequirementRow(
                            passed: hasNumber,
                            text: 'Có ít nhất một chữ số',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 26),
                    FilledButton.icon(
                      onPressed: submitting ? null : changePassword,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primaryContainer,
                        foregroundColor: AppTheme.onPrimaryContainer,
                        minimumSize: const Size.fromHeight(54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.lock_reset),
                      label: Text(
                        submitting ? 'Đang cập nhật...' : 'Đổi mật khẩu',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 34),
                    const Row(
                      children: [
                        Expanded(child: Divider(indent: 36, endIndent: 12)),
                        Icon(
                          Icons.local_florist,
                          color: AppTheme.outlineVariant,
                        ),
                        Expanded(child: Divider(indent: 12, endIndent: 36)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RequirementRow extends StatelessWidget {
  final bool passed;
  final String text;

  const _RequirementRow({required this.passed, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(
            passed ? Icons.check_circle : Icons.circle_outlined,
            size: 17,
            color: passed ? AppTheme.primary : AppTheme.outline,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: passed ? AppTheme.onSurface : AppTheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
