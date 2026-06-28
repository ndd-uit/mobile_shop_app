import 'package:flutter/material.dart';

import '../../models/product.dart';
import '../../services/category_service.dart';
import '../../services/product_service.dart';
import '../../theme/app_theme.dart';
import '../widgets/admin_feedback.dart';
import '../widgets/admin_shell.dart';

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  String query = '';
  String category = 'Tất cả danh mục';
  String stock = 'Tồn kho';
  String status = 'Trạng thái';
  late Future<List<_AdminProduct>> productsFuture;
  late Future<List<String>> categoriesFuture;

  @override
  void initState() {
    super.initState();
    productsFuture = _loadProducts();
    categoriesFuture = CategoryService.fetchNames();
  }

  Future<List<_AdminProduct>> _loadProducts() async {
    final products = await ProductService.fetchAdminAll();
    return products.map(_AdminProduct.fromProduct).toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_ProductsPageData>(
      future: Future.wait([
        productsFuture,
        categoriesFuture,
      ]).then((values) => _ProductsPageData(
            products: values[0] as List<_AdminProduct>,
            categories: values[1] as List<String>,
          )),
      builder: (context, snapshot) {
        final loading = snapshot.connectionState == ConnectionState.waiting;
        final hasError = snapshot.hasError;
        final allProducts = snapshot.data?.products ?? const <_AdminProduct>[];
        final categories = snapshot.data?.categories ?? const <String>[];
        final products = allProducts.where((product) {
          final matchesQuery = query.isEmpty ||
              product.name.toLowerCase().contains(query.toLowerCase()) ||
              product.code.toLowerCase().contains(query.toLowerCase());
          final matchesCategory =
              category == 'Tất cả danh mục' || product.category == category;
          final matchesStock = stock == 'Tồn kho' ||
              (stock == 'Còn hàng' && product.stock > 5) ||
              (stock == 'Sắp hết' && product.stock > 0 && product.stock <= 5) ||
              (stock == 'Hết hàng' && product.stock == 0);
          final matchesStatus =
              status == 'Trạng thái' || product.status == status;
          return matchesQuery &&
              matchesCategory &&
              matchesStock &&
              matchesStatus;
        }).toList();

        return AdminShell(
          currentSection: AdminSection.products,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _PageHeader(
                onCreate: () => Navigator.pushNamed(
                  context,
                  '/admin/products/form',
                ),
              ),
              const SizedBox(height: 32),
              _FilterBar(
                onQueryChanged: (value) => setState(() => query = value),
                category: category,
                categories: categories,
                stock: stock,
                status: status,
                onCategoryChanged: (value) => setState(() => category = value),
                onStockChanged: (value) => setState(() => stock = value),
                onStatusChanged: (value) => setState(() => status = value),
              ),
              const SizedBox(height: 24),
              if (loading)
                const AdminStatePanel.loading()
              else if (hasError)
                AdminStatePanel.error(onAction: _refreshProducts)
              else if (products.isEmpty)
                AdminStatePanel.empty(
                  title: 'Không tìm thấy sản phẩm',
                  message: 'Thử đổi từ khóa hoặc bộ lọc để xem thêm kết quả.',
                  actionLabel: 'Xóa bộ lọc',
                  onAction: _clearFilters,
                )
              else
                _ProductsTable(
                  products: products,
                  onEdit: _editProduct,
                  onToggleVisibility: _toggleProductVisibility,
                  onInventory: _openInventoryDialog,
                ),
            ],
          ),
        );
      },
    );
  }

  void _refreshProducts() {
    setState(() {
      productsFuture = _loadProducts();
      categoriesFuture = CategoryService.fetchNames();
    });
  }

  void _clearFilters() {
    setState(() {
      query = '';
      category = 'Tất cả danh mục';
      stock = 'Tồn kho';
      status = 'Trạng thái';
    });
  }

  void _editProduct(_AdminProduct product) {
    Navigator.pushNamed(
      context,
      '/admin/products/form',
      arguments: {'mode': 'edit', 'id': product.id, 'name': product.name},
    );
  }

  Future<void> _toggleProductVisibility(_AdminProduct product) async {
    final hidden = product.hidden;
    final confirmed = await showAdminConfirmDialog(
      context: context,
      title: hidden ? 'Hiện sản phẩm?' : 'Ẩn sản phẩm?',
      message: hidden
          ? 'Sản phẩm sẽ được hiển thị lại trên cửa hàng.'
          : 'Sản phẩm sẽ bị ẩn khỏi cửa hàng nhưng dữ liệu vẫn được giữ lại.',
      confirmLabel: hidden ? 'Hiện sản phẩm' : 'Ẩn sản phẩm',
    );
    if (!confirmed || !mounted) return;
    try {
      await ProductService.setActive(id: product.id, isActive: hidden);
      if (!mounted) return;
      _showMessage(context, hidden ? 'Đã hiện sản phẩm' : 'Đã ẩn sản phẩm');
      _refreshProducts();
    } catch (error) {
      if (!mounted) return;
      _showMessage(context, 'Không cập nhật được sản phẩm: $error');
    }
  }

  void _openInventoryDialog(_AdminProduct product) {
    showAdminConfirmDialog(
      context: context,
      title: 'Cập nhật tồn kho',
      message: 'Mở form điều chỉnh tồn kho cho ${product.name} ở bước nối dữ liệu.',
      confirmLabel: 'Đã hiểu',
    );
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}

