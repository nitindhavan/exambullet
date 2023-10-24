import 'package:flutter/material.dart';
class Button extends StatelessWidget {
  const Button({Key? key,required this.onPressed,required this.text}) : super(key: key);
  final Function() onPressed;
  final String text;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        alignment: Alignment.center,
        margin: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Color(0xff3D1975),
          borderRadius: BorderRadius.circular(10),
        ),
        height: 60,
        child: Text(
          text,style: TextStyle(color: Colors.white,fontSize: 16),),
      ),
    );
  }
}
