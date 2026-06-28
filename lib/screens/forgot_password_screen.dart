import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';

enum _RecoveryStep { phone, otp, password, success }

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  static const _bannerUrl =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuDfu98BYo9aRaaqH77Ud41YYXgYLPt2EsImR1891aReFN6ivqmTlKrNKRVGg_e_13JDNetHLMQ1bjuOdRCJmDGlBP2u5x2gBosWvz30rjWWdAklGELvP-ROODhx73RRl7PODQpZFtBTxL0qch4-qxG4k9ZGibfczrm2nQBvTzZuwdKugmvgT45r2VaZ4tyPVYVAF-R-nHbZ2JvSrWZODY6xRQaoOeTHDiloGgdZCCONqAux4fyHQc3qbWct1HNXIHhpiLOjKe9fJIQ';

  final phoneController = TextEditingController();
  final otpController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmationController = TextEditingController();

  _RecoveryStep step = _RecoveryStep.phone;
  Timer? timer;
  int resendSeconds = 0;
  bool obscurePassword = true;
  bool obscureConfirmation = true;
  bool sending = false;

  @override
  void dispose() {
    timer?.cancel();
    phoneController.dispose();
    otpController.dispose();
    passwordController.dispose();
    confirmationController.dispose();
    super.dispose();
  }

  void startCountdown() {
    timer?.cancel();
    setState(() => resendSeconds = 60);
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (resendSeconds <= 1) {
        timer.cancel();
        setState(() => resendSeconds = 0);
      } else {
        setState(() => resendSeconds--);
      }
    });
  }

  Future<void> sendOtp() async {
    final phone = phoneController.text.trim();
    if (!RegExp(r'^0\d{9}$').hasMatch(phone)) {
      showMessage('Số điện thoại phải gồm 10 chữ số và bắt đầu bằng 0');
      return;
    }
    setState(() => sending = true);
    try {
      await AuthService.sendPasswordResetForPhone(phone);
    } catch (e) {
      if (!mounted) return;
      setState(() => sending = false);
      showMessage('Không thể gửi yêu cầu đặt lại mật khẩu. Vui lòng thử lại.');
      return;
    }
    if (!mounted) return;
    setState(() {
      sending = false;
      step = _RecoveryStep.success;
    });
    showMessage('Đã gửi yêu cầu đặt lại mật khẩu');
  }

  void verifyOtp() {
    if (otpController.text != '123456') {
      showMessage('Mã OTP không chính xác');
      return;
    }
    timer?.cancel();
    setState(() => step = _RecoveryStep.password);
  }

  void updatePassword() {
    if (passwordController.text.length < 6) {
      showMessage('Mật khẩu mới cần ít nhất 6 ký tự');
      return;
    }
    if (passwordController.text != confirmationController.text) {
      showMessage('Mật khẩu xác nhận không khớp');
      return;
    }
    setState(() => step = _RecoveryStep.success);
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  void goBack() {
    switch (step) {
      case _RecoveryStep.phone:
        Navigator.pop(context);
      case _RecoveryStep.otp:
        timer?.cancel();
        setState(() => step = _RecoveryStep.phone);
      case _RecoveryStep.password:
        setState(() => step = _RecoveryStep.otp);
        startCountdown();
      case _RecoveryStep.success:
        Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: step == _RecoveryStep.phone,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) goBack();
      },
      child: Scaffold(
        backgroundColor: AppTheme.surface,
        appBar: AppBar(
          backgroundColor: AppTheme.surface,
          leading: IconButton(
            onPressed: goBack,
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
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.05, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  child: _buildStep(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep() {
    return switch (step) {
      _RecoveryStep.phone => _PhoneStep(
        key: const ValueKey('phone'),
        bannerUrl: _bannerUrl,
        controller: phoneController,
        onContinue: sending ? null : sendOtp,
        onSupport: () => showMessage('Hotline hỗ trợ: 1900 1234'),
        sending: sending,
      ),
      _RecoveryStep.otp => _OtpStep(
        key: const ValueKey('otp'),
        phoneNumber: phoneController.text,
        controller: otpController,
        resendSeconds: resendSeconds,
        onVerify: verifyOtp,
        onResend: resendSeconds == 0 ? sendOtp : null,
      ),
      _RecoveryStep.password => _PasswordStep(
        key: const ValueKey('password'),
        passwordController: passwordController,
        confirmationController: confirmationController,
        obscurePassword: obscurePassword,
        obscureConfirmation: obscureConfirmation,
        onTogglePassword: () {
          setState(() => obscurePassword = !obscurePassword);
        },
        onToggleConfirmation: () {
          setState(() => obscureConfirmation = !obscureConfirmation);
        },
        onSubmit: updatePassword,
      ),
      _RecoveryStep.success => _SuccessStep(
        key: const ValueKey('success'),
        onLogin: () => Navigator.pop(context),
      ),
    };
  }
}

class _PhoneStep extends StatelessWidget {
  final String bannerUrl;
  final TextEditingController controller;
  final VoidCallback? onContinue;
  final VoidCallback onSupport;
  final bool sending;

  const _PhoneStep({
    super.key,
    required this.bannerUrl,
    required this.controller,
    required this.onContinue,
    required this.onSupport,
    required this.sending,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 190,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFFD9DF), Color(0xFFFFF5F6)],
                    ),
                  ),
                ),
                Image.network(
                  bannerUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0x66FBF9F9)],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 26),
        const Text(
          'Quên mật khẩu',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        const Text(
          'Vui lòng nhập số điện thoại đã đăng ký để nhận yêu cầu đặt lại mật khẩu.',
          style: TextStyle(color: AppTheme.onSurfaceVariant, height: 1.5),
        ),
        const SizedBox(height: 28),
        const Text(
          'Số điện thoại',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.done,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          onSubmitted: (_) => onContinue?.call(),
          decoration: const InputDecoration(
            hintText: 'Nhập số điện thoại của bạn',
            prefixIcon: Icon(Icons.call_outlined),
          ),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: onContinue,
          iconAlignment: IconAlignment.end,
          icon: sending
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.arrow_forward),
          label: Text(sending ? 'Đang gửi...' : 'Gửi yêu cầu'),
        ),
        const SizedBox(height: 34),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Bạn cần hỗ trợ?',
              style: TextStyle(color: AppTheme.onSurfaceVariant),
            ),
            TextButton.icon(
              onPressed: onSupport,
              icon: const Icon(Icons.headset_mic_outlined, size: 19),
              label: const Text('Liên hệ'),
            ),
          ],
        ),
      ],
    );
  }
}

