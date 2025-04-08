import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:retilda/Views/Widgets/widgets.dart';
import 'package:sizer/sizer.dart';

class ToggleButtonsWidget extends StatefulWidget {
  final String firstButtonText;
  final String secondButtonText;
  final Function(bool isFirstButtonActive) onToggle;
  final Function(int chipValue, bool isFirstButtonActive) onChipSelected;
  final Function(String action, int chipValue, bool isFirstButtonActive) onActionSelected;

  const ToggleButtonsWidget({
    Key? key,
    required this.firstButtonText,
    required this.secondButtonText,
    required this.onToggle,
    required this.onChipSelected,
    required this.onActionSelected,
  }) : super(key: key);

  @override
  _ToggleButtonsWidgetState createState() => _ToggleButtonsWidgetState();
}

class _ToggleButtonsWidgetState extends State<ToggleButtonsWidget> {
  bool? isFirstButtonActive;
  int? selectedChipValue;

  void _toggle(bool isFirst) {
    setState(() {
      isFirstButtonActive = isFirst;
      selectedChipValue = null;
    });
    widget.onToggle(isFirst);
  }

  List<int> getChips() {
    return isFirstButtonActive == true
        ? [4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24, 26, 28, 30, 32, 34, 36, 38, 40]
        : isFirstButtonActive == false
            ? [2, 4, 6, 8, 10, 12]
            : [];
  }

  @override
  Widget build(BuildContext context) {
    final chips = getChips();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Toggle Buttons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _toggle(true),
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 200),
                    padding: EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isFirstButtonActive == true ? Colors.black : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black),
                    ),
                    child: Center(
                      child: Text(
                        widget.firstButtonText,
                        style: TextStyle(
                          color: isFirstButtonActive == true ? Colors.white : Colors.black,
                          fontWeight: FontWeight.w600,
                          fontSize: 12.sp,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 16),
              
              Expanded(
                child: GestureDetector(
                  onTap: () => _toggle(false),
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 200),
                    padding: EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isFirstButtonActive == false ? Colors.black : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black),
                    ),
                    child: Center(
                      child: Text(
                        widget.secondButtonText,
                        style: TextStyle(
                          color: isFirstButtonActive == false ? Colors.white : Colors.black,
                          fontWeight: FontWeight.w600,
                          fontSize: 12.sp,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Chips
        if (isFirstButtonActive != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: chips.map((chipValue) {
                final isSelected = chipValue == selectedChipValue;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedChipValue = chipValue;
                    });
                    widget.onChipSelected(chipValue, isFirstButtonActive!);
                  },
                  child: Chip(
                    label: Text(
                      chipValue.toString(),
                      style: GoogleFonts.poppins(
                        color: isSelected ? Colors.white : Colors.black,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    backgroundColor: isSelected ? Colors.black : Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}

