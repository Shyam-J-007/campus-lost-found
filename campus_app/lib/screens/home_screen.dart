import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../main.dart';
import 'chat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> _items = [];
  List<dynamic> _matches = [];
  bool _isLoading = true;
  bool _showLost = true;
  String _userName = 'Student';
  int _userId = 0;
  int _unreadMessages = 0;
  final _searchController = TextEditingController();

  final List<Map<String, dynamic>> _suggestions = [
    {
      'label': 'Purse',
      'image': 'https://images.unsplash.com/photo-1548036328-c9fa89d128fa?w=200&q=80',
      'related': ['Money', 'ID Card', 'Keys', 'PAN Card'],
    },
    {
      'label': 'Phone',
      'image': 'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=200&q=80',
      'related': ['Charger', 'Earphones', 'Phone Case'],
    },
    {
      'label': 'Money',
      'image': 'https://images.unsplash.com/photo-1580048915913-4f8f5cb481c4?w=200&q=80',
      'related': ['Purse', 'Wallet', 'ID Card'],
    },
    {
      'label': 'ID Card',
      'image': 'https://images.unsplash.com/photo-1602778870521-e0f85c7b4e1e?w=200&q=80',
      'related': ['Purse', 'PAN Card', 'Licence'],
    },
    {
      'label': 'Keys',
      'image': 'https://images.unsplash.com/photo-1514316454349-750a7fd3da3a?w=200&q=80',
      'related': ['Keychain', 'Bag', 'Purse'],
    },
    {
      'label': 'Bottle',
      'image': 'https://images.unsplash.com/photo-1602143407151-7111542de6e8?w=200&q=80',
      'related': ['Bag', 'Tiffin Box'],
    },
    {
      'label': 'Bag',
      'image': 'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=200&q=80',
      'related': ['Books', 'Laptop', 'Charger', 'Keys'],
    },
    {
      'label': 'Watch',
      'image': 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=200&q=80',
      'related': ['Bracelet', 'Purse'],
    },
    {
      'label': 'Earphones',
      'image': 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=200&q=80',
      'related': ['Phone', 'Charger', 'Bag'],
    },
    {
      'label': 'Calculator',
      'image': 'https://images.unsplash.com/photo-1587145820266-a5951ee6f620?w=200&q=80',
      'related': ['Books', 'Pen', 'Bag'],
    },
    {
      'label': 'Laptop',
      'image': 'https://images.unsplash.com/photo-1496181133206-80ce9b88a853?w=200&q=80',
      'related': ['Charger', 'Bag', 'Mouse', 'Earphones'],
    },
    {
      'label': 'Umbrella',
      'image': 'https://images.unsplash.com/photo-1549317336-206569e8475c?w=200&q=80',
      'related': ['Bag', 'Keys'],
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? 'Student';
      _userId = prefs.getInt('user_id') ?? 0;
    });
    await _loadItems();
    await _checkMatches();
    await _checkUnread();
  }

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);
    final items = await ApiService.searchItems(
      '',
      type: _showLost ? 'lost' : 'found',
    );
    setState(() {
      _items = items;
      _isLoading = false;
    });
  }

  Future<void> _checkMatches() async {
    if (_userId == 0) return;
    final matches = await ApiService.checkMatches(_userId);
    if (matches.isNotEmpty) {
      setState(() => _matches = matches);
      _showMatchNotification();
    }
  }

  Future<void> _checkUnread() async {
    if (_userId == 0) return;
    final count = await ApiService.getUnreadCount(_userId);
    setState(() => _unreadMessages = count);
  }

  Future<void> _logout() async {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor:
            isDark ? AppTheme.darkCard : AppTheme.lightCard,
        title: Text(
          'Log out?',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to log out?',
          style: TextStyle(
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color:
                    isDark ? Colors.white54 : Colors.black45,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.pop(context, true),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                gradient: AppTheme.goldGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppTheme.goldGlowSoft,
              ),
              child: const Text(
                'Log out',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  void _showMatchNotification() {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor:
          isDark ? AppTheme.darkCard : AppTheme.lightCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white24
                            : Colors.black12,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Icon(Icons.notifications_active,
                          color: AppTheme.gold, size: 24),
                      const SizedBox(width: 10),
                      Text(
                        'Possible matches found!',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ..._matches.map((match) => Container(
                        margin:
                            const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.gold.withOpacity(0.1),
                          borderRadius:
                              BorderRadius.circular(12),
                          border: Border.all(
                              color: AppTheme.gold
                                  .withOpacity(0.3),
                              width: 0.5),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                                Icons.check_circle_outline,
                                color: AppTheme.gold,
                                size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                match['message'] ?? '',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                  const SizedBox(height: 12),
                  ..._matches.map((match) => Padding(
                        padding:
                            const EdgeInsets.only(bottom: 8),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const ChatScreen(),
                                settings: RouteSettings(
                                  arguments: {
                                    'other_user_id': match[
                                            'finder_user_id'] ??
                                        0,
                                    'other_name':
                                        match['finder_name'] ??
                                            'Finder',
                                    'item_name':
                                        match['lost_item'] ??
                                            '',
                                  },
                                ),
                              ),
                            );
                          },
                          child: Container(
                            width: double.infinity,
                            height: 48,
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(30),
                              border: Border.all(
                                  color: AppTheme.gold,
                                  width: 1.5),
                              color: AppTheme.gold
                                  .withOpacity(0.05),
                            ),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                const Icon(
                                    Icons.message_outlined,
                                    color: AppTheme.gold,
                                    size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'Message finder of ${match['lost_item']}',
                                  style: const TextStyle(
                                    color: AppTheme.gold,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )),
                  const SizedBox(height: 8),
                  GoldButton(
                    text: 'Got it!',
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _search(String query) async {
    setState(() => _isLoading = true);
    final items = await ApiService.searchItems(
      query,
      type: _showLost ? 'lost' : 'found',
    );
    setState(() {
      _items = items;
      _isLoading = false;
    });
  }

  void _onSuggestionTap(Map<String, dynamic> suggestion) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;
    final related = suggestion['related'] as List<String>;

    showModalBottomSheet(
      context: context,
      backgroundColor:
          isDark ? AppTheme.darkCard : AppTheme.lightCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white24
                            : Colors.black12,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? Colors.white
                            : Colors.black87,
                      ),
                      children: [
                        const TextSpan(text: 'Lost your '),
                        TextSpan(
                          text: suggestion['label'] as String,
                          style: const TextStyle(
                              color: AppTheme.gold),
                        ),
                        const TextSpan(text: '?'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Also check if you lost these related items:',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? Colors.white54
                          : Colors.black45,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: related.map((item) {
                      return GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(
                                  context, '/report',
                                  arguments: item)
                              .then((_) => _loadItems());
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color:
                                AppTheme.gold.withOpacity(0.15),
                            borderRadius:
                                BorderRadius.circular(20),
                            border: Border.all(
                                color: AppTheme.gold
                                    .withOpacity(0.4),
                                width: 0.5),
                          ),
                          child: Text(
                            item,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.gold,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  GoldButton(
                    text:
                        'Report ${suggestion['label']} as Lost',
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/report',
                              arguments:
                                  suggestion['label'] as String)
                          .then((_) => _loadItems());
                    },
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _searchController.text =
                          suggestion['label'] as String;
                      _search(suggestion['label'] as String);
                    },
                    child: Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                            color: AppTheme.gold, width: 1.5),
                        color: AppTheme.gold.withOpacity(0.05),
                      ),
                      child: Center(
                        child: Text(
                          'Search reports for ${suggestion['label']}',
                          style: const TextStyle(
                            color: AppTheme.gold,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? AppTheme.darkBgGradient
              : AppTheme.lightBgGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Header ────────────────────────────────
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: AppTheme.gold,
                      child: Text(
                        _userName.isNotEmpty
                            ? _userName[0].toUpperCase()
                            : 'S',
                        style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 18),
                      ),
                    ),
                    const SizedBox(width: 12),
                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : Colors.black87,
                        ),
                        children: [
                          const TextSpan(text: 'Hello, '),
                          TextSpan(
                            text: '$_userName!',
                            style: const TextStyle(
                                color: AppTheme.gold),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                          isDark
                              ? Icons.light_mode
                              : Icons.dark_mode,
                          color: AppTheme.gold),
                      onPressed: () =>
                          MyApp.of(context)?.toggleTheme(),
                    ),
                    // Chat icon with badge
                    Stack(
                      children: [
                        IconButton(
                          icon: const Icon(
                              Icons.chat_bubble_outline),
                          color: AppTheme.gold,
                          onPressed: () => Navigator.pushNamed(
                                  context, '/conversations')
                              .then((_) => _checkUnread()),
                        ),
                        if (_unreadMessages > 0)
                          Positioned(
                            right: 6,
                            top: 6,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '$_unreadMessages',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    // Notification bell
                    Stack(
                      children: [
                        IconButton(
                          icon: const Icon(
                              Icons.notifications_outlined),
                          color: AppTheme.gold,
                          onPressed: _matches.isEmpty
                              ? null
                              : _showMatchNotification,
                        ),
                        if (_matches.isNotEmpty)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Search bar ────────────────────────────
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _searchController,
                  onChanged: _search,
                  style: TextStyle(
                      color:
                          isDark ? Colors.white : Colors.black87),
                  decoration: InputDecoration(
                    hintText: 'Search all campus items...',
                    hintStyle: TextStyle(
                        color: isDark
                            ? Colors.white38
                            : Colors.black38,
                        fontSize: 14),
                    prefixIcon: Icon(Icons.search,
                        color: isDark
                            ? Colors.white38
                            : Colors.black38),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 14),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ── Scrollable content ────────────────────
              Expanded(
                child: RefreshIndicator(
                  color: AppTheme.gold,
                  onRefresh: _loadItems,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20),
                    children: [
                      // Quick suggestions
                      Text(
                        'Quick report',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? Colors.white70
                              : Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 110,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _suggestions.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final s = _suggestions[index];
                            return GestureDetector(
                              onTap: () =>
                                  _onSuggestionTap(s),
                              child: Column(
                                children: [
                                  Container(
                                    width: 70,
                                    height: 70,
                                    decoration: BoxDecoration(
                                      borderRadius:
                                          BorderRadius.circular(
                                              16),
                                      border: Border.all(
                                        color: AppTheme.gold
                                            .withOpacity(0.3),
                                        width: 0.5,
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius:
                                          BorderRadius.circular(
                                              16),
                                      child: CachedNetworkImage(
                                        imageUrl: s['image']
                                            as String,
                                        fit: BoxFit.cover,
                                        placeholder:
                                            (context, url) =>
                                                Container(
                                          color: isDark
                                              ? AppTheme
                                                  .darkSurface
                                              : AppTheme
                                                  .lightSurface,
                                          child: const Center(
                                            child:
                                                CircularProgressIndicator(
                                              color:
                                                  AppTheme.gold,
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        ),
                                        errorWidget: (context,
                                                url, error) =>
                                            Container(
                                          color: isDark
                                              ? AppTheme
                                                  .darkSurface
                                              : AppTheme
                                                  .lightSurface,
                                          child: const Icon(
                                              Icons
                                                  .image_not_supported,
                                              color:
                                                  AppTheme.gold,
                                              size: 28),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    s['label'] as String,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? Colors.white70
                                          : Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Lost / Found toggle
                      Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppTheme.darkSurface
                              : AppTheme.lightSurface,
                          borderRadius:
                              BorderRadius.circular(30),
                        ),
                        child: Row(
                          children: [
                            _toggleButton('Lost Items',
                                _showLost, () async {
                              _showLost = true;
                              setState(() {});
                              await _loadItems();
                            }),
                            _toggleButton('Found Items',
                                !_showLost, () async {
                              _showLost = false;
                              setState(() {});
                              await _loadItems();
                            }),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Items list
                      if (_isLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(40),
                            child: CircularProgressIndicator(
                                color: AppTheme.gold),
                          ),
                        )
                      else if (_items.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(40),
                            child: Text(
                              _showLost
                                  ? 'No lost items reported yet.'
                                  : 'No found items reported yet.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white38
                                    : Colors.black38,
                                height: 1.6,
                              ),
                            ),
                          ),
                        )
                      else
                        ...(_items.map((item) => Padding(
                              padding: const EdgeInsets.only(
                                  bottom: 12),
                              child: _ItemCard(
                                item: item,
                                isDark: isDark,
                                isLost: _showLost,
                                currentUserId: _userId,
                                onRefresh: _loadItems,
                              ),
                            ))),

                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      // ── FABs ──────────────────────────────────────────
      floatingActionButtonLocation:
          FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Logout
            GestureDetector(
              onTap: _logout,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppTheme.darkCard
                      : AppTheme.lightCard,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: AppTheme.gold.withOpacity(0.5)),
                  boxShadow: AppTheme.cardShadowDark,
                ),
                child: const Icon(Icons.logout,
                    color: AppTheme.gold, size: 20),
              ),
            ),
            const SizedBox(height: 12),
            // Report Item
            GestureDetector(
              onTap: () =>
                  Navigator.pushNamed(context, '/report').then((_) {
                _loadItems();
                _checkMatches();
              }),
              child: Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  gradient: AppTheme.goldGradient,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: AppTheme.goldGlowSoft,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, color: Colors.black, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Report Item',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _toggleButton(
      String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? AppTheme.gold : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: active ? Colors.black : Colors.grey,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Item Card ─────────────────────────────────────────────────
class _ItemCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool isDark;
  final bool isLost;
  final int currentUserId;
  final VoidCallback onRefresh;

  const _ItemCard({
    required this.item,
    required this.isDark,
    required this.isLost,
    required this.currentUserId,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final isOwner = item['user_id'] == currentUserId;

    return Container(
      decoration: BoxDecoration(
        gradient: isDark
            ? AppTheme.cardGradientDark
            : AppTheme.cardGradientLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow:
            isDark ? AppTheme.cardShadowDark : AppTheme.cardShadowLight,
        border: Border.all(
          color: isDark
              ? AppTheme.gold.withOpacity(0.1)
              : AppTheme.gold.withOpacity(0.2),
          width: 0.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Image or icon
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: AppTheme.gold.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: item['image_url'] != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: item['image_url'],
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(
                              color: AppTheme.gold,
                              strokeWidth: 2),
                        ),
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.inventory_2_outlined,
                                color: AppTheme.gold, size: 28),
                      ),
                    )
                  : const Icon(Icons.inventory_2_outlined,
                      color: AppTheme.gold, size: 28),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['item_name'] ?? '',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color:
                          isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    isLost
                        ? (item['location_lost'] ?? '')
                        : (item['location_found'] ?? ''),
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? Colors.white54
                          : Colors.black45,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    isLost
                        ? (item['date_lost'] ?? '')
                        : (item['date_found'] ?? ''),
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? Colors.white38
                          : Colors.black38,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: isLost
                              ? AppTheme.stillMissing
                                  .withOpacity(0.15)
                              : AppTheme.foundMatch
                                  .withOpacity(0.15),
                          borderRadius:
                              BorderRadius.circular(20),
                          border: Border.all(
                            color: isLost
                                ? AppTheme.stillMissing
                                : AppTheme.foundMatch,
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          isLost ? 'STILL MISSING' : 'FOUND',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isLost
                                ? AppTheme.stillMissing
                                : AppTheme.foundMatch,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),

                      // Message button on found items
                      if (!isLost)
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const ChatScreen(),
                                settings: RouteSettings(
                                  arguments: {
                                    'other_user_id':
                                        item['user_id'] ?? 0,
                                    'other_name':
                                        item['finder_name'] ??
                                            'Finder',
                                    'item_name':
                                        item['item_name'] ?? '',
                                  },
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.gold
                                  .withOpacity(0.15),
                              borderRadius:
                                  BorderRadius.circular(20),
                              border: Border.all(
                                color: AppTheme.gold
                                    .withOpacity(0.5),
                                width: 0.5,
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.message_outlined,
                                    color: AppTheme.gold,
                                    size: 12),
                                SizedBox(width: 4),
                                Text(
                                  'MESSAGE',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.gold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Got it back button
                      if (isLost && isOwner)
                        GestureDetector(
                          onTap: () async {
                            final confirm =
                                await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor: isDark
                                    ? AppTheme.darkCard
                                    : AppTheme.lightCard,
                                title: Text(
                                  'Got it back?',
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                content: Text(
                                  'This will remove "${item['item_name']}" from both lost and found lists.',
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.black54,
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(
                                            context, false),
                                    child: Text(
                                      'Cancel',
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white54
                                            : Colors.black45,
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () =>
                                        Navigator.pop(
                                            context, true),
                                    child: Container(
                                      padding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 20,
                                              vertical: 10),
                                      decoration: BoxDecoration(
                                        gradient:
                                            AppTheme.goldGradient,
                                        borderRadius:
                                            BorderRadius.circular(
                                                20),
                                        boxShadow: AppTheme
                                            .goldGlowSoft,
                                      ),
                                      child: const Text(
                                        'Yes, got it!',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontWeight:
                                              FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              final result =
                                  await ApiService.recoverItem(
                                userId: currentUserId,
                                itemName: item['item_name'],
                              );
                              if (result
                                  .containsKey('message')) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Item marked as recovered!'),
                                    backgroundColor:
                                        AppTheme.gold,
                                  ),
                                );
                                onRefresh();
                              }
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.foundMatch
                                  .withOpacity(0.15),
                              borderRadius:
                                  BorderRadius.circular(20),
                              border: Border.all(
                                color: AppTheme.foundMatch
                                    .withOpacity(0.5),
                                width: 0.5,
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                    Icons.check_circle_outline,
                                    color: AppTheme.foundMatch,
                                    size: 12),
                                SizedBox(width: 4),
                                Text(
                                  'GOT IT BACK!',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.foundMatch,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}