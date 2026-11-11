import 'package:flutter/material.dart';

import 'modules/admin/admin_home.dart';
import 'modules/auth/login/view/login.dart';
import 'modules/auth/register/view/register.dart';
import 'modules/user/add_item/view/add_item.dart';
import 'modules/user/borrow_details/view/borrow_details.dart';
import 'modules/user/borrow_request/view/borrow_request.dart';
import 'modules/user/edit_item/view/edit_item.dart';
import 'modules/user/home/view/home.dart';
import 'modules/user/item_detail/view/item_detail.dart';
import 'modules/user/my_borrowed_items/view/my_borrowed_items.dart';
import 'modules/user/my_lending_items/view/my_lending_items.dart';
import 'modules/user/payment/view/payment.dart';
import 'modules/user/requests_returns/view/requests_returns.dart';
import 'modules/user/wallet/view/wallet.dart';

Route<dynamic> onGenerateAppRoute(RouteSettings settings) {
  final Widget page;
  switch (settings.name) {
    case '/login':
      page = const LoginScreen();
    case '/register':
      page = const RegisterScreen();
    case '/home':
      page = const _UserNavigationShell();
    case '/my-borrowed':
      page = const _UserNavigationShell(initialIndex: 1);
    case '/my-lending':
      page = const _UserNavigationShell(initialIndex: 2);
    case '/item-detail':
      page = ItemDetailScreen(
        itemId: settings.arguments as String? ?? 'ast-01',
      );
    case '/borrow-request':
      page = BorrowRequestScreen(
        itemId: settings.arguments as String? ?? 'ast-01',
      );
    case '/payment':
      page = const PaymentScreen();
    case '/borrow-details':
      page = BorrowDetailsScreen(
        recordId: settings.arguments as String? ?? 'BR-69-0142',
      );
    case '/add-item':
      page = const AddItemScreen();
    case '/wallet':
      page = const WalletScreen();
    case '/edit-item':
      page = EditItemScreen(itemId: settings.arguments as String? ?? '');
    case '/requests-returns':
      page = const RequestsReturnsScreen();
    case '/admin':
      page = const AdminHome();
    default:
      page = const Scaffold(body: Center(child: Text('Page not found')));
  }

  return MaterialPageRoute<void>(
    settings: settings,
    builder: (_) => _mobileWrapper(page),
  );
}

Widget _mobileWrapper(Widget child) {
  return Scaffold(
    backgroundColor: const Color(0xFF1F2937),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: child,
      ),
    ),
  );
}

class _UserNavigationShell extends StatefulWidget {
  final int initialIndex;

  const _UserNavigationShell({this.initialIndex = 0});

  @override
  State<_UserNavigationShell> createState() => _UserNavigationShellState();
}

class _UserNavigationShellState extends State<_UserNavigationShell> {
  late int _index = widget.initialIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          HomeScreen(),
          MyBorrowedItemsScreen(),
          MyLendingItemsScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (index) => setState(() => _index = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Borrowing',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2),
            label: 'Lending',
          ),
        ],
      ),
    );
  }
}
