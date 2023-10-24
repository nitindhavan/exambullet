import 'package:flutter/material.dart';
class Heading extends StatelessWidget {
  const Heading({Key? key,required this.heading}) : super(key: key);

  final String heading;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(16),
      child: Text(heading,style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold,),),
    );
  }
}
