import 'package:flutter/material.dart';

import 'package:frontend/model/asset/asset_model.dart';
import 'package:frontend/modules/user/home/controller/home_controller.dart';
import 'package:frontend/modules/user/home/service/home_api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.apiService});

  final HomeApiService? apiService;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final HomeApiService _apiService = widget.apiService ?? HomeApiService();
  late final HomeController _controller = HomeController(
    apiService: _apiService,
  );
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerUpdate);
    _controller.initialize();
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    if (widget.apiService == null) _apiService.dispose();
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

  void _search() {
    _controller.search(_searchController.text);
  }

  void _openItem(AssetModel asset) {
    Navigator.pushNamed(context, '/item-detail', arguments: asset.id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final greetingName = _controller.user?.username;
    final items = _controller.items;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _controller.loadItems(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6ECFF),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.swap_horiz_rounded,
                      color: Color(0xFF3156D8),
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'BORROW',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.6,
                      color: const Color(0xFF263B91),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Wallet',
                    onPressed: () => Navigator.pushNamed(context, '/wallet'),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF263B91),
                    ),
                    icon: const Icon(Icons.account_balance_wallet_outlined),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    tooltip: 'Log out',
                    onPressed: _logout,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF667085),
                    ),
                    icon: const Icon(Icons.logout_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              Text(
                greetingName == null || greetingName.isEmpty
                    ? 'Hello there 👋'
                    : 'Hello, $greetingName 👋',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFF667085),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Find what you need.',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: const Color(0xFF17233C),
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Borrow useful things from your community.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF718096),
                ),
              ),
              const SizedBox(height: 22),
              _WalletShortcut(
                onTap: () => Navigator.pushNamed(context, '/wallet'),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _search(),
                      decoration: InputDecoration(
                        hintText: 'Search items',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _searchController.text.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Clear search',
                                onPressed: () {
                                  _searchController.clear();
                                  _search();
                                },
                                icon: const Icon(Icons.close_rounded),
                              ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(
                            color: Color(0xFFE4E8F0),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(
                            color: Color(0xFFE4E8F0),
                          ),
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 52,
                    width: 52,
                    child: FilledButton(
                      onPressed: _controller.loading ? null : _search,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF3156D8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      child: const Icon(Icons.search_rounded),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Available to borrow',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF17233C),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${items.length} ${items.length == 1 ? 'item' : 'items'} available',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF718096),
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _addItem,
                    icon: const Icon(Icons.add_rounded, size: 19),
                    label: const Text('List an item'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF3156D8),
                    ),
                  ),
                ],
              ),
              if (_controller.error != null && items.isNotEmpty) ...[
                const SizedBox(height: 12),
                _HomeError(
                  message: _controller.error!,
                  onRetry: () => _controller.loadItems(),
                ),
              ],
              const SizedBox(height: 14),
              if (_controller.loading && items.isEmpty)
                const _LoadingItems()
              else if (_controller.error != null && items.isEmpty)
                _EmptyState(
                  icon: Icons.cloud_off_outlined,
                  title: 'Could not load items',
                  message: _controller.error!,
                  actionLabel: 'Try again',
                  onAction: () => _controller.loadItems(),
                )
              else if (items.isEmpty)
                _EmptyState(
                  icon: Icons.search_off_rounded,
                  title: _controller.query.isEmpty
                      ? 'Nothing to borrow yet'
                      : 'No matches found',
                  message: _controller.query.isEmpty
                      ? 'Check back soon or list something for your community.'
                      : 'Try a different search or clear your filters.',
                  actionLabel: _controller.query.isEmpty
                      ? 'List an item'
                      : 'Clear search',
                  onAction: _controller.query.isEmpty
                      ? _addItem
                      : () {
                          _searchController.clear();
                          _search();
                        },
                )
              else
                ...items.map(
                  (asset) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
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

class _WalletShortcut extends StatelessWidget {
  const _WalletShortcut({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF263B91),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your wallet',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Manage your balance and add money',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_rounded, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingItems extends StatelessWidget {
  const _LoadingItems();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 56),
      child: Center(
        child: Column(
          children: [
            CircularProgressIndicator(color: Color(0xFF3156D8)),
            SizedBox(height: 14),
            Text('Finding items for you...'),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4E8F0)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 42, color: const Color(0xFF8A97AE)),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF17233C),
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF718096), height: 1.4),
          ),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    );
  }
}

class _HomeError extends StatelessWidget {
  const _HomeError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFB42318)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Color(0xFF912018)),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _AssetCard extends StatelessWidget {
  const _AssetCard({required this.asset, required this.onTap});

  final AssetModel asset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final owner = asset.ownerUsername;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE7EAF1)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: SizedBox(
                  width: 92,
                  height: 100,
                  child: asset.imageUrl.isEmpty
                      ? const _ImagePlaceholder()
                      : Image.network(
                          asset.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const _ImagePlaceholder(),
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: SizedBox(
                  height: 100,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              asset.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF17233C),
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: Color(0xFF98A2B3),
                          ),
                        ],
                      ),
                      if (asset.description.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Text(
                          asset.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF667085),
                            fontSize: 12,
                            height: 1.3,
                          ),
                        ),
                      ],
                      const Spacer(),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              owner == null || owner.isEmpty
                                  ? 'Community item'
                                  : 'By $owner',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF718096),
                                fontSize: 11,
                              ),
                            ),
                          ),
                          Text(
                            '฿${asset.price}/day',
                            style: const TextStyle(
                              color: Color(0xFF3156D8),
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
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

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFFE9EDFA),
      child: Center(
        child: Icon(Icons.image_outlined, size: 32, color: Color(0xFF8190B2)),
      ),
    );
  }
}