class _OtpStep extends StatelessWidget {
  final String phoneNumber;
  final TextEditingController controller;
  final int resendSeconds;
  final VoidCallback onVerify;
  final VoidCallback? onResend;

  const _OtpStep({
    super.key,
    required this.phoneNumber,
    required this.controller,
    required this.resendSeconds,
    required this.onVerify,
    required this.onResend,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _StepIcon(icon: Icons.sms_outlined),
        const SizedBox(height: 26),
        const Text(
          'Nhập mã xác thực',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          'Mã OTP gồm 6 chữ số đã được gửi đến $phoneNumber.',
          style: const TextStyle(color: AppTheme.onSurfaceVariant, height: 1.5),
        ),
        const SizedBox(height: 28),
        _OtpInput(controller: controller, onCompleted: onVerify),
        const SizedBox(height: 20),
        FilledButton(onPressed: onVerify, child: const Text('Xác nhận OTP')),
        const SizedBox(height: 14),
        TextButton(
          onPressed: onResend,
          child: Text(
            resendSeconds > 0
                ? 'Gửi lại mã sau ${resendSeconds}s'
                : 'Gửi lại mã OTP',
          ),
        ),
        const Text(
          'Mã thử nghiệm: 123456',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.outline, fontSize: 12),
        ),
      ],
    );
  }
}

class _PasswordStep extends StatelessWidget {
  final TextEditingController passwordController;
  final TextEditingController confirmationController;
  final bool obscurePassword;
  final bool obscureConfirmation;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirmation;
  final VoidCallback onSubmit;

