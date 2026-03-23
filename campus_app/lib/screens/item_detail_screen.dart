import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme.dart';
import 'chat_screen.dart';

class ItemDetailScreen extends StatelessWidget {
  const ItemDetailScreen({super.key});
  String _formatDate(String? dateStr) {
  if (dateStr == null || dateStr.isEmpty) return '';
  try {
    final date = DateTime.parse(dateStr).toLocal();
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  } catch (e) {
    return dateStr;
  }
}

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments
        as Map<String, dynamic>?;
    if (args == null) return const Scaffold();

    final item = args['item'] as Map<String, dynamic>;
    final isLost = args['is_lost'] as bool;
    final currentUserId = args['current_user_id'] as int;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
              // ── Header ──────────────────────────────────
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppTheme.darkSurface
                              : AppTheme.lightSurface,
                          borderRadius:
                              BorderRadius.circular(12),
                          border: Border.all(
                              color: AppTheme.gold
                                  .withOpacity(0.3)),
                        ),
                        child: const Icon(
                            Icons.arrow_back_ios_new,
                            color: AppTheme.gold,
                            size: 18),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      isLost ? 'Lost Item' : 'Found Item',
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
              ),

              const SizedBox(height: 16),

              // ── Content ──────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      // ── Image ──────────────────────────
                      if (item['image_url'] != null)
                        GestureDetector(
                          onTap: () => _showFullImage(
                              context, item['image_url']),
                          child: Container(
                            width: double.infinity,
                            height: 260,
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(20),
                              boxShadow:
                                  AppTheme.cardShadowDark,
                            ),
                            child: ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(20),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  CachedNetworkImage(
                                    imageUrl:
                                        item['image_url'],
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
                                          size: 48),
                                    ),
                                  ),
                                  // Zoom hint
                                  Positioned(
                                    bottom: 12,
                                    right: 12,
                                    child: Container(
                                      padding:
                                          const EdgeInsets
                                              .symmetric(
                                              horizontal: 10,
                                              vertical: 6),
                                      decoration:
                                          BoxDecoration(
                                        color: Colors.black
                                            .withOpacity(0.6),
                                        borderRadius:
                                            BorderRadius
                                                .circular(20),
                                      ),
                                      child: const Row(
                                        mainAxisSize:
                                            MainAxisSize.min,
                                        children: [
                                          Icon(Icons.zoom_in,
                                              color:
                                                  Colors.white,
                                              size: 14),
                                          SizedBox(width: 4),
                                          Text(
                                            'Tap to zoom',
                                            style: TextStyle(
                                              color:
                                                  Colors.white,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      else
                        Container(
                          width: double.infinity,
                          height: 200,
                          decoration: BoxDecoration(
                            color: AppTheme.gold
                                .withOpacity(0.1),
                            borderRadius:
                                BorderRadius.circular(20),
                            border: Border.all(
                                color: AppTheme.gold
                                    .withOpacity(0.3)),
                          ),
                          child: const Center(
                            child: Icon(
                                Icons.inventory_2_outlined,
                                color: AppTheme.gold,
                                size: 64),
                          ),
                        ),

                      const SizedBox(height: 24),

                      // ── Status badge ───────────────────
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
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
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isLost
                                ? AppTheme.stillMissing
                                : AppTheme.foundMatch,
                            letterSpacing: 1,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ── Item name ──────────────────────
                      Text(
                        item['item_name'] ?? '',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : Colors.black87,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── Details card ───────────────────
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: isDark
                              ? AppTheme.cardGradientDark
                              : AppTheme.cardGradientLight,
                          borderRadius:
                              BorderRadius.circular(16),
                          boxShadow: isDark
                              ? AppTheme.cardShadowDark
                              : AppTheme.cardShadowLight,
                          border: Border.all(
                            color: AppTheme.gold
                                .withOpacity(0.15),
                            width: 0.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            _buildDetailRow(
                              icon: Icons.location_on_outlined,
                              label: isLost
                                  ? 'Lost at'
                                  : 'Found at',
                              value: isLost
                                  ? (item['location_lost'] ??
                                      'Unknown')
                                  : (item['location_found'] ??
                                      'Unknown'),
                              isDark: isDark,
                            ),
                            _buildDivider(isDark),
                            _buildDetailRow(
                              icon: Icons.calendar_today_outlined,
                              label: isLost ? 'Date lost' : 'Date found',
                              value: _formatDate(isLost
                                  ? item['date_lost']?.toString()
                                  : item['date_found']?.toString()),
                              isDark: isDark,
                            ),
                            if (item['description'] != null &&
                                item['description']
                                    .toString()
                                    .isNotEmpty) ...[
                              _buildDivider(isDark),
                              _buildDetailRow(
                                icon: Icons.description_outlined,
                                label: 'Description',
                                value: item['description'],
                                isDark: isDark,
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── Message button (found items only) ──
                      if (!isLost &&
                          item['user_id'] != currentUserId)
                        GoldButton(
                          text: 'Message the Finder',
                          onPressed: () {
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
                        ),

                      const SizedBox(height: 30),
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

  void _showFullImage(BuildContext context, String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              // Zoomable image
              Center(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 5.0,
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(
                          color: AppTheme.gold),
                    ),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.broken_image,
                            color: Colors.white, size: 64),
                  ),
                ),
              ),
              // Close button
              Positioned(
                top: 50,
                left: 20,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close,
                        color: Colors.white, size: 24),
                  ),
                ),
              ),
              // Zoom hint
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Pinch to zoom',
                      style: TextStyle(
                          color: Colors.white, fontSize: 13),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.gold, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? Colors.white38
                        : Colors.black38,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    color: isDark
                        ? Colors.white
                        : Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      color: isDark ? Colors.white10 : Colors.black12,
      height: 16,
    );
  }
}