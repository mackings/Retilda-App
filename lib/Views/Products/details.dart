import 'package:flutter/material.dart';
import 'package:retilda/Views/Widgets/components.dart';
import 'package:retilda/Views/Widgets/togglebtn.dart';
import 'package:retilda/Views/Widgets/widgets.dart';
import 'package:retilda/model/products.dart';
import 'package:sizer/sizer.dart';


class ProductDetails extends StatefulWidget {
  final Product product;

  const ProductDetails({Key? key, required this.product}) : super(key: key);

  @override
  State<ProductDetails> createState() => _ProductDetailsState();
}

class _ProductDetailsState extends State<ProductDetails> {
  bool isFirstButtonActive = true;
  int? selectedChipValue;

  void handleToggle(bool isFirstButtonActive) {
    setState(() {
      this.isFirstButtonActive = isFirstButtonActive;
      selectedChipValue = null; 
    });
  }

  void handleChipSelected(int chipValue, bool isFirstButtonActive) {
    setState(() {
      selectedChipValue = chipValue;
    });
    print('Selected Chip: $chipValue, Is First Button Active: $isFirstButtonActive');
  }

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, deviceType) {
        return Scaffold(
          appBar: AppBar(
            title: Text("Product Details"),
          ),
          body: SingleChildScrollView(
            child: Center(
              child: Column(
                children: [
                  SizedBox(
                    height: 2.h,
                  ),
                  SizedBox(
                    height: 30.h,
                    child: PageView(
                      children: widget.product.images.map((image) {
                        return Container(
                          margin: EdgeInsets.symmetric(horizontal: 35.0, vertical: 2),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.transparent,
                            image: DecorationImage(
                              image: NetworkImage(image),
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 25, right: 25, top: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CustomText(
                          widget.product.name,
                          fontWeight: FontWeight.w400,
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.add_shopping_cart),
                              onPressed: () {},
                            ),
                            IconButton(
                              icon: Icon(Icons.favorite_border),
                              onPressed: () {
                                // Favorite action
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.share),
                              onPressed: () {
                                // Share action
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 25, right: 25, top: 5),
                    child: Divider(
                      color: Colors.grey,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 25, right: 25, top: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CustomText(
                          "N${widget.product.price}",
                          fontWeight: FontWeight.w700,
                          fontSize: 12.sp,
                        ),
                        Container(
                          height: 6.h,
                          width: 50.w,
                          decoration: BoxDecoration(
                            color: ROrange,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: CustomText(
                 "Buy Now",
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                                    Padding(
                    padding: const EdgeInsets.only(left: 25, top: 20),
                    child: Row(
                      children: [
                        CustomText(
                          "Select desired Payment frequency",
                          fontSize: 12.sp,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 2.h,),

                  ToggleButtonsWidget(
                    firstButtonText: 'Weekly',
                    secondButtonText: 'Monthly',
                    onToggle: handleToggle,
                    onChipSelected: handleChipSelected,
                  ),

                  if (selectedChipValue != null)
Padding(
  padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
  child: Row(
    children: [
      Icon(Icons.error, color: ROrange,),
      SizedBox(width: 2.w),
      Flexible(
        child: CustomText(
          'You Selected: ${isFirstButtonActive ? "Weekly" : "Monthly"} Payments and ${selectedChipValue != null ? selectedChipValue.toString() : "No days selected"} ${isFirstButtonActive ? "Weeks" : "Months"}',
        ),
      ),
    ],
  ),
),


                ]
            ),
          ),
        ),
        );
      }
    );
      }  
  }

                  
