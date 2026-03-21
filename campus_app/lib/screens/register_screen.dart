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
    print('REGISTER RESULT: $result'); // ← add this line
    setState(() => _isLoading = false);
    

    setState(() => _isLoading = false);

    if (result.containsKey('message') && result['message'] == 'User registered') {
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
      setState(() => _errorMessage = result['error'] ?? result['message'] ?? 'Registration failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Icon(Icons.arrow_back_ios,
                    color: AppTheme.gold, size: 22),
              ),

              const SizedBox(height: 28),

              // Title
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  children: const [
                    TextSpan(text: 'Create your\n'),
                    TextSpan(
                      text: 'Account!',
                      style: TextStyle(color: AppTheme.gold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Join your campus lost & found network',
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.black45,
                  fontSize: 15,
                ),
              ),

              const SizedBox(height: 36),

              // Name field
              _buildLabel('Full Name', isDark),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                decoration: const InputDecoration(hintText: 'Shyam TJ'),
              ),

              const SizedBox(height: 20),

              // Email field
              _buildLabel('College Email', isDark),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                decoration: const InputDecoration(
                  hintText: 'your_id@srmist.edu.in',
                  suffixIcon: Icon(Icons.circle, color: AppTheme.gold, size: 10),
                ),
              ),

              const SizedBox(height: 20),

              // Student ID field
              _buildLabel('Student ID', isDark),
              const SizedBox(height: 8),
              TextField(
                controller: _studentIdController,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                decoration: const InputDecoration(hintText: 'RA*************'),
              ),

              const SizedBox(height: 20),

              // Password field
              _buildLabel('Password', isDark),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  hintText: 'Your Password',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: AppTheme.gold,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),

              // Error message
              if (_errorMessage.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(_errorMessage,
                    style: const TextStyle(
                        color: Colors.redAccent, fontSize: 13)),
              ],

              const SizedBox(height: 36),

              // Register button
              _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppTheme.gold))
                  : ElevatedButton(
                      onPressed: _register,
                      child: const Text('Create Account'),
                    ),

              const SizedBox(height: 20),

              // Already have account
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.pushReplacementNamed(context, '/login'),
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white54 : Colors.black45),
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
            ],
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