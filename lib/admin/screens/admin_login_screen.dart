import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../services/admin_auth_service.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  bool rememberMe = false;
  bool obscurePassword = true;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _redirectIfAlreadyAdmin();
  }

  Future<void> _redirectIfAlreadyAdmin() async {
    final isAdmin = await AdminAuthService.hasAdminSession();
    if (!mounted || !isAdmin) return;
    Navigator.pushReplacementNamed(context, '/admin/dashboard');
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (usernameController.text.trim().isEmpty ||
        passwordController.text.isEmpty) {
      _showMessage('Vui lòng nhập đầy đủ thông tin đăng nhập');
      return;
    }

    setState(() => isLoading = true);
    try {
      await AdminAuthService.login(
        username: usernameController.text.trim(),
        password: passwordController.text,
      );
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/admin/dashboard');
    } catch (error) {
      if (!mounted) return;
      _showMessage('Đăng nhập thất bại: $error');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: _LoginPanel(
                usernameController: usernameController,
                passwordController: passwordController,
                rememberMe: rememberMe,
                obscurePassword: obscurePassword,
                onRememberChanged: (value) {
                  setState(() => rememberMe = value ?? false);
                },
                onTogglePassword: () {
                  setState(() {
                    obscurePassword = !obscurePassword;
                  });
                },
                onForgotPassword: () {
                  _showMessage('Vui lòng liên hệ chủ shop để đặt lại mật khẩu');
                },
                          onSupport: () {
                            _showMessage('Hỗ trợ kỹ thuật: 1900 1234');
                          },
                          onSubmit: _submit,
                          isLoading: isLoading,
                        ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginPanel extends StatelessWidget {
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final bool rememberMe;
  final bool obscurePassword;
  final ValueChanged<bool?> onRememberChanged;
  final VoidCallback onTogglePassword;
  final VoidCallback onForgotPassword;
  final VoidCallback onSupport;
  final VoidCallback onSubmit;
  final bool isLoading;

  const _LoginPanel({
    required this.usernameController,
    required this.passwordController,
    required this.rememberMe,
    required this.obscurePassword,
    required this.onRememberChanged,
    required this.onTogglePassword,
    required this.onForgotPassword,
    required this.onSupport,
    required this.onSubmit,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.surfaceContainerLow),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _AdminHeader(),
            const SizedBox(height: 32),
            Text(
              'Email admin',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppTheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: usernameController,
              autofillHints: const [AutofillHints.username],
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                hintText: 'admin@daisyshop.app',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Mật khẩu admin',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppTheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: passwordController,
              obscureText: obscurePassword,
              autofillHints: const [AutofillHints.password],
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => onSubmit(),
              decoration: InputDecoration(
                hintText: '••••••••',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  onPressed: onTogglePassword,
                  icon: Icon(
                    obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onForgotPassword,
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Quên mật khẩu?'),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Checkbox(
                  value: rememberMe,
                  onChanged: onRememberChanged,
                  activeColor: AppTheme.primary,
                ),
                const Expanded(
                  child: Text(
                    'Ghi nhớ đăng nhập',
                    style: TextStyle(color: AppTheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: isLoading ? null : onSubmit,
              iconAlignment: IconAlignment.end,
              icon: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.arrow_forward),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryContainer,
                foregroundColor: AppTheme.onPrimary,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              label: const Text(
                'Đăng nhập',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: onSupport,
              style: TextButton.styleFrom(foregroundColor: AppTheme.primary),
              child: const Text('Bạn gặp sự cố? Liên hệ hỗ trợ kỹ thuật'),
            ),
            const SizedBox(height: 4),
            const Text(
              'Chỉ dành cho nhân sự được cấp quyền',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.secondary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminHeader extends StatelessWidget {
  const _AdminHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppTheme.primaryContainer.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.admin_panel_settings,
            color: AppTheme.primary,
            size: 40,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Daisy Admin',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            color: AppTheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Hệ thống quản trị Daisy Shop',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.secondary, fontSize: 14),
        ),
      ],
    );
  }
}
