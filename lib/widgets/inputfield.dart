import 'package:flutter/material.dart';
class InputField extends StatelessWidget {
  InputField({Key? key,required this.controller,required this.hint,this.icon}) : super(key: key);

  final TextEditingController controller;
  final String hint;
  IconData? icon;
  @override
  Widget build(BuildContext context) {
    return  Container(
      padding: EdgeInsets.only(left: 8,right: 8),
      alignment: Alignment.centerLeft,
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      height: 60,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          icon: Icon(icon)
        ),
      ),
    );
  }
}
