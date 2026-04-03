import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import 'login.dart';

class StudentDashboard extends StatefulWidget {
  final VoidCallback toggleTheme;
  const StudentDashboard({super.key, required this.toggleTheme});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  String searchQuery = "";
  String filterType = "All";

  void logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen(toggleTheme: widget.toggleTheme)),
    );
  }

  // ⏳ COUNTDOWN LOGIC (Fixed for yyyy-MM-dd format)
  String getCountdown(String dateStr) {
    try {
      DateTime eventDate = DateTime.parse(dateStr);
      DateTime now = DateTime.now();
      DateTime today = DateTime(now.year, now.month, now.day);
      int days = eventDate.difference(today).inDays;

      if (days < 0) return "Passed";
      if (days == 0) return "Today";
      return "$days days left";
    } catch (e) {
      return "";
    }
  }

  IconData getIcon(String type) {
    switch (type) {
      case "Exam": return Icons.school;
      case "Assignment": return Icons.assignment;
      case "Holiday": return Icons.beach_access;
      default: return Icons.event;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Student Dashboard", style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.dark_mode), onPressed: widget.toggleTheme),
          IconButton(icon: const Icon(Icons.logout), onPressed: () => logout(context)),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF240b36), Color(0xFFc31432)], // Dark Theme Gradient
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection("events")
                .orderBy("date", descending: false)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.white));

              var allDocs = snapshot.data!.docs;

              // Calculate Stats
              int total = allDocs.length;
              int exams = allDocs.where((e) => e["type"] == "Exam").length;
              int tasks = allDocs.where((e) => e["type"] == "Assignment").length;
              int holidays = allDocs.where((e) => e["type"] == "Holiday").length;

              // Filter & Search Logic
              var filteredDocs = allDocs.where((doc) {
                bool matchesSearch = doc["title"].toString().toLowerCase().contains(searchQuery.toLowerCase());
                bool matchesFilter = filterType == "All" || doc["type"] == filterType;
                return matchesSearch && matchesFilter;
              }).toList();

              return SingleChildScrollView(
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 📊 STAT BOXES
                    Row(
                      children: [
                        statBox("Total", total, Icons.event, Colors.blue),
                        const SizedBox(width: 8),
                        statBox("Exams", exams, Icons.school, Colors.green),
                        const SizedBox(width: 8),// FIXED: Changed Icons.orange to Icons.assignment
                        statBox("Tasks", tasks, Icons.assignment, Colors.orange), 
                        const SizedBox(width: 8),
                        statBox("Holidays", holidays, Icons.beach_access, Colors.purple),
                      ],
                    ),
                    const SizedBox(height: 25),

                    // 🔍 SEARCH BAR
                    TextField(
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Search updates...",
                        hintStyle: const TextStyle(color: Colors.white70),
                        prefixIcon: const Icon(Icons.search, color: Colors.white),
                        filled: true,
                        fillColor: Colors.black.withOpacity(0.3),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                      ),
                      onChanged: (val) => setState(() => searchQuery = val),
                    ),
                    const SizedBox(height: 10),

                    // 🏷 FILTER CHIPS
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ["All", "Exam", "Assignment", "Holiday"].map((type) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(type),
                              selected: filterType == type,
                              selectedColor: Colors.white,
                              labelStyle: TextStyle(color: filterType == type ? Colors.black : Colors.white),
                              backgroundColor: Colors.white.withOpacity(0.1),
                              onSelected: (val) => setState(() => filterType = type),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),

                    const Text("Campus Updates", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),

                    // 📋 LIST OF UPDATES
                    filteredDocs.isEmpty
                        ? const Center(child: Text("No records found", style: TextStyle(color: Colors.white70)))
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filteredDocs.length,
                            itemBuilder: (context, index) {
                              var data = filteredDocs[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.blue.withOpacity(0.1),
                                    child: Icon(getIcon(data["type"]), color: Colors.blue),
                                  ),
                                  title: Text(data["title"], style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text("${data["type"]} • ${data["date"]} • ${data["time"]}"),
                                  trailing: Text(
                                    getCountdown(data["date"]),
                                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ),
                              );},
                          ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget statBox(String title, int count, IconData icon, Color iconColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.4),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(height: 5),
            Text("$count", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            Text(title, style: const TextStyle(color: Colors.white70, fontSize: 10), overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}