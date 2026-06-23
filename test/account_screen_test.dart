import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_shop_app/models/customer_profile.dart';
import 'package:mobile_shop_app/screens/account_screen.dart';
import 'package:mobile_shop_app/screens/edit_profile_screen.dart';

void main() {
  testWidgets('opens account profile editor without framework errors', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: _AccountHost()));

    await tester.tap(find.text('Thông tin tài khoản'));
    await tester.pumpAndSettle();

    expect(find.text('Chỉnh sửa thông tin'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _AccountHost extends StatefulWidget {
  const _AccountHost();

  @override
  State<_AccountHost> createState() => _AccountHostState();
}

class _AccountHostState extends State<_AccountHost> {
  bool editing = false;
  final profile = const CustomerProfile(
    name: 'Nguyễn Thu Thảo',
    phoneNumber: '0901234567',
  );

  @override
  Widget build(BuildContext context) {
    if (editing) {
      return EditProfileScreen(
        profile: profile,
        onProfileChanged: (_) {},
        onBack: () => setState(() => editing = false),
      );
    }
    return AccountScreen(
      profile: profile,
      onProfileChanged: (_) {},
      onViewOrders: () {},
      onEditProfile: () => setState(() => editing = true),
      onManageAddresses: () {},
    );
  }
}
