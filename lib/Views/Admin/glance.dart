import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:retilda/Views/Admin/Api/service.dart';
import 'package:retilda/Views/Admin/model/model.dart';
import 'package:retilda/Views/Admin/widgets/purchasemodal.dart';



class Glace extends StatefulWidget {
  const Glace({super.key});

  @override
  State<Glace> createState() => _GlaceState();
}

class _GlaceState extends State<Glace> {
  late Future<List<GlanceUser>> _usersFuture;
  List<GlanceUser> _allUsers = [];
  List<GlanceUser> _filteredUsers = [];
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _usersFuture = ApiService.fetchUsers().then((users) {
      users.sort((a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()));
      _allUsers = users;
      _filteredUsers = users;
      return users;
    });

    _searchController.addListener(() {
      final query = _searchController.text.toLowerCase();
      setState(() {
        _filteredUsers = _allUsers.where((user) {
          return user.fullName.toLowerCase().contains(query) ||
              user.email.toLowerCase().contains(query);
        }).toList();
      });
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Sales Dashboard',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // Search bar
            Container(
              padding: EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search users...',
                  border: InputBorder.none,
                  icon: Icon(Icons.search),
                ),
                style: GoogleFonts.poppins(),
              ),
            ),
            SizedBox(height: 12),
            Expanded(
              child: FutureBuilder<List<GlanceUser>>(
                future: _usersFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(
                        child: Text(
                      'Error: ${snapshot.error}',
                      style: GoogleFonts.poppins(),
                    ));
                  } else if (_filteredUsers.isEmpty) {
                    return Center(
                        child: Text(
                      'No users found',
                      style: GoogleFonts.poppins(),
                    ));
                  }

                  return ListView.builder(
                    itemCount: _filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = _filteredUsers[index];
                      return Container(
                        margin: EdgeInsets.symmetric(vertical: 6),
                        padding: EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue.shade100,
                            child: Icon(
                              Icons.person,
                              color: Colors.blue,
                            ),
                          ),
                          title: Text(
                            user.fullName,
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600, fontSize: 15),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.email,
                                style: GoogleFonts.poppins(fontSize: 13),
                              ),

                             Text(
                                user.phone,
                                style: GoogleFonts.poppins(fontSize: 13),
                              ),
                            ],
                          ),
                          trailing: Icon(Icons.arrow_forward_ios),
onTap: () async {
  try {
    final userPurchases = await ApiService.fetchUserPurchases(user.id);

    if (userPurchases.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${user.fullName} has no purchases')),
      );
      return;
    }

    // If user has purchases → show modal
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PurchaseDetailsModal(
        purchases: userPurchases,
        user: user,
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$e')),
    );
  }
},





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
    );
  }
}