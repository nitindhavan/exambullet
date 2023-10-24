import 'package:exambullet/screens/result_screen.dart';
import 'package:flutter/material.dart';

import '../models/question_model.dart';
import '../models/test_model.dart';

class ScoreScreen extends StatefulWidget {
  const ScoreScreen({Key? key, required this.testModel, required this.selection, required this.questions}) : super(key: key);

  final TestModel testModel;
  final List<int> selection;
  final List<Question> questions;

  @override
  State<ScoreScreen> createState() => _ScoreScreenState();
}

class _ScoreScreenState extends State<ScoreScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Yor Score'),),
      body: Center(
        child: Container(
          width: 300,
          height: 250,
          child: Column(
            children: [
              Expanded(
                child: Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(width: 200,),
                      SizedBox(height: 32,),
                      Text("Your Score",style: TextStyle(fontSize: 16,color: Colors.black),),
                      SizedBox(height: 32,),
                      Expanded(child: Text('${getScore()}',style: TextStyle(fontSize: 32),textAlign: TextAlign.center,))
                    ],
                  ),
                ),
              ),
              GestureDetector(
                onTap: (){
                  Navigator.push(context, MaterialPageRoute(builder: (context)=> ResultScreen(testModel: widget.testModel, selection: widget.selection, questions: widget.questions)));
                },
                child: Container(
                  width: double.infinity,
                  height: 60,
                  alignment: Alignment.center,
                  child: const Text('Show Answers',style: TextStyle(color: Color(0xff3D1975)),),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  String getScore() {
    int total=0;
    int obtained=0;
    int index=0;
    for(Question question in widget.questions){
      total+=question.marks;
      if(widget.selection[index]==question.answer) obtained+=question.marks;
      index++;
    }
    return '${obtained} / $total';
  }
}
