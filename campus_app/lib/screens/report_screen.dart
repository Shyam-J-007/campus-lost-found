import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../theme.dart';


class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _itemNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  bool _isLost = true;
  bool _isLoading = false;
  String _errorMessage = '';
  DateTime _selectedDate = DateTime.now();
  bool _argLoaded = false;
  Uint8List? _webImageBytes;
  XFile? _pickedFile;
  final ImagePicker _picker = ImagePicker();

  final List<String> _commonItems = [
    'Purse',
    'Phone',
    'Money (Rupees)',
    'ID Card',
    'Keys',
    'Water Bottle',
    'Bag',
    'Watch',
    'Earphones',
    'Calculator',
    'Laptop',
    'Charger',
    'Umbrella',
    'Books',
    'Other',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_argLoaded) {
      final arg =
          ModalRoute.of(context)?.settings.arguments as String?;
      if (arg != null) {
        _itemNameController.text = arg;
      }
      _argLoaded = true;
    }
  }

  // ── Single helper to pick and store image ─────────────────
  Future<void> _handlePickedImage(XFile picked) async {
    if (kIsWeb) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _pickedFile = picked;
        _webImageBytes = bytes;
      });
    } else {
      setState(() {
        _pickedFile = picked;
      });
    }
  }

  Future<void> _pickImage() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor:
          isDark ? AppTheme.darkCard : AppTheme.lightCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Camera — hidden on web
            if (!kIsWeb)
              ListTile(
                leading: const Icon(Icons.camera_alt,
                    color: AppTheme.gold),
                title: Text(
                  'Take a photo',
                  style: TextStyle(
                      color:
                          isDark ? Colors.white : Colors.black87),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final picked = await _picker.pickImage(
                    source: ImageSource.camera,
                    imageQuality: 70,
                  );
                  if (picked != null) {
                    await _handlePickedImage(picked);
                  }
                },
              ),

            // Gallery
            ListTile(
              leading: const Icon(Icons.photo_library,
                  color: AppTheme.gold),
              title: Text(
                'Choose from gallery',
                style: TextStyle(
                    color:
                        isDark ? Colors.white : Colors.black87),
              ),
              onTap: () async {
                Navigator.pop(context);
                final picked = await _picker.pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 70,
                );
                if (picked != null) {
                  await _handlePickedImage(picked);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme:
                const ColorScheme.dark(primary: Color.fromARGB(255, 164, 121, 21)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _submit() async {
    if (_itemNameController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _locationController.text.isEmpty) {
      setState(() => _errorMessage = 'Please fill in all fields');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id') ?? 0;
    final date =
        '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

    // Upload image first if selected
    String? imageUrl;
    if (_pickedFile != null) {
      if (kIsWeb) {
        imageUrl = await ApiService.uploadImageWeb(_pickedFile!);
      } else {
        imageUrl = await ApiService.uploadImage(_pickedFile!.path);
      }
    }

    Map<String, dynamic> result;

    if (_isLost) {
      result = await ApiService.reportLostItem(
        userId: userId,
        itemName: _itemNameController.text.trim(),
        description: _descriptionController.text.trim(),
        location: _locationController.text.trim(),
        date: date,
        imageUrl: imageUrl,
      );
    } else {
      result = await ApiService.reportFoundItem(
        userId: userId,
        itemName: _itemNameController.text.trim(),
        description: _descriptionController.text.trim(),
        location: _locationController.text.trim(),
        date: date,
        imageUrl: imageUrl,
      );
    }

    setState(() => _isLoading = false);

    if (result.containsKey('message')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isLost
                ? 'Lost item reported!'
                : 'Found item reported!'),
            backgroundColor: AppTheme.gold,
          ),
        );
        Navigator.pop(context);
      }
    } else {
      setState(() =>
          _errorMessage = result['error'] ?? 'Failed to report item');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: isDark
                  ? AppTheme.darkBgGradient
                  : AppTheme.lightBgGradient,
            ),
        child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
              horizontal: 28, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.arrow_back_ios,
                    color: AppTheme.gold, size: 22),
              ),

              const SizedBox(height: 24),

              // Title
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  children: const [
                    TextSpan(text: 'Report an\n'),
                    TextSpan(
                      text: 'Item!',
                      style: TextStyle(color: AppTheme.gold),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Lost / Found toggle
              Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? AppTheme.darkSurface
                      : AppTheme.lightSurface,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    _toggleButton('I Lost It', _isLost, () {
                      setState(() => _isLost = true);
                    }),
                    _toggleButton('I Found It', !_isLost, () {
                      setState(() => _isLost = false);
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Common items chips
              _buildLabel('Select Item Type', isDark),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _commonItems.map((item) {
                  final isSelected =
                      _itemNameController.text == item;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _itemNameController.text = item;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.gold
                            : isDark
                                ? AppTheme.darkSurface
                                : AppTheme.lightSurface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.gold
                              : isDark
                                  ? Colors.white12
                                  : Colors.black12,
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        item,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected
                              ? Colors.black
                              : isDark
                                  ? Colors.white70
                                  : Colors.black54,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // Item name
              _buildLabel('Item Name', isDark),
              const SizedBox(height: 8),
              TextField(
                controller: _itemNameController,
                onChanged: (_) => setState(() {}),
                style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87),
                decoration: const InputDecoration(
                    hintText: 'Or type a custom item name'),
              ),

              const SizedBox(height: 20),

              // Description
              _buildLabel('Description', isDark),
              const SizedBox(height: 8),
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87),
                decoration: const InputDecoration(
                  hintText: 'Describe the item in detail...',
                ),
              ),

              const SizedBox(height: 20),

              // Location
              _buildLabel('Location', isDark),
              const SizedBox(height: 8),
              TextField(
                controller: _locationController,
                style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87),
                decoration: const InputDecoration(
                    hintText: 'e.g. Campus Library, Lab 3'),
              ),

              const SizedBox(height: 20),

              // Date picker
              _buildLabel('Date', isDark),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppTheme.darkSurface
                        : AppTheme.lightCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: isDark
                            ? Colors.white12
                            : const Color(0xFFE0D8C8)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          color: AppTheme.gold, size: 18),
                      const SizedBox(width: 12),
                      Text(
                        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                        style: TextStyle(
                          color: isDark
                              ? Colors.white
                              : Colors.black87,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Photo picker
              _buildLabel('Photo (optional)', isDark),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  height: 160,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppTheme.darkSurface
                        : AppTheme.lightSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? Colors.white12
                          : Colors.black12,
                      width: 0.5,
                    ),
                  ),
                  child: _pickedFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // ── Image preview ──────────
                              kIsWeb
                                  ? (_webImageBytes != null
                                      ? Image.memory(
                                          _webImageBytes!,
                                          fit: BoxFit.cover,
                                        )
                                      : const Center(
                                          child:
                                              CircularProgressIndicator(
                                                  color:
                                                      AppTheme.gold),
                                        ))
                                  : Image.network(
                                      _pickedFile!.path,
                                      fit: BoxFit.cover,
                                    ),

                              // ── Remove button ──────────
                              Positioned(
                                top: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: () => setState(() {
                                    _pickedFile = null;
                                    _webImageBytes = null;
                                  }),
                                  child: Container(
                                    padding:
                                        const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close,
                                        color: Colors.white,
                                        size: 16),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            const Icon(
                                Icons.add_photo_alternate_outlined,
                                color: AppTheme.gold,
                                size: 40),
                            const SizedBox(height: 8),
                            Text(
                              'Tap to add a photo',
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white38
                                    : Colors.black38,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              // AI identify button — shows after image is picked
              if (_pickedFile != null) ...[
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () async {
                    if (_pickedFile == null) return;

                    // Upload image first
                    String? imageUrl;
                    if (kIsWeb) {
                      imageUrl = await ApiService.uploadImageWeb(_pickedFile!);
                    } else {
                      imageUrl = await ApiService.uploadImage(_pickedFile!.path);
                    }

                    if (imageUrl == null) return;

                    setState(() => _isLoading = true);
                    final result = await ApiService.identifyImage(imageUrl);
                    setState(() => _isLoading = false);

                    if (result.containsKey('item_name')) {
                      setState(() {
                        _itemNameController.text = result['item_name'] ?? '';
                        _descriptionController.text =
                            result['description'] ?? '';
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('AI identified the item!'),
                          backgroundColor: AppTheme.gold,
                        ),
                      );
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    height: 46,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                          color: AppTheme.gold, width: 1.5),
                      color: AppTheme.gold.withOpacity(0.05),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.auto_awesome,
                            color: AppTheme.gold, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'AI Identify Item',
                          style: TextStyle(
                            color: AppTheme.gold,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // Error
              if (_errorMessage.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(_errorMessage,
                    style: const TextStyle(
                        color: Colors.redAccent, fontSize: 13)),
              ],

              const SizedBox(height: 36),

              // Submit button
              _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppTheme.gold))
                  : GoldButton(
                      text: _isLost ? 'Report Lost Item' : 'Report Found Item',
                      onPressed: _submit,
                    ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),)
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

  Widget _buildLabel(String text, bool isDark) {
    return Text(
      text,
      style: TextStyle(
        color: isDark ? Colors.white70 : Colors.black54,
        fontSize: 13,
      ),
    );
  }
}