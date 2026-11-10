
import 'package:flutter/foundation.dart';
import 'package:frontend/modules/admin/medels/approve_item_model.dart';

class ApproveItemsController extends ChangeNotifier {
  final List<ApproveItem> _items = [
    const ApproveItem(
      id: 'item1',
      name: 'Casio fx-991EX Calculator',
      owner: 'Somchai J.',
      time: '30 Oct. 11:10',
      category: 'Calculator',
      description: 'Scientific calculator for university study.',
    ),
    const ApproveItem(
      id: 'item2',
      name: 'Lab Coat Size M',
      owner: 'Suphaporn K.',
      time: '29 Oct. 16:08',
      category: 'Clothing',
      description: 'White laboratory coat, size M.',
    ),
    const ApproveItem(
      id: 'item3',
      name: 'Calculus Textbook Vol. 1',
      owner: 'Nattapat P.',
      time: '28 Oct. 09:30',
      category: 'Book',
      description: 'Calculus textbook in good condition.',
    ),
  ];

  List<ApproveItem> get items => List.unmodifiable(_items);

  int get pendingCount => _items.length;

  // Approve an item
  bool approveItem(String id) {
    final index = _items.indexWhere((item) => item.id == id);

    if (index == -1) return false;

    _items.removeAt(index);
    notifyListeners();
    return true;
  }

  // Reject an item with a required reason
  bool rejectItem(String id, String reason) {
    if (reason.trim().isEmpty) return false;

    final index = _items.indexWhere((item) => item.id == id);

    if (index == -1) return false;

    _items.removeAt(index);
    notifyListeners();
    return true;
  }
}
