import 'package:exambullet/models/question_model.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../models/test_model.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({Key? key, required this.testModel, required this.selection, required this.questions}) : super(key: key);

  final TestModel testModel;
  final List<int> selection;
  final List<Question> questions;
  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  int current = 0;
  List<int> selectedList = [];

  List<Question> questionList = [];


  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    selectedList=widget.selection;
    questionList=widget.questions;
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(widget.testModel.name),
          ],
        ),
      ),
      body: FutureBuilder(
        builder: (BuildContext context, AsyncSnapshot<DatabaseEvent> snapshot) {
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
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Image.network(questionList[current].imageUrl),
              ),
              Row(
                children: [
                  Expanded(
                      child: Container(
                          height: 60,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                              color: questionList[current].answer ==1 ? Colors.green : selectedList[current] == 1
                                  ? questionList[current].answer==1 ? Colors.green : Colors.red
                                  : Colors.white60),
                          margin: EdgeInsets.all(16),
                          child: Text(
                            'A',
                            style: TextStyle(
                                color: selectedList[current] == 1
                                    ? Colors.white
                                    : Colors.black),
                          ))),
                  Expanded(
                      child: Container(
                          height: 60,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                              color: questionList[current].answer ==2 ? Colors.green : selectedList[current] == 2
                                  ? questionList[current].answer==2 ? Colors.green : Colors.red
                                  : Colors.white60),
                          margin: EdgeInsets.all(16),
                          child: Text(
                            'B',
                            style: TextStyle(
                                color: selectedList[current] == 2
                                    ? Colors.white
                                    : Colors.black),
                          ))),
                  Expanded(
                      child: Container(
                          height: 60,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                              color: questionList[current].answer ==3 ? Colors.green : selectedList[current] == 3
                                  ? questionList[current].answer==3 ? Colors.green : Colors.red
                                  : Colors.white60),
                          margin: const EdgeInsets.all(16),
                          child: Text(
                            'C',
                            style: TextStyle(
                                color: selectedList[current] == 3
                                    ? Colors.white
                                    : Colors.black),
                          ))),
                  Expanded(
                      child: Container(
                          height: 60,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                              color: questionList[current].answer ==4 ? Colors.green : selectedList[current] == 4
                                  ? questionList[current].answer==4 ? Colors.green : Colors.red
                                  : Colors.white60),
                          margin: EdgeInsets.all(16),
                          child: Text(
                            'D',
                            style: TextStyle(
                                color: selectedList[current] == 4
                                    ? Colors.white
                                    : Colors.black),
                          ))),
                ],
              )
            ],
          );
        },
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
                },child: Container(decoration: BoxDecoration(color: current==index ? Color(0xff3D1975) : selectedList[index] != -1 ? questionList[index].answer == selectedList[index] ? Colors.green : Colors.red : Colors.white,borderRadius: BorderRadius.circular(10)),height: 60,width: 60,alignment: Alignment.center,child: Text('${index+1}',style: TextStyle(color: current==index ? Colors.white : Colors.black ),),margin: EdgeInsets.all(8),));
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
