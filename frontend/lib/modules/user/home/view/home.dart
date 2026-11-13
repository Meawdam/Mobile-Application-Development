import 'package:flutter/material.dart';

import 'package:frontend/model/asset/asset_model.dart';
import 'package:frontend/modules/user/home/controller/home_controller.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HomeController _controller = HomeController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerUpdate);
    _controller.initialize();
  }

  void _onControllerUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    await _controller.logout();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
  }

  Future<void> _addItem() async {
    await Navigator.pushNamed(context, '/add-item');
    await _controller.loadItems();
  }

  void _openItem(AssetModel asset) {
    Navigator.pushNamed(
      context,
      '/item-detail',
      arguments: asset.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    final greetingName = _controller.user?.username;
    final items = _controller.items;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _controller.loadItems(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          greetingName == null || greetingName.isEmpty
                              ? 'Hello'
                              : 'Hello, $greetingName',
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'What would you like to borrow?',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
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
                        onPressed: _logout,
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
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      onSubmitted: _controller.search,
                      decoration: const InputDecoration(
                        hintText: 'Search items',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: 'Search',
                    onPressed: () =>
                        _controller.search(_searchController.text),
                    icon: const Icon(Icons.search),
                  ),
                  const SizedBox(width: 4),
                  IconButton.filled(
                    tooltip: 'Add item',
                    onPressed: _addItem,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Items available to borrow',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              if (_controller.loading && items.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_controller.error != null && items.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Text(
                        _controller.error!,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () => _controller.loadItems(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              else if (items.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: Text('No items to display')),
                )
              else
                ...items.map(
                  (asset) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _AssetCard(
                      asset: asset,
                      onTap: () => _openItem(asset),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AssetCard extends StatelessWidget {
  final AssetModel asset;
  final VoidCallback onTap;

  const _AssetCard({required this.asset, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 84,
                  height: 84,
                  child: asset.imageUrl.isEmpty
                      ? const ColoredBox(
                          color: Color(0xFFE8ECF4),
                          child: Icon(Icons.image, size: 32),
                        )
                      : Image.network(
                          asset.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const ColoredBox(
                            color: Color(0xFFE8ECF4),
                            child: Icon(Icons.broken_image_outlined),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      asset.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      asset.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${asset.price} Baht / day',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