  const _PasswordStep({
    super.key,
    required this.passwordController,
    required this.confirmationController,
    required this.obscurePassword,
    required this.obscureConfirmation,
    required this.onTogglePassword,
    required this.onToggleConfirmation,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _StepIcon(icon: Icons.lock_reset),
        const SizedBox(height: 26),
        const Text(
          'Tạo mật khẩu mới',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        const Text(
          'Mật khẩu mới cần có ít nhất 6 ký tự.',
          style: TextStyle(color: AppTheme.onSurfaceVariant),
        ),
        const SizedBox(height: 28),
        TextField(
          controller: passwordController,
          autofocus: true,
          obscureText: obscurePassword,
          decoration: InputDecoration(
            labelText: 'Mật khẩu mới',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              onPressed: onTogglePassword,
              icon: Icon(
                obscurePassword ? Icons.visibility_off : Icons.visibility,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: confirmationController,
          obscureText: obscureConfirmation,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onSubmit(),
          decoration: InputDecoration(
            labelText: 'Xác nhận mật khẩu',
            prefixIcon: const Icon(Icons.lock_reset_outlined),
            suffixIcon: IconButton(
              onPressed: onToggleConfirmation,
              icon: Icon(
                obscureConfirmation ? Icons.visibility_off : Icons.visibility,
              ),
            ),
          ),
        ),
        const SizedBox(height: 22),
        FilledButton(
          onPressed: onSubmit,
          child: const Text('Cập nhật mật khẩu'),
        ),
      ],
    );
  }
}

class _SuccessStep extends StatelessWidget {
  final VoidCallback onLogin;

  const _SuccessStep({super.key, required this.onLogin});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 36),
        Container(
          width: 112,
          height: 112,
          decoration: const BoxDecoration(
            color: AppTheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check,
            size: 58,
            color: AppTheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(height: 28),
        const Text(
          'Yêu cầu đã được gửi',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        const Text(
          'Nếu tài khoản tồn tại, Daisy Shop sẽ gửi hướng dẫn đặt lại mật khẩu theo cấu hình Supabase Auth.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.onSurfaceVariant, height: 1.5),
        ),
        const SizedBox(height: 30),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: onLogin,
            child: const Text('Quay lại đăng nhập'),
          ),
        ),
      ],
    );
  }
}

class _StepIcon extends StatelessWidget {
  final IconData icon;

  const _StepIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: Container(
        width: 88,
        height: 88,
        decoration: const BoxDecoration(
          color: AppTheme.primaryFixed,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 42, color: AppTheme.primary),
      ),
    );
  }
}

class _OtpInput extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onCompleted;

  const _OtpInput({required this.controller, required this.onCompleted});

  @override
  State<_OtpInput> createState() => _OtpInputState();
}

class _OtpInputState extends State<_OtpInput> {
  final focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    focusNode.addListener(() {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: focusNode.requestFocus,
      child: SizedBox(
        height: 58,
        child: Stack(
          children: [
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: widget.controller,
              builder: (context, value, _) {
                final text = value.text;
                return Row(
                  children: List.generate(6, (index) {
                    final hasValue = index < text.length;
                    final isCurrent = index == text.length && text.length < 6;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(left: index == 0 ? 0 : 6),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          height: 56,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isCurrent && focusNode.hasFocus
                                  ? AppTheme.primary
                                  : hasValue
                                  ? AppTheme.primaryContainer
                                  : AppTheme.outlineVariant,
                              width: isCurrent || hasValue ? 1.5 : 1,
                            ),
                          ),
                          child: Text(
                            hasValue ? text[index] : '',
                            style: const TextStyle(
                              color: AppTheme.onSurface,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
            Positioned.fill(
              child: Opacity(
                opacity: 0.01,
                child: TextField(
                  controller: widget.controller,
                  focusNode: focusNode,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  onChanged: (value) {
                    setState(() {});
                    if (value.length == 6) widget.onCompleted();
                  },
                  onSubmitted: (_) => widget.onCompleted(),
                  decoration: const InputDecoration(
                    filled: false,
                    border: InputBorder.none,
                    counterText: '',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
