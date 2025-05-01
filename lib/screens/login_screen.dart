import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  bool _showUsernameField = false;
  String _error = '';
  bool _isLoading = false;
  bool _obscurePassword = true;

  String _mapFirebaseAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found for this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'weak-password':
        return 'Password should be at least 6 characters.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _mapFirebaseAuthError(e.code));
    } catch (e) {
      setState(() => _error = 'Login failed. Please try again.');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _register() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      if (_usernameController.text.trim().isEmpty) {
        setState(() => _error = 'Please enter a username.');
        _isLoading = false;
        return;
      }

      UserCredential cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      await cred.user?.updateDisplayName(_usernameController.text.trim());

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _mapFirebaseAuthError(e.code));
    } catch (e) {
      setState(() => _error = 'Registration failed. Please try again.');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _googleSignIn() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (e) {
      setState(() => _error = 'Google sign-in failed. Please try again.');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _signInAsGuest() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      await FirebaseAuth.instance.signInAnonymously();

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (e) {
      setState(() => _error = 'Guest sign-in failed. Please try again.');
    }

    setState(() => _isLoading = false);
  }

  void _toggleSignUp() {
    setState(() {
      _showUsernameField = !_showUsernameField;
      _error = '';
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Card(
              elevation: 10,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_outline, size: 60, color: theme.primaryColor),
                    const SizedBox(height: 16),
                    Text(
                      'Welcome!',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _showUsernameField ? 'Create your account' : 'Sign in to continue',
                      style: TextStyle(color: Colors.grey[700], fontSize: 16),
                    ),
                    const SizedBox(height: 28),
                    if (_showUsernameField)
                      _buildTextField(controller: _usernameController, hint: 'Username', icon: Icons.person),
                    if (_showUsernameField) const SizedBox(height: 20),
                    _buildTextField(controller: _emailController, hint: 'Email', icon: Icons.email),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _passwordController,
                      hint: 'Password',
                      icon: Icons.lock,
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility : Icons.visibility_off,
                          color: theme.primaryColor,
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (_error.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          _error,
                          style: const TextStyle(color: Colors.red, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ),
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: CircularProgressIndicator(),
                      )
                    else ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _showUsernameField ? _register : _login,
                          icon: Icon(_showUsernameField ? Icons.person_add : Icons.login),
                          label: Text(_showUsernameField ? 'Sign Up' : 'Sign In'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _showUsernameField ? "Already have an account? " : "Don't have an account? ",
                            style: TextStyle(color: Colors.grey[700], fontSize: 15),
                          ),
                          TextButton(
                            onPressed: _toggleSignUp,
                            child: Text(
                              _showUsernameField ? "Sign in" : "Sign up",
                              style: TextStyle(
                                color: theme.colorScheme.secondary,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: const [
                          Expanded(child: Divider()),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text("or"),
                          ),
                          Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: SizedBox(
                            width: 24,
                            height: 24,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Image.asset('assets/images/google-logo.png'),
                            ),
                          ),
                          label: const Text('Sign in with Google'),
                          onPressed: _googleSignIn,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton.icon(
                          icon: Icon(Icons.person_outline),
                          label: const Text('Continue as Guest'),
                          onPressed: _signInAsGuest,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        prefixIcon: Icon(icon),
        suffixIcon: suffixIcon,
        hintText: hint,
        filled: true,
        fillColor: Theme.of(context).cardColor,
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}