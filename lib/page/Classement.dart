import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import '../service/translate.dart';
import 'Question.dart';

class Classement extends StatefulWidget {
  final int numQuestions;
  final String category;
  final String difficulty;

  Classement({required this.numQuestions, required this.category, required this.difficulty});

  @override
  _ClassementState createState() => _ClassementState();
}

class _ClassementState extends State<Classement> {
  final _audioPlayer = AudioPlayer();
  List<Map<String, dynamic>> leaderboard = [];

  String selectedDifficulty = '';
  String selectedCategory = '';

  @override
  void initState() {
    super.initState();
    _playMusicIfEnabled();
    final localisation = Provider.of<LocalizationService>(context, listen: false);
    selectedCategory ??= localisation.translate('home.option1');
    selectedDifficulty ??= localisation.translate('home.diff1');
    _loadLeaderboard();
  }

  Future<void> _playMusicIfEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    final musicEnabled = prefs.getBool('Music') ?? false;
    if (musicEnabled) {
      await _audioPlayer.play(AssetSource('quiz.mp3'));
    }
  }

  Future<void> _loadLeaderboard() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.reload();

    String leaderboardKey = "leaderboard_${selectedCategory.toLowerCase()}_${selectedDifficulty.toLowerCase()}";
    String? storedScores = prefs.getString(leaderboardKey);

    if (storedScores == null || storedScores.isEmpty) {
      setState(() => leaderboard = []);
      return;
    }

    try {
      List<dynamic> rawScores = json.decode(storedScores);
      List<Map<String, dynamic>> scores = rawScores.map((e) => Map<String, dynamic>.from(e)).toList();
      scores.sort((a, b) => b["score"].compareTo(a["score"]));
      scores = scores.take(10).toList();

      setState(() {
        leaderboard = scores;
      });
    } catch (e) {
      print("Erreur de parsing du classement : $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final localisation = Provider.of<LocalizationService>(context);

    if (selectedDifficulty.isEmpty) selectedDifficulty = localisation.translate('home.diff1');
    if (selectedCategory.isEmpty) selectedCategory = localisation.translate('home.option1');

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF7B1FA2), Color(0xFFE1BEE7)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                margin: const EdgeInsets.all(20),
                elevation: 10,
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.asset('images/leaderboard_header.png', height: 80),
                      const SizedBox(height: 10),
                      Text(
                        localisation.translate('leaderboard.leaderboardTitle'),
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                      ),
                      const SizedBox(height: 20),
                      _buildDropdown<String>(
                        label: localisation.translate('leaderboard.selectCategoryLabel'),
                        value: selectedCategory,
                        items: [
                          localisation.translate('home.option1'),
                          localisation.translate('home.option2'),
                          localisation.translate('home.option3'),
                          localisation.translate('home.option4'),
                          localisation.translate('home.option5'),
                          localisation.translate('home.option6'),
                          localisation.translate('home.option7'),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => selectedCategory = val);
                            _loadLeaderboard();
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      _buildDropdown<String>(
                        label: localisation.translate('leaderboard.selectDifficultyLabel'),
                        value: selectedDifficulty,
                        items: [
                          localisation.translate('home.diff1'),
                          localisation.translate('home.diff2'),
                          localisation.translate('home.diff3'),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => selectedDifficulty = val);
                            _loadLeaderboard();
                          }
                        },
                      ),
                      const SizedBox(height: 30),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: leaderboard.length,
                        itemBuilder: (context, index) {
                          var entry = leaderboard[index];
                          String name = entry["name"];
                          double score = entry["score"];
                          Widget icon = const SizedBox();

                          if (index == 0) {
                            icon = Image.asset('images/gold.png', width: 32);
                          } else if (index == 1) {
                            icon = Image.asset('images/silver.png', width: 32);
                          } else if (index == 2) {
                            icon = Image.asset('images/bronze.png', width: 32);
                          }

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    if (index < 3) icon,
                                    const SizedBox(width: 10),
                                    Text(
                                      name,
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                                Text(
                                  "${(score * 100).toStringAsFixed(1)}%",
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: () => Navigator.pushNamed(context, "/home"),
                            style: _buttonStyle(),
                            child: Text(localisation.translate('leaderboard.homeButton')),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => Question(
                                    nombreQuestions: widget.numQuestions,
                                    categorie: widget.category,
                                    difficulte: widget.difficulty,
                                  ),
                                ),
                              );
                            },
                            style: _buttonStyle(),
                            child: Text(localisation.translate('leaderboard.replayButton')),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  ButtonStyle _buttonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.deepPurple,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T value,
    required List<T> items,
    required void Function(T?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.deepPurple),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.deepPurple, width: 1.5),
            borderRadius: BorderRadius.circular(30),
          ),
          child: DropdownButton<T>(
            value: value,
            isExpanded: true,
            underline: const SizedBox(),
            icon: const Icon(Icons.arrow_drop_down, color: Colors.deepPurple),
            iconSize: 28,
            style: const TextStyle(fontSize: 14, color: Colors.deepPurple),
            items: items.map((T item) {
              return DropdownMenuItem<T>(
                value: item,
                child: Text(item.toString()),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
