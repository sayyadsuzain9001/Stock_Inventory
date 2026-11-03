import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../services/auth_service.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Sign in / create account. Admins see all records; users submit items.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.auth});
  final AuthService auth;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _register = false;
  bool _busy = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (_register) {
        await widget.auth.register(_email.text, _password.text);
      } else {
        await widget.auth.signIn(_email.text, _password.text);
      }
    } catch (e) {
      if (mounted) setState(() => _error = authErrorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const NetworkBackdrop(url: AppImages.warehouseHero, opacity: 0.45),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          gradient: AppColors.goldGradient,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: const Icon(
                          Icons.inventory_2_rounded,
                          color: Colors.white,
                          size: 38,
                        ),
                      ).animate().scale(
                        duration: 500.ms,
                        curve: Curves.easeOutBack,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'StockPilot',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Stock Inventory Manager',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: 22),
                      _buildCard(context)
                          .animate()
                          .fadeIn(duration: 400.ms)
                          .slideY(begin: 0.08, end: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _register ? 'Create an account' : 'Welcome back',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              _register
                  ? 'New accounts can submit stock items.'
                  : 'Admins manage records. Users submit stock items.',
              style: const TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 18),
            TextFormField(
              key: const Key('loginEmail'),
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.alternate_email_rounded),
              ),
              validator: (v) {
                final s = (v ?? '').trim();
                if (s.isEmpty) return 'Email is required';
                if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s)) {
                  return 'Enter a valid email address';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              key: const Key('loginPassword'),
              controller: _password,
              obscureText: _obscure,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  tooltip: _obscure ? 'Show password' : 'Hide password',
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (v) => (v ?? '').length < 6
                  ? 'Password must be at least 6 characters'
                  : null,
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              child: _error == null
                  ? const SizedBox(height: 18)
                  : Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: AppColors.crimson,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _error!,
                              key: const Key('loginError'),
                              style: const TextStyle(color: AppColors.crimson),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            GradientButton(
              key: const Key('loginButton'),
              label: _register ? 'Create account' : 'Sign in',
              busyLabel: _register ? 'Creating...' : 'Signing in...',
              icon: _register
                  ? Icons.person_add_alt_1_rounded
                  : Icons.login_rounded,
              busy: _busy,
              onPressed: _submit,
            ),
            const SizedBox(height: 10),
            TextButton(
              key: const Key('toggleRegister'),
              onPressed: _busy
                  ? null
                  : () => setState(() {
                      _register = !_register;
                      _error = null;
                    }),
              child: Text(
                _register
                    ? 'Already have an account? Sign in'
                    : 'New here? Create an account',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
