import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'login.dart';
import 'register_user.dart';
import 'student_list.dart';

class AdminDashboard extends StatefulWidget {
  final VoidCallback toggleTheme;
  const AdminDashboard({super.key, required this.toggleTheme});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController timeController = TextEditingController();

  String selectedType = "Exam";
  String filterType = "All";
  String searchQuery = "";
  String? editingId; // Tracks if we are in Edit Mode

  // --- LOGIC FUNCTIONS ---

  void logout() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen(toggleTheme: widget.toggleTheme)),
    );
  }

  Future<void> pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => dateController.text = DateFormat('yyyy-MM-dd').format(picked));
    }
  }

  Future<void> pickTime() async {
    TimeOfDay? picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked != null) setState(() => timeController.text = picked.format(context));
  }

  void prepareEdit(DocumentSnapshot doc) {
    setState(() {
      editingId = doc.id;
      titleController.text = doc['title'];
      dateController.text = doc['date'];
      timeController.text = doc['time'];
      selectedType = doc['type'];
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Editing mode active")));
  }

  Future<void> saveOrUpdate() async {
    if (_formKey.currentState!.validate()) {
      final data = {
        "title": titleController.text.trim(),
        "date": dateController.text,
        "time": timeController.text,
        "type": selectedType,
        "timestamp": FieldValue.serverTimestamp(),
      };

      if (editingId == null) {
        await FirebaseFirestore.instance.collection("events").add(data);
      } else {
        await FirebaseFirestore.instance.collection("events").doc(editingId).update(data);
        setState(() => editingId = null);
      }

      titleController.clear();
      dateController.clear();
      timeController.clear();
      FocusScope.of(context).unfocus();
    }
  }

  Future<void> confirmDelete(String id, String title) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Event?"),
        content: Text("Are you sure you want to delete '$title'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              FirebaseFirestore.instance.collection("events").doc(id).delete();
              Navigator.pop(context);
            },
            child: const Text("DELETE", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- UI COMPONENTS ---

  Widget statBox(String title, int count, IconData icon, Color iconColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.4),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(height: 5),
            Text("$count", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            Text(title, style: const TextStyle(color: Colors.white70, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(editingId == null ? "Admin Panel" : "Edit Event"),
        actions: [
          // 👥 Student List
          IconButton(
            icon: const Icon(Icons.group),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentListScreen())),
          ),
          // ➕ Register User
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterUserScreen())),
          ),
          // 🌙 Theme & 🚪 Logout
          IconButton(icon: const Icon(Icons.dark_mode), onPressed: widget.toggleTheme),
          IconButton(icon: const Icon(Icons.logout), onPressed: logout),
        ],
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
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection("events").orderBy("date").snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.white));

              var allDocs = snapshot.data!.docs;
              var filteredDocs = allDocs.where((doc) {
                bool matchesSearch = doc["title"].toString().toLowerCase().contains(searchQuery);
                bool matchesFilter = filterType == "All" || doc["type"] == filterType;
                return matchesSearch && matchesFilter;
              }).toList();

              return SingleChildScrollView(
                padding: const EdgeInsets.all(15),
                child: Column(
                  children: [
                    // 📊 STATS ROW
                    Row(
                      children: [
                        statBox("Total", allDocs.length, Icons.event, Colors.blue),
                        const SizedBox(width: 8),
                        statBox("Exams", allDocs.where((d) => d["type"] == "Exam").length, Icons.school, Colors.green),
                        const SizedBox(width: 8),
                        statBox("Tasks", allDocs.where((d) => d["type"] == "Assignment").length, Icons.assignment, Colors.orange),
                        const SizedBox(width: 8),
                        statBox("Holidays", allDocs.where((d) => d["type"] == "Holiday").length, Icons.beach_access, Colors.purple),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // 📝 FORM CARD
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: editingId != null ? const BorderSide(color: Colors.cyan, width: 2) : BorderSide.none,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              TextFormField(
                                controller: titleController,
                                decoration: const InputDecoration(labelText: "Title", prefixIcon: Icon(Icons.title)),
                                validator: (v) => v!.isEmpty ? "Enter title" : null,
                              ),
                              Row(children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: dateController,
                                      readOnly: true,
                                      onTap: pickDate,
                                      decoration: const InputDecoration(labelText: "Date", prefixIcon: Icon(Icons.calendar_today)),
                                      validator: (v) => v!.isEmpty ? "Select date" : null,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: TextFormField(
                                      controller: timeController,
                                      readOnly: true,
                                      onTap: pickTime,
                                      decoration: const InputDecoration(labelText: "Time", prefixIcon: Icon(Icons.access_time)),
                                      validator: (v) => v!.isEmpty ? "Select time" : null,
                                    ),
                                  ),
                                ],
                              ),
                              DropdownButtonFormField(
                                value: selectedType,
                                items: ["Exam", "Assignment", "Holiday", "Event"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                                onChanged: (val) => setState(() => selectedType = val.toString()),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: saveOrUpdate,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: editingId == null ? const Color(0xFFc31432) : Colors.cyan,
                                  minimumSize: const Size(double.infinity, 50),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: Text(editingId == null ? "PUBLISH UPDATE" : "SAVE CHANGES", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                              if (editingId != null)
                                TextButton(
                                  onPressed: () => setState(() { editingId = null; titleController.clear(); }),
                                  child: const Text("Cancel Edit"),
                                )
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),

                    // 🔍 SEARCH & FILTERS
                    TextField(
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Search records...",
                        hintStyle: const TextStyle(color: Colors.white70),
                        prefixIcon: const Icon(Icons.search, color: Colors.white),
                        filled: true,
                        fillColor: Colors.black.withOpacity(0.3),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                      ),
                      onChanged: (val) => setState(() => searchQuery = val.toLowerCase()),
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ["All", "Exam", "Assignment", "Holiday"].map((type) {
                          return Padding(padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(type),
                              selected: filterType == type,
                              onSelected: (val) => setState(() => filterType = type),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 📋 EVENT LIST
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredDocs.length,
                      itemBuilder: (context, index) {
                        var data = filteredDocs[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          child: ListTile(
                            title: Text(data["title"], style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text("${data["date"]} • ${data["type"]}"),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => prepareEdit(data)),
                                IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => confirmDelete(data.id, data["title"])),
                              ],
                            ),
                          ),
                        );
                      },
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
}