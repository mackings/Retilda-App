import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class SliderWidget extends StatelessWidget {
  final List<SliderItem> items;

  SliderWidget({required this.items});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: 1, // We only want one row
      itemBuilder: (context, index) {
        return RowOfContainers(items: items);
      },
    );
  }
}

class RowOfContainers extends StatelessWidget {
  final List<SliderItem> items;

  RowOfContainers({required this.items});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: items.map((item) {
        return Container(
          margin: EdgeInsets.all(10),
          width: MediaQuery.of(context).size.width / 3,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 20.h, 
                height: 20.w, 
                child: Image.asset(
                  item.imagePath,
                  fit: BoxFit.cover, 
                ),
             decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10)
          ),
              ),
              SizedBox(height: 10),
              Text(item.text),
            ],
          ),
        );
      }).toList(),
    );
  }
}


class SliderItem {
  final String imagePath;
  final String text;

  SliderItem({required this.imagePath, required this.text});
}
