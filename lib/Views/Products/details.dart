import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retilda/Views/Widgets/components.dart';
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Product Details"),
      ),
      body: Center(
        child: Column(

          children: [
            SizedBox(height: 2.h,),
            SizedBox(
              height: 30.h, 
              child: PageView(
                children: widget.product.images.map((image) {
                  return Container(
                    margin: EdgeInsets.symmetric(horizontal: 25.0,vertical: 2),
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
       padding: const EdgeInsets.only(left: 25,right: 25,top: 10),
       child: Row(
       mainAxisAlignment: MainAxisAlignment.spaceBetween,
       children: [
         Text(
        widget.product.name,
        style: TextStyle(fontWeight: FontWeight.bold),
         ),
         Row(
        children: [
          IconButton(
            icon: Icon(Icons.add_shopping_cart),
            onPressed: () {
           
            },
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
       padding: const EdgeInsets.only(left: 25,right: 25,top: 5),
       child: Divider(
        color: Colors.grey,
       ),
     ),

                 Padding(
              padding: const EdgeInsets.only(left: 25,right: 25,top: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CustomText("Price: \$${widget.product.price}"),

              
              Container(
                height: 7.h,
                width: 50.w,
                decoration: BoxDecoration(
                  color: ROrange,
                  borderRadius: BorderRadius.circular(10)
                ),
                child: Center(child: CustomText("Buy Now",color: Colors.white,))
              ),
                ],
              ),
            ),

          ],
        ),
      ),
    );
  }
}
