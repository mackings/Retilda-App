import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:retilda/Views/Products/Allproducts.dart';
import 'package:retilda/Views/Widgets/components.dart';

class SearchContainer extends StatelessWidget {
  final TextEditingController controller;

  const SearchContainer({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 18.0),
      constraints: BoxConstraints(maxWidth: 500.0), 
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: ROrange),
                  SizedBox(width: 10.0),
                  
                  Expanded(
                    child: TextFormField(
                      onTap: () {
                   Navigator.push(context,
                        MaterialPageRoute(builder: (context) => Allproducts()));
                      },
                      controller: controller,
                      decoration: InputDecoration(
                        hintText: 'Search for Products',
                        hintStyle: GoogleFonts.poppins(
                          color: Colors.grey
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),


        ],
      ),
    );
  }
}
