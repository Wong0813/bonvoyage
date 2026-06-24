import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../models/models.dart';
import '../../services/auth_service.dart';
import '../../services/database_init.dart';
import '../../services/database_service.dart';
import '../../utils/app_theme.dart';
import '../customer/customer_home.dart';
import '../agent/agent_home.dart';
import '../admin/admin_home.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _companyController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isRegisterMode = false;
  String _registerRole = 'user';
  String? _errorMessage;

  late AnimationController _bgAnimController;

  @override
  void initState() {
    super.initState();
    _bgAnimController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();
    _initDb();
  }

  Future<void> _initDb() async {
    try {
      await DatabaseInit.initialize();
    } catch (_) {}
  }

  @override
  void dispose() {
    _bgAnimController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    _fullNameController.dispose();
    _companyController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isRegisterMode) {
        bool ok;
        if (_registerRole == 'agent') {
          ok = await AuthService.instance.registerAgent(
            username: _usernameController.text.trim(),
            password: _passwordController.text,
            email: _emailController.text.trim(),
            companyName: _companyController.text.trim(),
            phone: _phoneController.text.trim(),
            location: _locationController.text.trim(),
          );
        } else {
          ok = await AuthService.instance.registerCustomer(
            username: _usernameController.text.trim(),
            password: _passwordController.text,
            email: _emailController.text.trim(),
            fullName: _fullNameController.text.trim(),
          );
        }
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          if (ok) {
            _isRegisterMode = false;
            _errorMessage = null;
            showAppSnackBar(context, 'Registration successful! Please sign in.');
          } else {
            _errorMessage = 'Username or email already exists.';
          }
        });
      } else {
        final user = await AuthService.instance.login(
          _usernameController.text.trim(),
          _passwordController.text,
        );
        if (!mounted) return;
        setState(() => _isLoading = false);
        if (user == null) {
          setState(() => _errorMessage = 'Invalid username or password.');
          return;
        }
        _navigate(user);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _navigate(UserModel user) {
    Widget dest;
    if (user.isAdmin) {
      dest = AdminHome(user: user);
    } else if (user.isAgent) {
      dest = AgentHome(user: user);
    } else {
      dest = CustomerHome(user: user);
    }
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, _, _) => dest,
        transitionDuration: const Duration(milliseconds: 500),
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _bgAnimController,
        builder: (context, child) => Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(
                math.cos(_bgAnimController.value * 2 * math.pi) * 0.5,
                math.sin(_bgAnimController.value * 2 * math.pi) * 0.5,
              ),
              end: Alignment(
                -math.cos(_bgAnimController.value * 2 * math.pi) * 0.5,
                -math.sin(_bgAnimController.value * 2 * math.pi) * 0.5,
              ),
              colors: const [Color(0xFF0A0A1A), Color(0xFF0D1B3E), Color(0xFF1A0D3E)],
            ),
          ),
          child: child,
        ),
        child: SafeArea(
          child: SizedBox.expand(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                  children: [
                    Icon(Icons.flight_takeoff_rounded, color: AppTheme.accent, size: 48),
                    const SizedBox(height: 8),
                    ShaderMask(
                      shaderCallback: (b) => const LinearGradient(
                        colors: [Color(0xFF6C63FF), Color(0xFF00D4FF)],
                      ).createShader(b),
                      child: const Text(
                        'BonVoyage',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: AppTheme.glassCard(radius: 28),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isRegisterMode ? 'Create Account' : 'Welcome Back',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_isRegisterMode) ...[
                              const SizedBox(height: 16),
                              SegmentedButton<String>(
                                segments: const [
                                  ButtonSegment(value: 'user', label: Text('Customer')),
                                  ButtonSegment(value: 'agent', label: Text('Agent')),
                                ],
                                selected: {_registerRole},
                                onSelectionChanged: (s) =>
                                    setState(() => _registerRole = s.first),
                              ),
                            ],
                            const SizedBox(height: 20),
                            _field(_usernameController, 'Username', Icons.person_outline),
                            if (_isRegisterMode) ...[
                              const SizedBox(height: 12),
                              _field(_emailController, 'Email', Icons.email_outlined),
                              if (_registerRole == 'user') ...[
                                const SizedBox(height: 12),
                                _field(_fullNameController, 'Full Name', Icons.badge_outlined),
                              ] else ...[
                                const SizedBox(height: 12),
                                _field(_companyController, 'Company Name', Icons.business),
                                const SizedBox(height: 12),
                                _field(_phoneController, 'Phone', Icons.phone),
                                const SizedBox(height: 12),
                                _field(_locationController, 'Location', Icons.location_on),
                              ],
                            ],
                            const SizedBox(height: 12),
                            _field(
                              _passwordController,
                              'Password',
                              Icons.lock_outline,
                              obscure: _obscurePassword,
                              suffix: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                  color: Colors.white38,
                                  size: 20,
                                ),
                                onPressed: () =>
                                    setState(() => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            if (_errorMessage != null) ...[
                              const SizedBox(height: 12),
                              Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent)),
                            ],
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(_isRegisterMode ? 'Register' : 'Sign In'),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Center(
                              child: TextButton(
                                onPressed: () => setState(() {
                                  _isRegisterMode = !_isRegisterMode;
                                  _errorMessage = null;
                                }),
                                child: Text(
                                  _isRegisterMode
                                      ? 'Already have an account? Sign In'
                                      : 'No account? Register',
                                  style: TextStyle(color: Color(0xFF00D4FF)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _hintBox(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
   );
  }

  Widget _field(
    TextEditingController c,
    String label,
    IconData icon, {
    bool obscure = false,
    Widget? suffix,
  }) {
    return TextFormField(
      controller: c,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: AppTheme.input(label, icon: icon).copyWith(suffixIcon: suffix),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Required';
        if (label == 'Password' && v.length < 6) return 'Min 6 characters';
        if (label == 'Email' && !v.contains('@')) return 'Invalid email';
        return null;
      },
    );
  }

  Widget _hintBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassCard(radius: 14),
      child: Column(
        children: [
          Text('Demo Accounts', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
          const SizedBox(height: 8),
          const Text('admin/admin123  ·  user/user123  ·  agent/agent123',
              style: TextStyle(color: Colors.white54, fontSize: 11)),
        ],
      ),
    );
  }
}

Future<void> logout(BuildContext context) async {
  await DatabaseService.instance.close();
  if (!context.mounted) return;
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (_) => const LoginScreen()),
  );
}
