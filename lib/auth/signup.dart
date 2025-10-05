import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _passwordVisible = false;
  bool _isLoading = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_passwordController.text.trim() !=
        _confirmPasswordController.text.trim()) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Passwords do not match")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // ✅ Create user in Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = userCredential.user;

      if (user != null) {
        // ✅ Save user info & role in Firestore
        await FirebaseFirestore.instance.collection("users").doc(user.uid).set({
          "email": user.email,
<<<<<<< Updated upstream
=======
          "name": _nameController.text.trim(),
          "age": int.tryParse(_ageController.text.trim()) ?? 0,
          "address": _addressController.text.trim(),
          "birthday": _selectedBirthday != null
              ? Timestamp.fromDate(_selectedBirthday!)
              : null,
>>>>>>> Stashed changes
          "role": "user", // default role for all new signups
          "createdAt": FieldValue.serverTimestamp(),
        });

<<<<<<< Updated upstream
        // ✅ Navigate user to dashboard
        Navigator.pushReplacementNamed(context, '/userDashboard', arguments: user.email);
=======
        // ✅ Show success message and redirect to login page
        if (context.mounted) {
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Account created successfully! Please login."),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );

          // Wait a moment to show the success message, then navigate to login
          await Future.delayed(const Duration(seconds: 2));

          if (context.mounted) {
            // ignore: use_build_context_synchronously
            Navigator.pushReplacementNamed(context, '/login');
          }
        }
>>>>>>> Stashed changes
      }
    } on FirebaseAuthException catch (e) {
      String message = "Signup failed. Please try again.";
      if (e.code == 'email-already-in-use') {
        message = "This email is already registered.";
      } else if (e.code == 'weak-password') {
        message = "Password should be at least 6 characters.";
<<<<<<< Updated upstream
=======
      } else if (e.code == 'invalid-email') {
        message = "Invalid email address.";
      }
      if (context.mounted) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      if (context.mounted) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("An error occurred: $e")));
>>>>>>> Stashed changes
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  OutlineInputBorder _inputBorder(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(30.0),
    borderSide: BorderSide(color: color, width: 1.0),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Sign Up",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.yellow),
        ),
        centerTitle: true,
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
<<<<<<< Updated upstream
              const SizedBox(height: 40),
              TextFormField(
                controller: _emailController,
                validator: (value) =>
                    value == null || value.isEmpty ? "Email is required." : null,
=======
              const SizedBox(height: 20),

              // Name Field
              TextFormField(
                controller: _nameController,
                validator: (value) => value == null || value.isEmpty
                    ? "Full name is required."
                    : null,
                decoration: InputDecoration(
                  labelText: "Full Name",
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: _inputBorder(Colors.grey.shade300),
                  enabledBorder: _inputBorder(Colors.grey.shade300),
                  focusedBorder: _inputBorder(
                    Theme.of(context).colorScheme.primary,
                  ),
                  prefixIcon: const Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 20),

              // Email Field
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                validator: (value) => value == null || value.isEmpty
                    ? "Email is required."
                    : null,
>>>>>>> Stashed changes
                decoration: InputDecoration(
                  labelText: "Email",
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: _inputBorder(Colors.grey.shade300),
                  enabledBorder: _inputBorder(Colors.grey.shade300),
<<<<<<< Updated upstream
                  focusedBorder:
                      _inputBorder(Theme.of(context).colorScheme.primary),
                ),
              ),
              const SizedBox(height: 20),
=======
                  focusedBorder: _inputBorder(
                    Theme.of(context).colorScheme.primary,
                  ),
                  prefixIcon: const Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 20),

              // Age Field
              TextFormField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                validator: _validateAge,
                decoration: InputDecoration(
                  labelText: "Age",
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: _inputBorder(Colors.grey.shade300),
                  enabledBorder: _inputBorder(Colors.grey.shade300),
                  focusedBorder: _inputBorder(
                    Theme.of(context).colorScheme.primary,
                  ),
                  prefixIcon: const Icon(Icons.cake),
                  suffixText: "years",
                ),
              ),
              const SizedBox(height: 20),

              // Birthday Field
              TextFormField(
                controller: _birthdayController,
                readOnly: true,
                validator: _validateBirthday,
                onTap: () => _selectBirthday(context),
                decoration: InputDecoration(
                  labelText: "Birthday",
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: _inputBorder(Colors.grey.shade300),
                  enabledBorder: _inputBorder(Colors.grey.shade300),
                  focusedBorder: _inputBorder(
                    Theme.of(context).colorScheme.primary,
                  ),
                  prefixIcon: const Icon(Icons.calendar_today),
                  hintText: "Select your birthday",
                ),
              ),
              const SizedBox(height: 20),

              // Address Field
              TextFormField(
                controller: _addressController,
                maxLines: 2,
                validator: (value) => value == null || value.isEmpty
                    ? "Address is required."
                    : null,
                decoration: InputDecoration(
                  labelText: "Address",
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: _inputBorder(Colors.grey.shade300),
                  enabledBorder: _inputBorder(Colors.grey.shade300),
                  focusedBorder: _inputBorder(
                    Theme.of(context).colorScheme.primary,
                  ),
                  prefixIcon: const Icon(Icons.home),
                  hintText: "Enter your complete address",
                ),
              ),
              const SizedBox(height: 20),

              // Password Field
>>>>>>> Stashed changes
              TextFormField(
                controller: _passwordController,
                obscureText: !_passwordVisible,
                validator: (value) =>
                    value == null || value.isEmpty ? "Password is required." : null,
                decoration: InputDecoration(
                  labelText: "Password",
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: _inputBorder(Colors.grey.shade300),
                  enabledBorder: _inputBorder(Colors.grey.shade300),
<<<<<<< Updated upstream
                  focusedBorder:
                      _inputBorder(Theme.of(context).colorScheme.primary),
=======
                  focusedBorder: _inputBorder(
                    Theme.of(context).colorScheme.primary,
                  ),
                  prefixIcon: const Icon(Icons.lock),
>>>>>>> Stashed changes
                  suffixIcon: IconButton(
                    tooltip: _passwordVisible
                        ? 'Hide password'
                        : 'Show password',
                    icon: Icon(
                      _passwordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() => _passwordVisible = !_passwordVisible);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                validator: (value) =>
                    value == null || value.isEmpty ? "Confirm your password." : null,
                decoration: InputDecoration(
                  labelText: "Confirm Password",
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: _inputBorder(Colors.grey.shade300),
                  enabledBorder: _inputBorder(Colors.grey.shade300),
<<<<<<< Updated upstream
                  focusedBorder:
                      _inputBorder(Theme.of(context).colorScheme.primary),
=======
                  focusedBorder: _inputBorder(
                    Theme.of(context).colorScheme.primary,
                  ),
                  prefixIcon: const Icon(Icons.lock_outline),
>>>>>>> Stashed changes
                ),
              ),
              const SizedBox(height: 40),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _handleSignup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(
                          255,
                          163,
                          234,
                          165,
                        ),
                        foregroundColor: const Color.fromARGB(248, 190, 171, 7),
                      ),
                      child: const Text("Sign Up"),
                    ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/login');
                },
                child: RichText(
                  text: TextSpan(
                    text: "Already have an account? ",
                    style: TextStyle(color: Colors.grey[700], fontSize: 16),
                    children: [
                      TextSpan(
                        text: "Login",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
