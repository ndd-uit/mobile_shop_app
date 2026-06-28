import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../services/admin_auth_service.dart';

enum AdminSection { dashboard, products, orders, vouchers }

class AdminShell extends StatelessWidget {
  final AdminSection currentSection;
  final Widget child;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onCreatePressed;
  final bool showSearch;
  final Widget? breadcrumb;

  const AdminShell({
    super.key,
    required this.currentSection,
    required this.child,
    this.onSearchChanged,
    this.onCreatePressed,
    this.showSearch = true,
    this.breadcrumb,
  });

  static const _avatarUrl =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuDuTudBfcA3AnRb8K-NatVIY49Inl1qMZS_JsFy1pQvnRv8PlfVwgQ4Idv4Nd_mFwnSqV7CKp6ITzdZKJ4e3l40hPOd5OBW6o4z--kMfUXtSX3UgkLTzFSegRoy1dj8CpuMTteMDAAkzzaXKAof3tqiZIuIHfIK0Z_hCzjL9pr1oiRoamfv07plt0ZaUFgxuHCHEMB5xkHTCEJ-dTZD7uoMaJtLC_PZuk8gK8vtarjNGLpJFQGv-XabiX103n2BkOzHCU0isMg57Fw';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      drawer: _AdminDrawer(currentSection: currentSection),
      floatingActionButton: onCreatePressed == null
          ? null
          : FloatingActionButton(
              onPressed: onCreatePressed,
              backgroundColor: AppTheme.primary,
              foregroundColor: AppTheme.onPrimary,
              child: const Icon(Icons.add),
            ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final desktop = constraints.maxWidth >= 980;
          return Row(
            children: [
              if (desktop)
                SizedBox(
                  width: 256,
                  child: _AdminSidebar(currentSection: currentSection),
                ),
              Expanded(
                child: Column(
                  children: [
                    _AdminTopBar(
                      desktop: desktop,
                      onSearchChanged: onSearchChanged,
                      showSearch: showSearch,
                      breadcrumb: breadcrumb,
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(
                          desktop ? 24 : 16,
                          24,
                          desktop ? 24 : 16,
                          32,
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1184),
                            child: child,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AdminTopBar extends StatefulWidget {
  final bool desktop;
  final ValueChanged<String>? onSearchChanged;
  final bool showSearch;
  final Widget? breadcrumb;

  const _AdminTopBar({
    required this.desktop,
    this.onSearchChanged,
    required this.showSearch,
    this.breadcrumb,
  });

  @override
  State<_AdminTopBar> createState() => _AdminTopBarState();
}

class _AdminTopBarState extends State<_AdminTopBar> {
  final searchController = TextEditingController();

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(bottom: BorderSide(color: AppTheme.outlineVariant)),
      ),
      child: Row(
        children: [
          if (!widget.desktop)
            IconButton(
              onPressed: () => Scaffold.of(context).openDrawer(),
              icon: const Icon(Icons.menu),
            ),
          if (widget.showSearch)
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: widget.desktop ? 420 : 260,
                minWidth: widget.desktop ? 360 : 0,
              ),
              child: TextField(
                controller: searchController,
                onChanged: widget.onSearchChanged,
                decoration: const InputDecoration(
                  hintText: 'Tìm kiếm đơn hàng, sản phẩm...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(999)),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            )
          else
            Expanded(child: widget.breadcrumb ?? const SizedBox.shrink()),
          if (widget.showSearch) const Spacer() else const SizedBox(width: 16),
          _IconBadgeButton(icon: Icons.notifications_outlined, hasBadge: true),
          const SizedBox(width: 8),
          _IconBadgeButton(icon: Icons.settings_outlined),
          if (widget.desktop) ...[
            const SizedBox(width: 16),
            Container(width: 1, height: 28, color: AppTheme.outlineVariant),
            const SizedBox(width: 16),
            InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () async {
                await AdminAuthService.logout();
                if (!context.mounted) return;
                Navigator.pushNamedAndRemoveUntil(context, '/admin', (_) => false);
              },
              child: const CircleAvatar(
                radius: 16,
                backgroundImage: NetworkImage(AdminShell._avatarUrl),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () async {
                await AdminAuthService.logout();
                if (!context.mounted) return;
                Navigator.pushNamedAndRemoveUntil(context, '/admin', (_) => false);
              },
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.onSurface,
                padding: EdgeInsets.zero,
                minimumSize: const Size(48, 36),
              ),
              child: const Text(
                'Admin',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _IconBadgeButton extends StatelessWidget {
  final IconData icon;
  final bool hasBadge;

  const _IconBadgeButton({required this.icon, this.hasBadge = false});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(onPressed: () {}, icon: Icon(icon)),
        if (hasBadge)
          const Positioned(
            top: 12,
            right: 12,
            child: SizedBox(
              width: 8,
              height: 8,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppTheme.error,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _AdminDrawer extends StatelessWidget {
  final AdminSection currentSection;

  const _AdminDrawer({required this.currentSection});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      shape: const RoundedRectangleBorder(),
      child: _AdminSidebar(currentSection: currentSection),
    );
  }
}

class _AdminSidebar extends StatelessWidget {
  final AdminSection currentSection;

  const _AdminSidebar({required this.currentSection});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(right: BorderSide(color: AppTheme.outlineVariant)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daisy Admin',
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Fashion Boutique',
                    style: TextStyle(color: AppTheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            _NavItem(
              icon: Icons.dashboard_outlined,
              label: 'Dashboard',
              selected: currentSection == AdminSection.dashboard,
              routeName: '/admin/dashboard',
            ),
            _NavItem(
              icon: Icons.inventory_2_outlined,
              label: 'Products',
              selected: currentSection == AdminSection.products,
              routeName: '/admin/products',
            ),
            _NavItem(
              icon: Icons.shopping_cart_outlined,
              label: 'Orders',
              selected: currentSection == AdminSection.orders,
              routeName: '/admin/orders',
            ),
            _NavItem(
              icon: Icons.confirmation_number_outlined,
              label: 'Vouchers',
              selected: currentSection == AdminSection.vouchers,
              routeName: '/admin/vouchers',
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final String routeName;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.routeName,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: ListTile(
        selected: selected,
        selectedTileColor: AppTheme.primaryContainer,
        selectedColor: AppTheme.onPrimaryContainer,
        textColor: AppTheme.secondary,
        iconColor: selected ? AppTheme.onPrimaryContainer : AppTheme.secondary,
        leading: Icon(icon),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        onTap: () {
          final scaffold = Scaffold.maybeOf(context);
          if (scaffold?.isDrawerOpen == true) {
            Navigator.pop(context);
          }
          if (!selected) Navigator.pushReplacementNamed(context, routeName);
        },
      ),
    );
  }
}
