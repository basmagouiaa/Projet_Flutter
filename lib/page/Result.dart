import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../service/translate.dart';
import 'Classement.dart';

class PageResultats extends StatefulWidget {
  final List<Map<String, dynamic>> reponsesUtilisateur;
  final String difficulte;
  final int nombreQuestions;
  final String categorie;

  const PageResultats({
    super.key,
    required this.reponsesUtilisateur,
    required this.difficulte,
    required this.nombreQuestions,
    required this.categorie,
  });

  @override
  State<PageResultats> createState() => _PageResultatsState();
}

class _PageResultatsState extends State<PageResultats> {
  late AudioPlayer _audioPlayer;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _playAudio();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playAudio() async {
    final prefs = await SharedPreferences.getInstance();
    final musicEnabled = prefs.getBool('music') ?? false;
    if (musicEnabled) {
      await _audioPlayer.play(AssetSource('quiz.mp3'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final localization = Provider.of<LocalizationService>(context);
    int bonnesReponses = widget.reponsesUtilisateur
        .where((rep) => rep["reponse_choisie"] == rep["bonne_reponse"])
        .length;

    double pourcentage = (bonnesReponses / widget.nombreQuestions) * 100;

    _enregistrerScore(bonnesReponses, widget.nombreQuestions, widget.difficulte.toLowerCase());

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
                margin: const EdgeInsets.all(20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 10,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        localization.translate('result.quizResultsTitle'),
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        '${localization.translate('result.score')} : $bonnesReponses / ${widget.nombreQuestions}  (${pourcentage.toStringAsFixed(1)}%)',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 30),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: widget.reponsesUtilisateur.length,
                        itemBuilder: (context, index) {
                          final reponse = widget.reponsesUtilisateur[index];
                          final estCorrect = reponse["reponse_choisie"] == reponse["bonne_reponse"];

                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: estCorrect ? Colors.green.shade50 : Colors.red.shade50,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: const [
                                BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  reponse["question"],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepPurple,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${localization.translate('result.yourAnswer')} : ${reponse["reponse_choisie"]}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: estCorrect ? Colors.green : Colors.red,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${localization.translate('result.correctAnswer')} : ${reponse["bonne_reponse"]}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => Classement(
                                numQuestions: widget.nombreQuestions,
                                category: widget.categorie,
                                difficulty: widget.difficulte,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Text(
                          localization.translate('result.seeLeaderboard'),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
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

  Future<void> _enregistrerScore(int correct, int total, String difficulty) async {
    final prefs = await SharedPreferences.getInstance();
    final playerName = prefs.getString("username") ?? "Joueur";
    final score = correct / total;
    final leaderboardKey = "leaderboard_${widget.categorie.toLowerCase()}_${difficulty.toLowerCase()}";
    final storedScores = prefs.getString(leaderboardKey);

    final scores = storedScores != null ? json.decode(storedScores) : [];
    final parsedScores = scores.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e)).toList();
    parsedScores.add({"name": playerName, "score": score});
    parsedScores.sort((a, b) => (b["score"] as double).compareTo(a["score"] as double));

    await prefs.setString(leaderboardKey, json.encode(parsedScores));
  }
}