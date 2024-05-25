import 'package:flutter/material.dart';
import 'package:dots_indicator/dots_indicator.dart';
import 'package:retilda/Views/Widgets/components.dart';
import 'package:sizer/sizer.dart';

class CarouselPageView extends StatefulWidget {
  @override
  _CarouselPageViewState createState() => _CarouselPageViewState();
}

class _CarouselPageViewState extends State<CarouselPageView> {
  final PageController _controller = PageController();
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [

        Padding(
          padding: const EdgeInsets.only(top: 20,left: 20,right: 20),
          child: Container(
            height: 22.h,
            child: PageView(
              controller: _controller,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              children: [
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Container(
                    height: 20.h,
                  decoration: BoxDecoration(
                    image: DecorationImage(image: AssetImage("assets/f4.jpg",
                    ),
                    fit: BoxFit.fill
                    ),
                   // color: Colors.blue,
                    borderRadius: BorderRadius.circular(15)
                  ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Container(height: 20.h,
                  decoration: BoxDecoration(
                   image: DecorationImage(image: AssetImage("assets/f3.jpg",
                    ),
                    fit: BoxFit.fill
                    ),
                    borderRadius: BorderRadius.circular(15)
                  ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Container(height: 20.h,
                  decoration: BoxDecoration(
                   image: DecorationImage(image: AssetImage("assets/f1.jpg",
                    ),
                    fit: BoxFit.fill
                    ),
                    borderRadius: BorderRadius.circular(15)
                  ),
                  ),
                ),
              ],
            ),
          ),
        ),
        DotsIndicator(
          dotsCount: 3, 
          position: _currentIndex, 
          decorator: DotsDecorator(
            size: Size(10.0, 10.0),
            activeSize: Size(20.0, 10.0),
            color: Colors.grey, 
            activeColor: Colors.black, 
            spacing: EdgeInsets.all(5.0),
          ),
        ),
      ],
    );
  }
}
