import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../theme.dart';
import 'chat_screen.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() =>
      _ConversationsScreenState();
}

class _ConversationsScreenState
    extends State<ConversationsScreen> {
  List<dynamic> _conversations = [];
  bool _isLoading = true;
  int _myUserId = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _myUserId = prefs.getInt('user_id') ?? 0;
    setState(() => _isLoading = true);
    final convos =
        await ApiService.getConversations(_myUserId);

    // Deduplicate — show one conversation per unique contact
    final Map<int, dynamic> seen = {};
    for (final c in convos) {
      final otherId = c['sender_id'] == _myUserId
          ? c['receiver_id']
          : c['sender_id'];
      if (!seen.containsKey(otherId)) {
        seen[otherId] = c;
      }
    }

    setState(() {
      _conversations = seen.values.toList();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back_ios,
                        color: AppTheme.gold, size: 20),
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
                      children: const [
                        TextSpan(text: 'My '),
                        TextSpan(
                          text: 'Messages',
                          style: TextStyle(color: AppTheme.gold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // List
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppTheme.gold))
                  : _conversations.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              const Icon(
                                  Icons.chat_bubble_outline,
                                  color: AppTheme.gold,
                                  size: 48),
                              const SizedBox(height: 12),
                              Text(
                                'No conversations yet.\nStart one from a match notification!',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white38
                                      : Colors.black38,
                                  height: 1.6,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _conversations.length,
                          itemBuilder: (context, index) {
                            final c = _conversations[index];
                            final isMe =
                                c['sender_id'] == _myUserId;
                            final otherName = isMe
                                ? (c['receiver_name'] ?? 'User')
                                : (c['sender_name'] ?? 'User');
                            final otherId = isMe
                                ? c['receiver_id']
                                : c['sender_id'];
                            final itemName =
                                c['match_item_name'] ?? '';
                            final isUnread = 
                                !isMe && (c['is_read'] == 0 || c['is_read'] == false);

                            return ListTile(
                              contentPadding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 8),
                              leading: CircleAvatar(
                                radius: 24,
                                backgroundColor: AppTheme.gold,
                                child: Text(
                                  otherName.isNotEmpty
                                      ? otherName[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                ),
                              ),
                              title: Text(
                                otherName,
                                style: TextStyle(
                                  fontWeight: isUnread
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isDark
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                              subtitle: Text(
                                itemName.isNotEmpty
                                    ? 'Re: $itemName'
                                    : c['message'] ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark
                                      ? Colors.white54
                                      : Colors.black45,
                                ),
                              ),
                              trailing: isUnread
                                  ? Container(
                                      width: 10,
                                      height: 10,
                                      decoration:
                                          const BoxDecoration(
                                        color: AppTheme.gold,
                                        shape: BoxShape.circle,
                                      ),
                                    )
                                  : null,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const ChatScreen(),
                                    settings: RouteSettings(
                                      arguments: {
                                        'other_user_id': otherId,
                                        'other_name': otherName,
                                        'item_name': itemName,
                                      },
                                    ),
                                  ),
                                ).then((_) => _load());
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}