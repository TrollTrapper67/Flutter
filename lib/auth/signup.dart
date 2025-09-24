import 'package:flutter/material.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isPasswordObscured = true;
  bool _isConfirmPasswordObscured = true;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Validation rules
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return "Email is required.";
    final regex = RegExp(r'^[\w\.-]+@(gmail\.com|yahoo\.com)$');
    if (!regex.hasMatch(value.trim())) {
      return "Use a valid gmail.com or yahoo.com address.";
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) return "Phone number is required.";
    final regex = RegExp(r'^09\d{9}$');
    if (!regex.hasMatch(value.trim())) {
      return "Phone must start with 09 and be 11 digits.";
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return "Password is required.";
    final regex = RegExp(r'^(?=.*[A-Z])(?=.*\d)(?=.*[\W_]).{3,}$');
    if (!regex.hasMatch(value)) {
      return "Must have 1 capital, 1 number, 1 special char, min 3 chars.";
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value != _passwordController.text) {
      return "Passwords do not match.";
    }
    return null;
  }

  void _handleSignUp() {
    if (_formKey.currentState?.validate() ?? false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Sign up successful!"),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                _buildTextFormField(
                  controller: _nameController,
                  labelText: "Full Name",
                ),
                const SizedBox(height: 20),
                _buildTextFormField(
                  controller: _usernameController,
                  labelText: "Username",
                ),
                const SizedBox(height: 20),
                _buildTextFormField(
                  controller: _emailController,
                  labelText: "Email Address",
                  keyboardType: TextInputType.emailAddress,
                  validator: _validateEmail,
                ),
                const SizedBox(height: 20),
                _buildTextFormField(
                  controller: _phoneController,
                  labelText: "Phone Number",
                  keyboardType: TextInputType.phone,
                  validator: _validatePhone,
                ),
                const SizedBox(height: 20),
                _buildPasswordFormField(
                  controller: _passwordController,
                  labelText: "Password",
                  isObscured: _isPasswordObscured,
                  onToggleVisibility: () {
                    setState(() {
                      _isPasswordObscured = !_isPasswordObscured;
                    });
                  },
                  validator: _validatePassword,
                ),
                const SizedBox(height: 20),
                _buildPasswordFormField(
                  controller: _confirmPasswordController,
                  labelText: "Confirm Password",
                  isObscured: _isConfirmPasswordObscured,
                  onToggleVisibility: () {
                    setState(() {
                      _isConfirmPasswordObscured = !_isConfirmPasswordObscured;
                    });
                  },
                  validator: _validateConfirmPassword,
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _handleSignUp,
                  child: const Text('Sign Up', style: TextStyle(fontSize: 18)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Shared border style
  OutlineInputBorder _inputBorder(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: 1.0),
      );

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: labelText,
        filled: true,
        fillColor: Colors.white,
        border: _inputBorder(Colors.grey.shade300),
        enabledBorder: _inputBorder(Colors.grey.shade300),
        focusedBorder: _inputBorder(Theme.of(context).colorScheme.primary),
        errorBorder: _inputBorder(Colors.red),
        focusedErrorBorder: _inputBorder(Colors.red),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 15.0,
          horizontal: 20.0,
        ),
      ),
    );
  }

  Widget _buildPasswordFormField({
    required TextEditingController controller,
    required String labelText,
    required bool isObscured,
    required VoidCallback onToggleVisibility,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isObscured,
      validator: validator,
      decoration: InputDecoration(
        labelText: labelText,
        filled: true,
        fillColor: Colors.white,
        border: _inputBorder(Colors.grey.shade300),
        enabledBorder: _inputBorder(Colors.grey.shade300),
        focusedBorder: _inputBorder(Theme.of(context).colorScheme.primary),
        errorBorder: _inputBorder(Colors.red),
        focusedErrorBorder: _inputBorder(Colors.red),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 15.0,
          horizontal: 20.0,
        ),
        suffixIcon: IconButton(
          icon: Icon(isObscured ? Icons.visibility_off : Icons.visibility),
          onPressed: onToggleVisibility,
        ),
      ),
    );
  }
}