class _PageHeader extends StatelessWidget {
  final VoidCallback onCreate;

  const _PageHeader({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 700;
        final title = const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quản lý sản phẩm',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 4),
            Text(
              'Quản lý danh sách, tồn kho và trạng thái sản phẩm của cửa hàng.',
              style: TextStyle(color: AppTheme.secondary),
            ),
          ],
        );
        final button = FilledButton.icon(
          onPressed: () => Navigator.pushNamed(context, '/admin/products/form'),
          icon: const Icon(Icons.add),
          label: const Text('Thêm sản phẩm'),
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.primaryContainer,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [title, const SizedBox(height: 14), button],
          );
        }
        return Row(children: [Expanded(child: title), button]);
      },
    );
  }
}

class _FilterBar extends StatelessWidget {
  final ValueChanged<String> onQueryChanged;
  final String category;
  final List<String> categories;
  final String stock;
  final String status;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<String> onStockChanged;
  final ValueChanged<String> onStatusChanged;

  const _FilterBar({
    required this.onQueryChanged,
    required this.category,
    required this.categories,
    required this.stock,
    required this.status,
    required this.onCategoryChanged,
    required this.onStockChanged,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _panelDecoration(),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(width: 256, child: _SearchField(onChanged: onQueryChanged)),
          SizedBox(
            width: 192,
            child: _SelectBox(
              value: category,
              options: ['Tất cả danh mục', ...categories],
              onChanged: onCategoryChanged,
            ),
          ),
          SizedBox(
            width: 160,
            child: _SelectBox(
              value: stock,
              options: const ['Tồn kho', 'Còn hàng', 'Sắp hết', 'Hết hàng'],
              onChanged: onStockChanged,
            ),
          ),
          SizedBox(
            width: 160,
            child: _SelectBox(
              value: status,
              options: const ['Trạng thái', 'Đang bán', 'Sắp hết', 'Đã ẩn'],
              onChanged: onStatusChanged,
            ),
          ),
          const _ViewToggle(),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final ValueChanged<String> onChanged;

  const _SearchField({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Tên, mã sản phẩm...',
        prefixIcon: Icon(Icons.search, size: 20),
        contentPadding: EdgeInsets.symmetric(vertical: 10),
      ),
    );
  }
}

class _SelectBox extends StatelessWidget {
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  const _SelectBox({required this.value, required this.options, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12)),
      items: [
        for (final option in options) DropdownMenuItem(value: option, child: Text(option)),
      ],
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }
}

class _ViewToggle extends StatelessWidget {
  const _ViewToggle();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.only(left: 12),
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: AppTheme.outlineVariant)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ViewButton(icon: Icons.table_rows, selected: true),
          const SizedBox(width: 4),
          _ViewButton(icon: Icons.grid_view, selected: false),
        ],
      ),
    );
  }
}

class _ViewButton extends StatelessWidget {
  final IconData icon;
  final bool selected;

