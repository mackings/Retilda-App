import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:retilda/Views/Widgets/components.dart';
import 'package:retilda/Views/Widgets/widgets.dart';
import 'package:sizer/sizer.dart';

class DeliveryModal extends StatefulWidget {
  @override
  _DeliveryModalState createState() => _DeliveryModalState();
}

class _DeliveryModalState extends State<DeliveryModal> {
  final _addressController = TextEditingController();
  final _dateController = TextEditingController();
  final List<String> _timeSlots = [
    '08:00 AM - 10:00 AM',
    '10:00 AM - 12:00 PM',
    '12:00 PM - 02:00 PM',
    '02:00 PM - 04:00 PM',
    '04:00 PM - 06:00 PM',
    '06:00 PM - 08:00 PM'
  ];
  String? _selectedTimeSlot;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Icon(Icons.close)),
              ),

              SizedBox(
                height: 15,
              ),
              Row(
                children: [
                  CustomText(
                    "Your Item Delivery",
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  SizedBox(
                    width: 5,
                  ),
                  Icon(Icons.location_history)
                ],
              ),
              SizedBox(
                height: 25,
              ),
              Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(width: 0.5, color: Colors.black)),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    maxLines: 2,
                    controller: _addressController,
                    decoration: InputDecoration( 
                        border: InputBorder.none,
                        hintText: "Enter Delivery Address",
                        hintStyle: GoogleFonts.poppins()),
                  ),
                ),
              ),
              SizedBox(height: 16.0),
              GestureDetector(
                onTap: () => _selectDate(context),
                child: AbsorbPointer(
                  child: Container(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(width: 0.5, color: Colors.black)),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextFormField(
                        controller: _dateController,
                        decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: "Select  Delivery Date ",
                            suffixIcon: Icon(
                              Icons.calendar_today,
                            ),
                            hintStyle: GoogleFonts.poppins()),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16.0),

              Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(width: 0.5, color: Colors.black)),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                        hintText: "Select Time slots",
                        hintStyle: GoogleFonts.poppins(),
                        border: InputBorder.none),
                    value: _selectedTimeSlot,
                    items: _timeSlots.map((String slot) {
                      return DropdownMenuItem<String>(
                        value: slot,
                        child: CustomText(slot),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _selectedTimeSlot = newValue;
                      });
                    },
                  ),
                ),
              ),
              SizedBox(height: 29.0),

              CustomBtn(
                text: "Request delivery",
                backgroundColor: RButtoncolor,
                ),

              // ElevatedButton(
              //   onPressed: () {
              //     // Handle form submission
              //     print('Delivery Address: ${_addressController.text}');
              //     print('Delivery Date: ${_dateController.text}');
              //     print('Delivery Time Slot: $_selectedTimeSlot');
              //     Navigator.pop(context);
              //   },
              //   child: Text('Submit'),
              // ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _addressController.dispose();
    _dateController.dispose();
    super.dispose();
  }
}
