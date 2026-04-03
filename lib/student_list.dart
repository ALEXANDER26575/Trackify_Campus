import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentListScreen extends StatefulWidget {
  const StudentListScreen({super.key});

  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  String searchQuery = "";

  // 🛡️ DELETE FUNCTION (With Confirmation)
  Future<void> confirmDeleteStudent(String id, String name) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Remove Student?"),
        content: Text("Are you sure you want to delete '$name' from the directory? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await FirebaseFirestore.instance.collection('users').doc(id).delete();
              if (!mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Student record deleted")),
              );
            },
            child: const Text("DELETE", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Student Directory", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF240b36), Color(0xFFc31432)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 🔍 SEARCH BAR
              Padding(
                padding: const EdgeInsets.all(15),
                child: TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Search name or email...",
                    hintStyle: const TextStyle(color: Colors.white70),
                    prefixIcon: const Icon(Icons.search, color: Colors.white),
                    filled: true,
                    fillColor: Colors.black.withOpacity(0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (val) => setState(() => searchQuery = val.toLowerCase()),
                ),
              ),

              // 👥 STUDENT LIST
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .where('role', isEqualTo: 'student')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Center(child: Text("Error loading data", style: TextStyle(color: Colors.white)));
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Colors.white));
                    }

                    // Filter Logic with Safety Checks
                    var studentDocs = snapshot.data!.docs.where((doc) {
                      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                      String name = data.containsKey('name') ? data['name'].toString().toLowerCase() : "unknown";
                      String email = data.containsKey('email') ? data['email'].toString().toLowerCase() : "no email";
                      return name.contains(searchQuery) || email.contains(searchQuery);
                    }).toList();

                    if (studentDocs.isEmpty) {
                      return const Center(child: Text("No students found", style: TextStyle(color: Colors.white70)));
                    }

                    return ListView.builder(
                      itemCount: studentDocs.length,
                      itemBuilder: (context, index) {
                        var doc = studentDocs[index];
                        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

                        // UI Safety Checks
                        String studentName = data.containsKey('name') ? data['name'] : "Unknown Student";
                        String studentEmail = data.containsKey('email') ? data['email'] : "No Email";

                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFF240b36),
                              child: Text(
                                studentName.isNotEmpty ? studentName[0].toUpperCase() : "?",
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(studentName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(studentEmail),
                            // 🗑️ DELETE BUTTON
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                              onPressed: () => confirmDeleteStudent(doc.id, studentName),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}