import 'package:exambullet/main.dart';
import 'package:exambullet/models/User.dart';
import 'package:exambullet/models/exam.dart';
import 'package:exambullet/screens/exams.dart';
import 'package:exambullet/screens/membership_screen.dart';
import 'package:exambullet/screens/test_screen.dart';
import 'package:exambullet/widgets/heading.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../models/test_model.dart';

class Home extends StatefulWidget {
  const Home({Key? key, required this.user}) : super(key: key);

  final UserModel user;
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String selected = 'Test';

  final ScrollController scrollcontroller = new ScrollController();

  bool scroll_visibility = true;

  @override
  void initState() {
    scrollcontroller.addListener(() {
      if (scrollcontroller.position.pixels > 0)
        scroll_visibility = false;
      else
        scroll_visibility = true;

      setState(() {});
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.person,
                  color: Colors.white,
                ),
                SizedBox(
                  width: 16,
                ),
                Text('Hello! ${widget.user.name}'),
              ],
            ),
            Icon(Icons.notifications),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Visibility(
            visible: scroll_visibility,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(height: 16,),
                // GestureDetector(
                //     onTap: () {
                //       Navigator.push(
                //           context,
                //           MaterialPageRoute(
                //               builder: (context) => AllExams(
                //                     model: widget.user,
                //                   )));
                //     },
                //     child: Container(
                //         margin: EdgeInsets.all(16),
                //         child: Text(
                //           'Change',
                //           style:
                //               TextStyle(color: Color(0xff3D1975), fontSize: 16),
                //         ),),),
              ],
            ),
          ),
          FutureBuilder(builder: (BuildContext context, AsyncSnapshot<DatabaseEvent> snapshot) {
            if(!snapshot.hasData) return LinearProgressIndicator();
            ExamModel model=ExamModel.fromMap(snapshot.data!.snapshot.value as Map);
            return Visibility(
              visible: scroll_visibility,
              child: Card(
                margin: EdgeInsets.only(left: 16, right: 16),
                color: Colors.white,
                child: Container(
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                          child: Image.network(
                            model.icon,
                            height: 100,
                            width: 100,
                          )),
                      Expanded(
                        child: Container(
                          margin: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                model.name,
                                style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 8,),
                              Text(model.about,maxLines: 4,),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },future: FirebaseDatabase.instance.ref('exams').child(origin!).once(),),
          Container(
              margin: EdgeInsets.all(16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    menu('Test'),
                    // menu('Quiz\'s'),
                    // menu('Videos from Youtube'),
                    // menu('Competitions'),
                    // menu('Question Papers'),
                    // menu('PDF books'),
                  ],
                ),
              )),
          Expanded(
            child: StreamBuilder<DatabaseEvent>(
              stream: FirebaseDatabase.instance.ref('tests').orderByChild('examId').equalTo(origin).onValue,
              builder: (context, snapshot) {
                if(!snapshot.hasData) return Center(child: Center(child: CircularProgressIndicator(color: Color(0xff3D1975))),);
                List<TestModel> testModel=[];
                for(DataSnapshot snap in snapshot.data!.snapshot.children){
                  testModel.add(TestModel.fromMap(snap.value as Map));
                }
                  return ListView.builder(
                  controller: scrollcontroller,
                  itemBuilder: (BuildContext context, int index) {
                    return GestureDetector(
                      onTap: (){
                        FirebaseDatabase.instance.ref('memberships').child(testModel[index].examId).child(FirebaseAuth.instance.currentUser!.uid).once().then((value){
                          if(value.snapshot.exists) {
                            Navigator.push(context, MaterialPageRoute(
                                builder: (context) =>
                                    TestScreen(testModel: testModel[index])));
                          }else{
                            Navigator.push(context, MaterialPageRoute(builder: (context)=> MemberShipScreen(model: testModel[index].examId,)));
                          }
                        });
                      },
                      child: Container(
                        color: Colors.white,
                          alignment: Alignment.centerLeft,
                          margin: EdgeInsets.only(left: 16,right: 16,bottom: 8),
                          height: 60,
                          padding: EdgeInsets.only(left: 8),
                          child: Text(testModel[index].name)),
                    );
                  },itemCount: testModel.length,
                );
              }
            ),
          ),
        ],
      ),
    );
  }

  Widget menu(String title) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selected = title;
        });
      },
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          title,
          style: TextStyle(
              color: selected == title ? Color(0xff3D1975) : Colors.black,
              fontWeight:
                  selected == title ? FontWeight.bold : FontWeight.normal),
        ),
      ),
    );
  }
}
