import 'package:exambullet/models/User.dart';
import 'package:exambullet/models/exam.dart';
import 'package:exambullet/widgets/heading.dart';
import 'package:exambullet/widgets/inputfield.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class AllExams extends StatefulWidget {
  const AllExams({Key? key,required this.model}) : super(key: key);

  final UserModel model;
  @override
  State<AllExams> createState() => _AllExamsState();
}

class _AllExamsState extends State<AllExams> {
  var searchController=TextEditingController();
  @override
  Widget build(BuildContext context) {
    searchController.addListener(() {
      setState(() {
        searchController;
      });
    });
    return Scaffold(
      appBar: AppBar(title: Text('All Exams'),),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InputField(controller: searchController, hint: 'Search',icon: Icons.search,),
          Heading(heading: 'All Exams'),
          Expanded(
            child: StreamBuilder(builder: (BuildContext context, AsyncSnapshot<DatabaseEvent> snapshot) {
              if(!snapshot.hasData) return Center(child: CircularProgressIndicator(color: Color(0xff3D1975),));
              List<ExamModel> modelList=[];
              for(DataSnapshot snap in snapshot.data!.snapshot.children){
                ExamModel model=ExamModel.fromMap(snap.value as Map);
                modelList.add(model);
              }
              return GridView.builder(gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2), itemBuilder: (BuildContext context, int index) {
                return GestureDetector(
                  onTap: (){

                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Card(
                      color: Colors.white,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Expanded(child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Image.network(modelList[index].icon),
                            )),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(modelList[index].name),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },itemCount: modelList.length,);
            },stream: FirebaseDatabase.instance.ref('exams').onValue,),
          ),
        ],
      ),
    );
  }
}
