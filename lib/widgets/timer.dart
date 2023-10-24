import 'dart:async';

import 'package:flutter/material.dart';

class TimerWidget extends StatefulWidget {
  const TimerWidget({Key? key,required this.totalTime, required this.onFinish}) : super(key: key);

  final int totalTime;

  final Function onFinish;
  @override
  State<TimerWidget> createState() => _TimerWidgetState();
}

class _TimerWidgetState extends State<TimerWidget> {
  String time="00:00:00";
  int currentTime=0;

  @override
  void initState() {
    super.initState();
    currentTime=widget.totalTime*60;
    Timer.periodic(Duration(seconds: 1), (timer) {
      if(mounted) {
        setState(() {
          currentTime--;
          if (currentTime == 0) {
            timer.cancel();
            widget.onFinish();
          }
          time = _printDuration(Duration(seconds: currentTime));
        });
      }
    });
  }
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 16.0,top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Icon(Icons.timer,color: Color(0xff3D1975),),
          SizedBox(width: 8,),
          Text(time,style: TextStyle(fontSize: 16),)
        ],
      ),
    );
  }
  String _printDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }
}
