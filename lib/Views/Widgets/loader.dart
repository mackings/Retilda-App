import 'package:flutter/material.dart';
import 'package:retilda/Views/Widgets/components.dart';

class ButtonLoader extends StatelessWidget {
  final bool isLoading;

  ButtonLoader({required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? Container(
            height: 50,
            width: 50,
            child: Stack(
              children: [
                SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(RButtoncolor),
                  ),
                ),
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: 10,
                      height: 10,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(RButtoncolor),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
        : SizedBox(); // Return an empty SizedBox when not loading
  }
}
