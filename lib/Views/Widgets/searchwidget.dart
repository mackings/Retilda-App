import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:retilda/Views/Widgets/components.dart';

class SearchContainer extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onFilterPressed;

  const SearchContainer({
    Key? key,
    required this.controller,
    required this.onFilterPressed,
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

          SizedBox(width: 10.0),

          Container(
            decoration: BoxDecoration(
              color: Colors.transparent,
              border: Border.all(color: ROrange),
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: IconButton(
              icon: Icon(Icons.filter_list),
              onPressed: onFilterPressed,
            ),
          ),
        ],
      ),
    );
  }
}
