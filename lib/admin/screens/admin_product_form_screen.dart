import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/admin_product_image_service.dart';
import '../../services/category_service.dart';
import '../../services/product_service.dart';
import '../../theme/app_theme.dart';
import '../widgets/admin_shell.dart';

class AdminProductFormScreen extends StatefulWidget {
  const AdminProductFormScreen({super.key});

  @override
  State<AdminProductFormScreen> createState() => _AdminProductFormScreenState();
}

class _AdminProductFormScreenState extends State<AdminProductFormScreen> {
  bool isActive = true;
  String selectedCategory = 'Áo';
  bool isSaving = false;
  String? editingId;

  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final priceController = TextEditingController();
  final stockController = TextEditingController();
  final imagePicker = ImagePicker();
  final imageUrls = <String>[];
  final pickedImages = <XFile>[];
  bool isUploadingImage = false;
  List<String> originalImageUrls = const [];
  late Future<List<String>> categoriesFuture;

  @override
  void initState() {
    super.initState();
    categoriesFuture = CategoryService.fetchNames();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    final id = args is Map ? args['id'] as String? : null;
    if (id != null && editingId == null) {
      editingId = id;
      _loadProduct(id);
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    stockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final editName = args is Map ? args['name'] as String? : null;
    final isEdit = args is Map && args['mode'] == 'edit';

    return AdminShell(
      currentSection: AdminSection.products,
      showSearch: false,
      breadcrumb: _ProductFormBreadcrumb(isEdit: isEdit),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PageHeader(
            isEdit: isEdit,
            productName: editName,
            onCancel: _goBack,
            onSave: _saveProduct,
          ),
          const SizedBox(height: 32),
          LayoutBuilder(
            builder: (context, constraints) {
              final desktop = constraints.maxWidth >= 980;
              if (!desktop) {
                return Column(
                  children: [
                    _leftColumn(),
                    const SizedBox(height: 24),
                    _rightColumn(),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: _leftColumn()),
                  const SizedBox(width: 24),
                  Expanded(child: _rightColumn()),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _leftColumn() {
    return Column(
      children: [
        _FormCard(
          title: 'Thông tin cơ bản',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _FieldLabel('Tên sản phẩm *'),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(hintText: 'Vd: Váy lụa thiết kế dáng dài...'),
              ),
              const SizedBox(height: 16),
              const _FieldLabel('Mô tả sản phẩm'),
              TextField(
                controller: descriptionController,
                minLines: 5,
                maxLines: 7,
                decoration: const InputDecoration(
                  hintText: 'Mô tả chất liệu, kiểu dáng, cách phối đồ...',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _FormCard(
          title: 'Giá & Tồn kho',
          child: LayoutBuilder(
            builder: (context, constraints) {
              final twoCols = constraints.maxWidth >= 520;
              final fields = [
                _PriceField(controller: priceController),
                _StockField(controller: stockController),
              ];
              if (!twoCols) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    fields[0],
                    const SizedBox(height: 16),
                    fields[1],
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: fields[0]),
                  const SizedBox(width: 16),
                  Expanded(child: fields[1]),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _rightColumn() {
    return Column(
      children: [
        _ImageCard(
          imageUrls: imageUrls,
          pickedImages: pickedImages,
          isUploading: isUploadingImage,
          onPickImages: _pickImages,
          onRemoveStoredImage: _removeStoredImage,
          onRemovePickedImage: _removePickedImage,
        ),
        const SizedBox(height: 24),
        _StatusCard(
          isActive: isActive,
          onChanged: (value) => setState(() => isActive = value),
        ),
        const SizedBox(height: 24),
        _CategoryCard(
          selected: selectedCategory,
          categoriesFuture: categoriesFuture,
          onSelected: (value) => setState(() => selectedCategory = value),
        ),
      ],
    );
  }

  void _goBack() {
    Navigator.pushReplacementNamed(context, '/admin/products');
  }

  Future<void> _loadProduct(String id) async {
    try {
      final product = await ProductService.fetchById(id);
      if (!mounted || product == null) return;
      setState(() {
        nameController.text = product.name;
        descriptionController.text = product.description;
        priceController.text = product.price.toString();
        stockController.text = product.stock.toString();
        imageUrls
          ..clear()
          ..addAll(product.imageUrls.isEmpty && product.imageUrl.isNotEmpty
              ? [product.imageUrl]
              : product.imageUrls);
        originalImageUrls = List<String>.from(imageUrls);
        selectedCategory = product.category;
        isActive = product.isActive;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không tải được sản phẩm: $error'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<void> _saveProduct() async {
    final name = nameController.text.trim();
    final price = int.tryParse(priceController.text.trim().replaceAll('.', ''));
    final stock = int.tryParse(stockController.text.trim()) ?? 0;
    if (name.isEmpty || price == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nhập tên sản phẩm và giá hợp lệ'), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    setState(() => isSaving = true);
    final id = editingId ?? _createProductId(name);
    try {
      var savedImageUrls = List<String>.from(imageUrls);
      if (pickedImages.isNotEmpty) {
        setState(() => isUploadingImage = true);
        final uploadedUrls = await AdminProductImageService.uploadProductImages(pickedImages, id);
        if (!mounted) return;
        savedImageUrls = [...savedImageUrls, ...uploadedUrls];
      }
      final primaryImageUrl = savedImageUrls.isEmpty ? '' : savedImageUrls.first;

      await ProductService.upsertProduct(
        id: id,
        name: name,
        price: price,
        category: selectedCategory,
        imageUrl: primaryImageUrl,
        imageUrls: savedImageUrls,
        description: descriptionController.text.trim(),
        stock: stock,
        isActive: isActive,
      );
      final removedUrls = originalImageUrls
          .where((url) => url.isNotEmpty && !savedImageUrls.contains(url))
          .toList();
      if (removedUrls.isNotEmpty) {
        await AdminProductImageService.deleteProductImagesByUrls(removedUrls);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(editingId == null ? 'Đã tạo sản phẩm' : 'Đã cập nhật sản phẩm'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pushReplacementNamed(context, '/admin/products');
    } catch (error) {
      if (!mounted) return;
      setState(() {
        isSaving = false;
        isUploadingImage = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không lưu được sản phẩm: $error'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<void> _pickImages() async {
    final images = await imagePicker.pickMultiImage(
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (images.isEmpty || !mounted) return;
    setState(() => pickedImages.addAll(images));
  }

  void _removeStoredImage(String imageUrl) {
    setState(() => imageUrls.remove(imageUrl));
  }

  void _removePickedImage(XFile image) {
    setState(() => pickedImages.remove(image));
  }
}

String _createProductId(String name) {
  final slug = name
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
      .trim()
      .replaceAll(RegExp(r'\s+'), '-');
  final suffix = DateTime.now().millisecondsSinceEpoch.toString().substring(7);
  return slug.isEmpty ? 'product-$suffix' : '$slug-$suffix';
}

class _ProductFormBreadcrumb extends StatelessWidget {
  final bool isEdit;

  const _ProductFormBreadcrumb({required this.isEdit});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        TextButton.icon(
          onPressed: () => Navigator.pushReplacementNamed(context, '/admin/products'),
          icon: const Icon(Icons.arrow_back, size: 18),
          label: const Text('Danh sách'),
          style: TextButton.styleFrom(foregroundColor: AppTheme.onSurfaceVariant),
        ),
        const Text('/', style: TextStyle(color: AppTheme.outlineVariant)),
        const SizedBox(width: 8),
        Text(
          isEdit ? 'Sửa sản phẩm' : 'Thêm sản phẩm',
          style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _PageHeader extends StatelessWidget {
  final bool isEdit;
  final String? productName;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  const _PageHeader({
    required this.isEdit,
    this.productName,
    required this.onCancel,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 720;
        final title = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEdit ? 'Sửa sản phẩm' : 'Thêm sản phẩm',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              isEdit
                  ? 'Cập nhật thông tin ${productName ?? 'sản phẩm'} trong cửa hàng.'
                  : 'Nhập thông tin chi tiết cho sản phẩm mới vào cửa hàng.',
              style: const TextStyle(color: AppTheme.secondary),
            ),
          ],
        );
        final actions = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton(
              onPressed: onCancel,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primary,
                side: const BorderSide(color: AppTheme.outlineVariant),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Hủy'),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: onSave,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: AppTheme.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(isEdit ? 'Cập nhật' : 'Lưu sản phẩm'),
            ),
          ],
        );
        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              title,
              const SizedBox(height: 16),
              Align(alignment: Alignment.centerRight, child: actions),
            ],
          );
        }
        return Row(children: [Expanded(child: title), actions]);
      },
    );
  }
}

class _FormCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _FormCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: AppTheme.onSurfaceVariant,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _PriceField extends StatelessWidget {
  final TextEditingController controller;

  const _PriceField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _FieldLabel('Giá bán (VNĐ) *'),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(prefixText: '₫ ', hintText: '0'),
        ),
      ],
    );
  }
}

class _StockField extends StatelessWidget {
  final TextEditingController controller;

  const _StockField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _FieldLabel('Số lượng tồn kho'),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: '0'),
        ),
      ],
    );
  }
}

class _ImageCard extends StatelessWidget {
  final List<String> imageUrls;
  final List<XFile> pickedImages;
  final bool isUploading;
  final VoidCallback onPickImages;
  final ValueChanged<String> onRemoveStoredImage;
  final ValueChanged<XFile> onRemovePickedImage;

  const _ImageCard({
    required this.imageUrls,
    required this.pickedImages,
    required this.isUploading,
    required this.onPickImages,
    required this.onRemoveStoredImage,
    required this.onRemovePickedImage,
  });

  @override
  Widget build(BuildContext context) {
    return _FormCard(
      title: 'Ảnh sản phẩm',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton.icon(
            onPressed: isUploading ? null : onPickImages,
            icon: isUploading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.upload_file),
            label: Text(isUploading ? 'Đang upload ảnh...' : 'Chọn nhiều ảnh sản phẩm'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 16),
          _ProductImagesGrid(
            imageUrls: imageUrls,
            pickedImages: pickedImages,
            onRemoveStoredImage: onRemoveStoredImage,
            onRemovePickedImage: onRemovePickedImage,
          ),
        ],
      ),
    );
  }
}

class _ProductImagesGrid extends StatelessWidget {
  final List<String> imageUrls;
  final List<XFile> pickedImages;
  final ValueChanged<String> onRemoveStoredImage;
  final ValueChanged<XFile> onRemovePickedImage;

  const _ProductImagesGrid({
    required this.imageUrls,
    required this.pickedImages,
    required this.onRemoveStoredImage,
    required this.onRemovePickedImage,
  });

  @override
  Widget build(BuildContext context) {
    final total = imageUrls.length + pickedImages.length;
    if (total == 0) {
      return const _ImagePlaceholder(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_outlined, color: AppTheme.onSurfaceVariant),
            SizedBox(height: 8),
            Text('Chưa chọn ảnh', style: TextStyle(color: AppTheme.onSurfaceVariant)),
          ],
        ),
      );
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 0.86,
      children: [
        for (var i = 0; i < imageUrls.length; i++)
          _ImageTile(
            badge: i == 0 ? 'Ảnh chính' : null,
            onRemove: () => onRemoveStoredImage(imageUrls[i]),
            child: _ProductImagePreview(imageUrl: imageUrls[i]),
          ),
        for (final image in pickedImages)
          _ImageTile(
            badge: imageUrls.isEmpty && image == pickedImages.first ? 'Ảnh chính' : 'Mới',
            onRemove: () => onRemovePickedImage(image),
            child: _ProductImagePreview(pickedImage: image),
          ),
      ],
    );
  }
}

class _ImageTile extends StatelessWidget {
  final Widget child;
  final String? badge;
  final VoidCallback onRemove;

  const _ImageTile({required this.child, required this.onRemove, this.badge});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: ClipRRect(borderRadius: BorderRadius.circular(10), child: child),
        ),
        if (badge != null)
          Positioned(
            left: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                badge!,
                style: const TextStyle(color: AppTheme.onPrimary, fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        Positioned(
          right: 6,
          top: 6,
          child: IconButton.filled(
            onPressed: onRemove,
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: AppTheme.onError,
              minimumSize: const Size(30, 30),
              fixedSize: const Size(30, 30),
              padding: EdgeInsets.zero,
            ),
            icon: const Icon(Icons.close, size: 16),
          ),
        ),
      ],
    );
  }
}

