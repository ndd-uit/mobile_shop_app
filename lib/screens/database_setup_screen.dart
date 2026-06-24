import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class DatabaseSetupScreen extends StatelessWidget {
  const DatabaseSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryFixed,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.storage_outlined,
                      size: 42,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Chưa cấu hình cơ sở dữ liệu',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Điền Supabase Project URL và anon key thật vào file .env, sau đó khởi động lại ứng dụng.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'SUPABASE_URL=https://....supabase.co\nSUPABASE_ANON_KEY=eyJ...',
                      style: TextStyle(fontFamily: 'monospace', height: 1.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