  const _ViewButton({required this.icon, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: selected
            ? AppTheme.primaryFixedDim.withValues(alpha: 0.22)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(icon, size: 20, color: selected ? AppTheme.primary : AppTheme.secondary),
    );
  }
}

class _ProductsTable extends StatelessWidget {
  final List<_AdminProduct> products;
  final ValueChanged<_AdminProduct> onEdit;
  final ValueChanged<_AdminProduct> onToggleVisibility;
  final ValueChanged<_AdminProduct> onInventory;

  const _ProductsTable({
    required this.products,
    required this.onEdit,
    required this.onToggleVisibility,
    required this.onInventory,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _panelDecoration(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 1040,
              child: Table(
                columnWidths: const {
                  0: FixedColumnWidth(96),
                  1: FlexColumnWidth(2.2),
                  2: FixedColumnWidth(130),
                  3: FixedColumnWidth(130),
                  4: FixedColumnWidth(96),
                  5: FixedColumnWidth(130),
                  6: FixedColumnWidth(132),
                },
                children: [
                  const TableRow(
                    decoration: BoxDecoration(color: AppTheme.surfaceContainerLow),
                    children: [
                      _HeaderCell('Hình ảnh'),
                      _HeaderCell('Tên sản phẩm'),
                      _HeaderCell('Danh mục'),
                      _HeaderCell('Giá'),
                      _HeaderCell('Tồn kho'),
                      _HeaderCell('Trạng thái'),
                      _HeaderCell('Hành động', alignRight: true),
                    ],
                  ),
                  for (final product in products) _productRow(product),
                ],
              ),
            ),
          ),
          const _Pagination(),
        ],
      ),
    );
  }

  TableRow _productRow(_AdminProduct product) {
    return TableRow(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppTheme.surfaceContainer)),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Opacity(
            opacity: product.hidden ? 0.6 : 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(
                product.imageUrl,
                width: 48,
                height: 56,
                fit: BoxFit.cover,
                color: product.hidden ? Colors.grey : null,
                colorBlendMode: product.hidden ? BlendMode.saturation : null,
                errorBuilder: (_, _, _) => Container(
                  width: 48,
                  height: 56,
                  color: AppTheme.surfaceContainer,
                  child: const Icon(Icons.image_not_supported_outlined),
                ),
              ),
            ),
          ),
        ),
        _ProductNameCell(product: product),
        _BodyCell(product.category, muted: true),
        _BodyCell(product.price, color: AppTheme.primary, fontWeight: FontWeight.w600),
        _BodyCell(
          '${product.stock}',
          color: product.stock <= 5 ? AppTheme.onErrorContainer : AppTheme.onSurface,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Align(
            alignment: Alignment.centerLeft,
            child: _StatusPill(label: product.status, tone: product.tone),
          ),
        ),
        _ActionsCell(
          hidden: product.hidden,
          onEdit: () => onEdit(product),
          onToggleVisibility: () => onToggleVisibility(product),
          onInventory: () => onInventory(product),
        ),
      ],
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  final bool alignRight;

  const _HeaderCell(this.text, {this.alignRight = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Text(
        text,
        textAlign: alignRight ? TextAlign.right : TextAlign.left,
        style: const TextStyle(
          color: AppTheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _BodyCell extends StatelessWidget {
  final String text;
  final bool muted;
  final Color? color;
  final FontWeight fontWeight;

  const _BodyCell(
    this.text, {
    this.muted = false,
    this.color,
    this.fontWeight = FontWeight.w500,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
      child: Text(
        text,
        style: TextStyle(
          color: color ?? (muted ? AppTheme.secondary : AppTheme.onSurface),
          fontWeight: fontWeight,
        ),
      ),
    );
  }
}

class _ProductNameCell extends StatelessWidget {
  final _AdminProduct product;

  const _ProductNameCell({required this.product});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Opacity(
        opacity: product.hidden ? 0.6 : 1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppTheme.onSurface,
                fontWeight: FontWeight.w600,
                decoration: product.hidden ? TextDecoration.lineThrough : null,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              product.code,
              style: const TextStyle(color: AppTheme.secondary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final _ProductTone tone;

  const _StatusPill({required this.label, required this.tone});

  @override
  Widget build(BuildContext context) {
    final colors = switch (tone) {
      _ProductTone.active => (const Color(0xFFE6F4EA), const Color(0xFF1E8E3E)),
      _ProductTone.low => (const Color(0xFFFEF7E0), const Color(0xFFB06000)),
      _ProductTone.hidden => (AppTheme.surfaceContainer, AppTheme.secondary),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: colors.$2,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ActionsCell extends StatelessWidget {
  final bool hidden;
  final VoidCallback onEdit;
  final VoidCallback onToggleVisibility;
  final VoidCallback onInventory;

  const _ActionsCell({
    required this.hidden,
    required this.onEdit,
    required this.onToggleVisibility,
    required this.onInventory,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _IconAction(icon: Icons.edit_outlined, tooltip: 'Sửa sản phẩm', onPressed: onEdit),
          _IconAction(
            icon: hidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            tooltip: hidden ? 'Hiện sản phẩm' : 'Ẩn sản phẩm',
            onPressed: onToggleVisibility,
          ),
          _IconAction(
            icon: Icons.inventory_2_outlined,
            tooltip: 'Cập nhật tồn kho',
            onPressed: onInventory,
          ),
        ],
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _IconAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 32,
      child: IconButton(
        onPressed: onPressed,
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        icon: Icon(icon, size: 18, color: AppTheme.secondary),
      ),
    );
  }
}

class _Pagination extends StatelessWidget {
  const _Pagination();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppTheme.surfaceContainer)),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Hiển thị 1-3 của 124 sản phẩm',
              style: TextStyle(color: AppTheme.secondary, fontSize: 12),
            ),
          ),
          _PageButton(icon: Icons.chevron_left, disabled: true),
          _PageButton(label: '1', selected: true),
          _PageButton(label: '2'),
          _PageButton(label: '3'),
          _PageButton(icon: Icons.chevron_right),
        ],
      ),
    );
  }
}

