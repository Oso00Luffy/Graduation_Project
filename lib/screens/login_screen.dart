import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  bool _showUsernameField = false; // Show for sign up only
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
        password: _passwordController.text.trim(),
      );
      Navigator.pushReplacementNamed(context, '/home');
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
        password: _passwordController.text.trim(),
      );
      await cred.user!.updateDisplayName(_usernameController.text.trim());
      Navigator.pushReplacementNamed(context, '/home');
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
      print('Starting Google sign-in...');
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      print('Google user: $googleUser');
      if (googleUser == null) {
        // User cancelled the sign-in
        setState(() => _isLoading = false);
        print('Google sign-in cancelled by user.');
        return;
      }
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      print('Google Auth: ${googleAuth.accessToken} / ${googleAuth.idToken}');
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      print('Firebase sign-in with Google credential successful!');
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      print('Google sign-in error: $e');
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
      Navigator.pushReplacementNamed(context, '/home');
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Color(0xFF10151A) : Color(0xFFF4F8FB),
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 380,
            ),
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
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _showUsernameField ? 'Create your account' : 'Sign in to continue',
                      style: TextStyle(
                        color: isDark ? Colors.grey[300] : Colors.grey[700],
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 28),
                    if (_showUsernameField) ...[
                      _buildTextField(
                        controller: _usernameController,
                        hint: 'Username',
                        icon: Icons.person,
                        keyboardType: TextInputType.name,
                      ),
                      const SizedBox(height: 20),
                    ],
                    _buildTextField(
                      controller: _emailController,
                      hint: 'Email',
                      icon: Icons.email,
                      keyboardType: TextInputType.emailAddress,
                    ),
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
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
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
                            textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                            _showUsernameField
                                ? "Already have an account? "
                                : "Don't have an account? ",
                            style: TextStyle(color: Colors.grey[700], fontSize: 15),
                          ),
                          TextButton(
                            onPressed: _toggleSignUp, // Switches between sign in/up
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size(50, 30),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              alignment: Alignment.centerLeft,
                            ),
                            child: Text(
                              _showUsernameField ? "Sign in" : "Sign up",
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.secondary,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text("or", style: TextStyle(color: Colors.grey[600])),
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
                              child: Image.asset('assets/images/google-logo.png', width: 48, height: 48
                              ),
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
                      SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton.icon(
                          icon: Icon(Icons.person_outline),
                          label: Text('Continue as Guest'),
                          onPressed: _signInAsGuest,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            textStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
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
      style: TextStyle(fontSize: 16),
      decoration: InputDecoration(
        prefixIcon: Icon(icon),
        suffixIcon: suffixIcon,
        hintText: hint,
        filled: true,
        fillColor: Theme.of(context).cardColor,
        contentPadding: EdgeInsets.symmetric(vertical: 18, horizontal: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}