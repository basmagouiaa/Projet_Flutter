import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class page1 extends StatefulWidget {
  const page1({Key? key}) : super(key: key);

  @override
  State<page1> createState() => _page1State();
}

class _page1State extends State<page1> {
  late AudioPlayer _audioPlayer;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    playAudio();
    startTimer();
  }

  void playAudio() async {
    final prefs = await SharedPreferences.getInstance();
    final Music = prefs.getBool('Music') ?? false;
    if(Music)
    await _audioPlayer.play(AssetSource('quiz.mp3'));
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void startTimer() async {
    var duration = Duration(seconds: 4);
    Timer(duration, loginroute);
  }

  void loginroute() {
    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xffec2553), Color(0xfff66962)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Lottie.asset('assets/quiz.json'),
            ),
          ),
        ],
      ),
    );
  }
}