class _ProductImagePreview extends StatelessWidget {
  final XFile? pickedImage;
  final String? imageUrl;

  const _ProductImagePreview({this.pickedImage, this.imageUrl});

  @override
  Widget build(BuildContext context) {
    if (pickedImage != null) {
      return FutureBuilder<Uint8List>(
        future: pickedImage!.readAsBytes(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return _ImagePlaceholder(
              child: const CircularProgressIndicator(strokeWidth: 2),
            );
          }
          return Image.memory(
            snapshot.data!,
            height: 192,
            width: double.infinity,
            fit: BoxFit.cover,
          );
        },
      );
    }

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Image.network(
        imageUrl!,
        height: double.infinity,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const _ImagePlaceholder(
          child: Icon(Icons.image_not_supported_outlined),
        ),
      );
    }

    return const _ImagePlaceholder(child: Icon(Icons.image_outlined));
  }
}

class _ImagePlaceholder extends StatelessWidget {
  final Widget child;

  const _ImagePlaceholder({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 192,
      width: double.infinity,
      color: AppTheme.surfaceContainerLow,
      alignment: Alignment.center,
      child: child,
    );
  }
}

class _StatusCard extends StatelessWidget {
  final bool isActive;
  final ValueChanged<bool> onChanged;

  const _StatusCard({required this.isActive, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Trạng thái', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                SizedBox(height: 4),
                Text(
                  'Hiển thị trên cửa hàng',
                  style: TextStyle(color: AppTheme.secondary, fontSize: 12),
                ),
              ],
            ),
          ),
          Switch(
            value: isActive,
            activeThumbColor: AppTheme.primary,
            activeTrackColor: AppTheme.primaryContainer,
            onChanged: onChanged,
          ),
          const SizedBox(width: 6),
          const Text('Đang bán', style: TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String selected;
  final Future<List<String>> categoriesFuture;
  final ValueChanged<String> onSelected;

  const _CategoryCard({
    required this.selected,
    required this.categoriesFuture,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return _FormCard(
      title: 'Danh mục',
      child: FutureBuilder<List<String>>(
        future: categoriesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }
          final categories = snapshot.data ?? const <String>[];
          if (categories.isEmpty) {
            return const Text(
              'Chưa có danh mục. Hãy thêm dữ liệu trong bảng categories.',
              style: TextStyle(color: AppTheme.onSurfaceVariant),
            );
          }
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final category in categories)
                ChoiceChip(
                  label: Text(category),
                  selected: selected == category,
                  showCheckmark: false,
                  onSelected: (_) => onSelected(category),
                  selectedColor: AppTheme.primary,
                  backgroundColor: AppTheme.surfaceContainerLow,
                  labelStyle: TextStyle(
                    color: selected == category ? AppTheme.onPrimary : AppTheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                ),
            ],
          );
        },
      ),
    );
  }
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: AppTheme.surface,
    border: Border.all(color: AppTheme.surfaceContainerHigh),
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
