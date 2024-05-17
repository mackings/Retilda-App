import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class ToggleButtonsWidget extends StatefulWidget {
  final String firstButtonText;
  final String secondButtonText;
  final Function(bool isFirstButtonActive) onToggle;
  final Function(int chipValue, bool isFirstButtonActive) onChipSelected;

  const ToggleButtonsWidget({
    Key? key,
    required this.firstButtonText,
    required this.secondButtonText,
    required this.onToggle,
    required this.onChipSelected,
  }) : super(key: key);

  @override
  _ToggleButtonsWidgetState createState() => _ToggleButtonsWidgetState();
}

class _ToggleButtonsWidgetState extends State<ToggleButtonsWidget> {
  bool? isFirstButtonActive;
  int? selectedChipValue;

  void _toggleButtons(bool isFirst) {
    setState(() {
      isFirstButtonActive = isFirst;
    });
    widget.onToggle(isFirst);
  }

  List<int> getChips() {
    if (isFirstButtonActive == true) {
      return [4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24, 26, 28, 30, 32, 34, 36, 38, 40];
    } else if (isFirstButtonActive == false) {
      return [2, 4, 6, 8, 10, 12];
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    List<int> chips = getChips();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              GestureDetector(
                onTap: () => _toggleButtons(true),
                child: Container(
                  height: 6.h,
                  width: 40.w,
                  decoration: BoxDecoration(
                    color: isFirstButtonActive == true ? Colors.orange : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.orange, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      widget.firstButtonText,
                      style: TextStyle(
                        color: isFirstButtonActive == true ? Colors.white : Colors.orange,
                        fontSize: 12.sp,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 4.w),
              GestureDetector(
                onTap: () => _toggleButtons(false),
                child: Container(
                  height: 6.h,
                  width: 40.w,
                  decoration: BoxDecoration(
                    color: isFirstButtonActive == false ? Colors.orange : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.orange, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      widget.secondButtonText,
                      style: TextStyle(
                        color: isFirstButtonActive == false ? Colors.white : Colors.orange,
                        fontSize: 12.sp,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (isFirstButtonActive != null)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: chips.map((chipValue) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedChipValue = chipValue;
                    });
                    widget.onChipSelected(chipValue, isFirstButtonActive!);
                  },
                  child: Chip(
                    label: Text(chipValue.toString()),
                    backgroundColor: chipValue == selectedChipValue ? Colors.orange : Colors.white,
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}
