import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/auth_controller.dart';
import '../models/user_model.dart';
import 'home_screen.dart';
import 'signup_screen.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isDriver = false;
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(
          () => ref.read(authControllerProvider.notifier).clearMessages(),
    );
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final userType = _isDriver ? UserType.driver : UserType.user;

      await ref.read(authControllerProvider.notifier).signInWithEmailPassword(
        email: _emailController.text,
        password: _passwordController.text,
        userType: userType,
      );
    }
  }

  Future<void> _handleGoogleSignIn() async {
    final userType = _isDriver ? UserType.driver : UserType.user;

    await ref.read(authControllerProvider.notifier).signInWithGoogle(
      userType: userType,
    );
  }

  void _handleAppleSignIn() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Apple Sign-In coming soon'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _navigateToSignUp() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const SignUpScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: Colors.red,
          ),
        );
      }

      if (next.successMessage != null && next.user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    });

    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildLogo(),
                  const SizedBox(height: 48),

                  const Text(
                    'Sign-In',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 40),

                  _buildEmailField(),
                  const SizedBox(height: 16),

                  _buildPasswordField(),
                  const SizedBox(height: 24),

                  _buildUserTypeToggle(),
                  const SizedBox(height: 32),

                  _buildLoginButton(authState.isLoading),
                  const SizedBox(height: 32),

                  _buildDivider(),
                  const SizedBox(height: 32),

                  _buildSocialLoginButtons(authState.isLoading),
                  const SizedBox(height: 24),

                  _buildSignUpLink(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ================= UI COMPONENTS =================

  Widget _buildLogo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Icon(Icons.directions_car, size: 40),
        SizedBox(width: 12),
        Text(
          'VANTREK',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      decoration: const InputDecoration(
        hintText: 'Email',
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Enter email';
        if (!value.contains('@')) return 'Invalid email';
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: !_isPasswordVisible,
      decoration: InputDecoration(
        hintText: 'Password',
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordVisible
                ? Icons.visibility
                : Icons.visibility_off,
          ),
          onPressed: () {
            setState(() {
              _isPasswordVisible = !_isPasswordVisible;
            });
          },
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Enter password';
        if (value.length < 6) return 'Min 6 characters';
        return null;
      },
    );
  }

  Widget _buildUserTypeToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ChoiceChip(
          label: const Text('User'),
          selected: !_isDriver,
          onSelected: (_) => setState(() => _isDriver = false),
        ),
        const SizedBox(width: 12),
        ChoiceChip(
          label: const Text('Driver'),
          selected: _isDriver,
          onSelected: (_) => setState(() => _isDriver = true),
        ),
      ],
    );
  }

  Widget _buildLoginButton(bool isLoading) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : _handleLogin,
        child: isLoading
            ? const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        )
            : const Text('Log In'),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('OR'),
        ),
        Expanded(child: Divider()),
      ],
    );
  }

  // 🔥 FIXED OVERFLOW HERE
  Widget _buildSocialLoginButtons(bool isLoading) {
    return Row(
      children: [
        Expanded(
          child: _buildSocialButton(
            label: 'Continue with Google',
            icon: Icons.g_mobiledata,
            onTap: isLoading ? null : _handleGoogleSignIn,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSocialButton(
            label: 'Continue with Apple',
            icon: Icons.apple,
            onTap: isLoading ? null : _handleAppleSignIn,
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required String label,
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
          color: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  color: onTap == null ? Colors.grey : Colors.black,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              icon,
              size: 22,
              color: onTap == null ? Colors.grey : Colors.black,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignUpLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Don't have an account? "),
        GestureDetector(
          onTap: _navigateToSignUp,
          child: const Text(
            'Sign Up',
            style: TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
