import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _query = '';

  static const _items = [
    ('ast-01', 'Canon M50 Camera', '120', '1500'),
    ('ast-02', 'Portable Projector', '250', '1000'),
    ('ast-03', 'Scientific Calculator', '30', '200'),
    ('ast-04', 'Lab Coat Size M', '50', '300'),
  ];

  @override
  Widget build(BuildContext context) {
    final visibleItems = _items
        .where((item) => item.$2.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hello, Somchai'),
                      SizedBox(height: 4),
                      Text(
                        'What would you like to borrow?',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Wallet',
                        onPressed: () =>
                            Navigator.pushNamed(context, '/wallet'),
                        icon: const Icon(Icons.account_balance_wallet_outlined),
                      ),
                      IconButton(
                        tooltip: 'Log out',
                        onPressed: () => Navigator.of(context)
                            .pushNamedAndRemoveUntil('/login', (_) => false),
                        icon: const Icon(Icons.logout),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (value) => setState(() => _query = value),
                      decoration: const InputDecoration(
                        hintText: 'Search items',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: 'Add item',
                    onPressed: () => Navigator.pushNamed(context, '/add-item'),
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => Navigator.pushNamed(context, '/borrow-details'),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF9C4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Color(0xFF856404),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Portable Projector - Return by 3 Nov 2026',
                          style: TextStyle(color: Color(0xFF856404)),
                        ),
                      ),
                      Icon(Icons.chevron_right, color: Color(0xFF856404)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Items available to borrow',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: visibleItems.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.78,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemBuilder: (context, index) {
                  final item = visibleItems[index];
                  return Card(
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => Navigator.pushNamed(
                        context,
                        '/item-detail',
                        arguments: item.$1,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Expanded(
                            child: SizedBox(
                              width: double.infinity,
                              child: ColoredBox(
                                color: Color(0xFFE8ECF4),
                                child: Icon(Icons.image, size: 40),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.$2,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text('฿${item.$3} / day'),
                                Text('Deposit ฿${item.$4}'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
