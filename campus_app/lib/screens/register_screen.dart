import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String _errorMessage = '';

  Future<void> _register() async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _studentIdController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      setState(() => _errorMessage = 'Please fill in all fields');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final result = await ApiService.register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      studentId: _studentIdController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (result.containsKey('message') &&
        result['message'] == 'User registered') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created! Please log in.'),
            backgroundColor: AppTheme.gold,
          ),
        );
        Navigator.pushReplacementNamed(context, '/login');
      }
    } else {
      setState(() => _errorMessage =
          result['error'] ?? result['message'] ?? 'Registration failed');
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
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppTheme.darkSurface
                          : AppTheme.lightSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppTheme.gold.withOpacity(0.3)),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new,
                        color: AppTheme.gold, size: 18),
                  ),
                ),

                const SizedBox(height: 32),

                // Gold icon
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: AppTheme.goldGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: AppTheme.goldGlow,
                  ),
                  child: const Icon(Icons.person_add,
                      color: Colors.black, size: 32),
                ),

                const SizedBox(height: 24),

                Text(
                  'Create your',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const GoldGradientText(
                  'Account!',
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
                const SizedBox(height: 8),
                Text(
                  'Join your campus lost & found network',
                  style: TextStyle(
                    color: isDark ? Colors.white54 : Colors.black45,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 32),

                _buildField('Full Name', _nameController,
                    'Shyam TJ', isDark),
                const SizedBox(height: 16),
                _buildField('College Email', _emailController,
                    'you@college.edu', isDark),
                const SizedBox(height: 16),
                _buildField('Student ID', _studentIdController,
                    '21ECE100', isDark),
                const SizedBox(height: 16),

                // Password
                _buildLabel('Password', isDark),
                const SizedBox(height: 8),
                _buildShadowBox(
                  isDark: isDark,
                  child: TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      hintText: '••••••••',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: AppTheme.gold,
                          size: 20,
                        ),
                        onPressed: () => setState(() =>
                            _obscurePassword = !_obscurePassword),
                      ),
                    ),
                  ),
                ),

                if (_errorMessage.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.errorRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppTheme.errorRed.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: AppTheme.errorRed, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage,
                            style: const TextStyle(
                                color: AppTheme.errorRed,
                                fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                GoldButton(
                  text: 'Create Account',
                  onPressed: _register,
                  isLoading: _isLoading,
                ),

                const SizedBox(height: 20),

                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.pushReplacementNamed(
                        context, '/login'),
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? Colors.white54
                                : Colors.black45),
                        children: const [
                          TextSpan(text: 'Already have an account? '),
                          TextSpan(
                            text: 'Sign In',
                            style: TextStyle(
                                color: AppTheme.gold,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller,
      String hint, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label, isDark),
        const SizedBox(height: 8),
        _buildShadowBox(
          isDark: isDark,
          child: TextField(
            controller: controller,
            style: TextStyle(
                color: isDark ? Colors.white : Colors.black87),
            decoration: InputDecoration(hintText: hint),
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text, bool isDark) {
    return Text(
      text,
      style: TextStyle(
        color: isDark ? Colors.white70 : Colors.black54,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildShadowBox(
      {required bool isDark, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}