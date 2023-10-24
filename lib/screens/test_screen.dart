import 'package:exambullet/models/question_model.dart';
import 'package:exambullet/screens/result_screen.dart';
import 'package:exambullet/screens/score_screen.dart';
import 'package:exambullet/widgets/timer.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../models/test_model.dart';

class TestScreen extends StatefulWidget {
  const TestScreen({Key? key, required this.testModel}) : super(key: key);

  final TestModel testModel;
  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  int current = 0;
  List<int> selectedList = [];

  List<Question> questionList = [];


  String time="00:00:00";
  
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(widget.testModel.name),
            GestureDetector(onTap: (){
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=> ScoreScreen(selection : selectedList, questions : questionList, testModel: widget.testModel,)));
            },child: Text('Finish',style: TextStyle(fontSize: 14),))
          ],
        ),
      ),
      body: FutureBuilder(
        builder: (BuildContext context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (!snapshot.hasData)
            return Center(
              child: CircularProgressIndicator(),
            );
          questionList.clear();
          // selectedList.clear();
          for (DataSnapshot snap in snapshot.data!.snapshot.children) {
            Question question = Question.fromMap(snap.value as Map);
            questionList.add(question);
            selectedList.add(-1);
          }
          return Column(
            children: [
              Row(
                children: [
                  Container(
                    height: 50,
                    width: 50,
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(50)),
                    child: GestureDetector(
                        onTap: () {
                          setState(() {
                            if (current > 0) {
                              current--;
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("This is the first question "),
                                ),
                              );
                            }
                          });
                        },
                        child: Icon(Icons.arrow_back_ios)),
                  ),
                  Expanded(
                      child: Container(
                    height: 60,
                    alignment: Alignment.center,
                    child: Text(
                      'Question ${current + 1} of ${questionList.length}',
                      textAlign: TextAlign.center,
                    ),
                  )),
                  Container(
                    height: 50,
                    width: 50,
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(50)),
                    child: GestureDetector(
                        onTap: () {
                          setState(() {
                            if (current < questionList.length - 1) {
                              current++;
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("This is the Last question "),
                                ),
                              );
                            }
                          });
                        },
                        child: Icon(Icons.arrow_forward_ios)),
                  ),
                ],
              ),
              TimerWidget(totalTime: widget.testModel.time,onFinish: (){
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=> ScoreScreen(selection : selectedList, questions : questionList, testModel: widget.testModel,)));
              },),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Image.network(questionList[current].imageUrl),
              ),
              Row(
                children: [
                  Expanded(
                      child: GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedList[current] = 1;
                            });
                          },
                          child: Container(
                              height: 60,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                  color: selectedList[current] == 1
                                      ? Color(0xff3D1975)
                                      : Colors.white60),
                              margin: EdgeInsets.all(16),
                              child: Text(
                                'A',
                                style: TextStyle(
                                    color: selectedList[current] == 1
                                        ? Colors.white
                                        : Colors.black),
                              )))),
                  Expanded(
                      child: GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedList[current] = 2;
                            });
                          },
                          child: Container(
                              height: 60,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                  color: selectedList[current] == 2
                                      ? Color(0xff3D1975)
                                      : Colors.white60),
                              margin: EdgeInsets.all(16),
                              child: Text(
                                'B',
                                style: TextStyle(
                                    color: selectedList[current] == 2
                                        ? Colors.white
                                        : Colors.black),
                              )))),
                  Expanded(
                      child: GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedList[current] = 3;
                            });
                          },
                          child: Container(
                              height: 60,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                  color: selectedList[current] == 3
                                      ? Color(0xff3D1975)
                                      : Colors.white60),
                              margin: const EdgeInsets.all(16),
                              child: Text(
                                'C',
                                style: TextStyle(
                                    color: selectedList[current] == 3
                                        ? Colors.white
                                        : Colors.black),
                              )))),
                  Expanded(
                      child: GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedList[current] = 4;
                            });
                          },
                          child: Container(
                              height: 60,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                  color: selectedList[current] == 4
                                      ? Color(0xff3D1975)
                                      : Colors.white60),
                              margin: EdgeInsets.all(16),
                              child: Text(
                                'D',
                                style: TextStyle(
                                    color: selectedList[current] == 4
                                        ? Colors.white
                                        : Colors.black),
                              )))),
                ],
              )
            ],
          );
        },
        future: FirebaseDatabase.instance
            .ref()
            .child('questions')
            .orderByChild('testId')
            .equalTo(widget.testModel.id)
            .once(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            showModalBottomSheet(context: context, builder: (BuildContext context) {
              return GridView.builder(gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5), itemBuilder: (BuildContext context, int index) {
                return GestureDetector(onTap: (){
                  setState(() {
                    current=index;
                    Navigator.pop(context);
                  });
                },child: Container(decoration: BoxDecoration(color: current==index ? Color(0xff3D1975) : selectedList[index] != -1 ? Colors.green : Colors.white,borderRadius: BorderRadius.circular(10)),height: 60,width: 60,alignment: Alignment.center,child: Text('${index+1}',style: TextStyle(color: current==index ? Colors.white : Colors.black ),),margin: EdgeInsets.all(8),));
              },itemCount: questionList.length,);
            },backgroundColor: Color(0xffF6F2FF));
          });
        },
        child: Icon(Icons.arrow_drop_up),
        backgroundColor: Color(0xff3D1975),
      ),
    );
  }
}