class _PageButton extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final bool selected;
  final bool disabled;

  const _PageButton({
    this.label,
    this.icon,
    this.selected = false,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: disabled ? 0.45 : 1,
      child: Container(
        width: 32,
        height: 32,
        margin: const EdgeInsets.only(left: 4),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: icon == null
            ? Text(
                label!,
                style: TextStyle(
                  color: selected ? AppTheme.onPrimaryContainer : AppTheme.secondary,
                  fontWeight: FontWeight.w600,
                ),
              )
            : Icon(icon, size: 18, color: AppTheme.secondary),
      ),
    );
  }
}

class _AdminProduct {
  final String id;
  final String code;
  final String name;
  final String category;
  final String price;
  final int stock;
  final String status;
  final _ProductTone tone;
  final String imageUrl;
  final bool hidden;

  const _AdminProduct({
    required this.id,
    required this.code,
    required this.name,
    required this.category,
    required this.price,
    required this.stock,
    required this.status,
    required this.tone,
    required this.imageUrl,
    this.hidden = false,
  });

  factory _AdminProduct.fromProduct(Product product) {
    final hidden = !product.isActive;
    final lowStock = product.stock > 0 && product.stock <= 5;
    return _AdminProduct(
      id: product.id,
      code: product.id.toUpperCase(),
      name: product.name,
      category: product.category,
      price: _formatCurrency(product.price),
      stock: product.stock,
      status: hidden ? 'Đã ẩn' : (lowStock ? 'Sắp hết' : 'Đang bán'),
      tone: hidden ? _ProductTone.hidden : (lowStock ? _ProductTone.low : _ProductTone.active),
      imageUrl: product.imageUrl,
      hidden: hidden,
    );
  }
}

String _formatCurrency(int value) {
  final raw = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < raw.length; i++) {
    final position = raw.length - i;
    buffer.write(raw[i]);
    if (position > 1 && position % 3 == 1) buffer.write('.');
  }
  return '$bufferđ';
}

enum _ProductTone { active, low, hidden }

class _ProductsPageData {
  final List<_AdminProduct> products;
  final List<String> categories;

  const _ProductsPageData({required this.products, required this.categories});
}

BoxDecoration _panelDecoration() {
  return BoxDecoration(
    color: AppTheme.surface,
    border: Border.all(color: AppTheme.surfaceContainer),
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.05),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  );
}
