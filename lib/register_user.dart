import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterUserScreen extends StatefulWidget {
  const RegisterUserScreen({super.key});

  @override
  State<RegisterUserScreen> createState() => _RegisterUserScreenState();
}

class _RegisterUserScreenState extends State<RegisterUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String selectedRole = "student";
  bool isLoading = false;

  Future<void> registerNewUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      // ⚠️ Note: Creating a user here will log the Admin out unless 
      // you use a specialized Admin SDK or a secondary Firebase App instance.
      // For a school project, we usually demonstrate the Firestore entry logic:
      
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // Save role to Firestore
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        "name": nameController.text.trim(),
        "email": emailController.text.trim(),
        "role": selectedRole,
        "createdAt": FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("$selectedRole registered successfully!")),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}"), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Register New User")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Full Name", prefixIcon: Icon(Icons.person)),
                validator: (v) => v!.isEmpty ? "Enter name" : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(labelText: "Email", prefixIcon: Icon(Icons.email)),
                validator: (v) => v!.isEmpty ? "Enter email" : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Password", prefixIcon: Icon(Icons.lock)),
                validator: (v) => v!.length < 6 ? "Min 6 characters" : null,
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField(
                value: selectedRole,
                items: ["student", "admin"].map((role) => 
                  DropdownMenuItem(value: role, child: Text(role.toUpperCase()))).toList(),
                onChanged: (val) => setState(() => selectedRole = val.toString()),
                decoration: const InputDecoration(labelText: "Assign Role"),
              ),
              const SizedBox(height: 30),
              isLoading 
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: registerNewUser,
                    style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                    child: const Text("CREATE ACCOUNT"),
                  ),],
          ),
        ),
      ),
    );
  }
}