import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html_unescape/html_unescape.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';

import '../service/translate.dart';
import 'Result.dart';

class Question extends StatefulWidget {
  final int nombreQuestions;
  final String categorie;
  final String difficulte;

  const Question({super.key, required this.nombreQuestions, required this.categorie, required this.difficulte});

  @override
  State<Question> createState() => _QuestionState();
}

class _QuestionState extends State<Question> {
  final HtmlUnescape _decodeHtml = HtmlUnescape();

  List questions = [];
  List<String> reponsesMelangees = [];
  List<Map<String, dynamic>> reponsesUtilisateur = [];

  int indexQuestionActuelle = 0;
  int? indexOptionSelectionnee;
  int? indexBonneReponse;
  int compteur = 10;
  bool enChargement = true;
  bool afficherCorrection = false;

  late Timer minuteur;
  late AudioPlayer _lecteurAudio;
  bool musiqueActivee = false;

  @override
  void initState() {
    super.initState();
    _initialiserAudioEtMusique();
    _recupererQuestions();
    _demarrerMinuteur();
  }

  Future<void> _initialiserAudioEtMusique() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    musiqueActivee = prefs.getBool('Music') ?? false;
    _lecteurAudio = AudioPlayer();

    if (musiqueActivee) {
      await _lecteurAudio.play(AssetSource('clock.mp3'), volume: 1.0);
    }
  }

  @override
  void dispose() {
    minuteur.cancel();
    _lecteurAudio.dispose();
    super.dispose();
  }

  void _demarrerMinuteur() {
    minuteur = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (compteur > 0) {
        setState(() => compteur--);
      } else {
        _passerALaQuestionSuivante();
      }
    });
  }

  Future<void> _recupererQuestions() async {
    final idCategorie = _obtenirIdCategorie(widget.categorie);
    final difficulty = _convertirDifficulte(widget.difficulte);

    final String url =
        "https://opentdb.com/api.php?amount=${widget.nombreQuestions}&category=$idCategorie&difficulty=$difficulty&type=multiple";
    try {
      final reponse = await http.get(Uri.parse(url));
      if (reponse.statusCode == 200) {
        final donnees = json.decode(reponse.body);
        if (donnees['results'].isNotEmpty) {
          setState(() {
            questions = donnees['results'];
            enChargement = false;
            _melangerReponses();
          });
        }
      }
    } catch (e) {
      setState(() => enChargement = false);
      debugPrint('Erreur lors de la récupération des questions: $e');
    }
  }

  String _convertirDifficulte(String difficulte) {
    Map<String, String> mapping = {
      'Facile': 'easy',
      'Moyen': 'medium',
      'Difficile': 'hard',
      'سهل': 'easy',
      'متوسط': 'medium',
      'صعب': 'hard',
    };
    return mapping[difficulte] ?? 'easy';
  }

  int _obtenirIdCategorie(String categorie) {
    final localisation = Provider.of<LocalizationService>(context, listen: false);
    final mapCategorie = {
      localisation.translate('home.option1'): 17,
      localisation.translate('home.option2'): 27,
      localisation.translate('home.option3'): 15,
      localisation.translate('home.option4'): 18,
      localisation.translate('home.option5'): 19,
      localisation.translate('home.option6'): 28,
      localisation.translate('home.option7'): 21,
    };
    return mapCategorie[categorie] ?? 9;
  }

  void _melangerReponses() {
    if (questions.isNotEmpty) {
      List<String> options = List.from(questions[indexQuestionActuelle]['incorrect_answers']);
      options.add(questions[indexQuestionActuelle]['correct_answer']);
      options.shuffle();

      setState(() {
        reponsesMelangees = options;
        indexBonneReponse = reponsesMelangees.indexOf(questions[indexQuestionActuelle]['correct_answer']);
        compteur = 10;
        afficherCorrection = false;
      });

      if (musiqueActivee) {
        _lecteurAudio.stop();
        _lecteurAudio.play(AssetSource('clock.mp3'), volume: 1.0);
      }
    }
  }

  void _passerALaQuestionSuivante() async {
    await _lecteurAudio.stop();

    if (indexOptionSelectionnee != null) {
      reponsesUtilisateur.add({
        "question": questions[indexQuestionActuelle]['question'],
        "reponse_choisie": reponsesMelangees[indexOptionSelectionnee!],
        "bonne_reponse": questions[indexQuestionActuelle]['correct_answer'],
      });
    }

    if (!afficherCorrection && indexOptionSelectionnee != null) {
      setState(() => afficherCorrection = true);
      await Future.delayed(const Duration(seconds: 2));
    }

    if (indexQuestionActuelle < questions.length - 1) {
      setState(() {
        indexQuestionActuelle++;
        indexOptionSelectionnee = null;
      });
      _melangerReponses();
    } else {
      minuteur.cancel();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PageResultats(
            reponsesUtilisateur: reponsesUtilisateur,
            difficulte: widget.difficulte.toLowerCase(),
            nombreQuestions: widget.nombreQuestions,
            categorie: widget.categorie,
          ),
        ),
      );
    }
  }

  Color _assombrir(Color couleur) {
    return Color.fromARGB(
      couleur.alpha,
      (couleur.red * 0.7).round(),
      (couleur.green * 0.7).round(),
      (couleur.blue * 0.7).round(),
    );
  }

  @override
  Widget build(BuildContext context) {
    String imagePath = '';
    if (afficherCorrection) {
      imagePath = indexOptionSelectionnee == indexBonneReponse
          ? 'images/correct.png'
          : 'images/wrong.png';
    }

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
          child: enChargement
              ? const Center(child: CircularProgressIndicator())
              : Center(
            child: SingleChildScrollView(
              child: Card(
                elevation: 10,
                margin: const EdgeInsets.all(20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (imagePath.isNotEmpty)
                        Image.asset(imagePath, height: 100),
                      const SizedBox(height: 10),
                      LinearProgressIndicator(
                        value: compteur / 10,
                        backgroundColor: Colors.grey.shade300,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Temps restant : $compteur s",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "Q${indexQuestionActuelle + 1} :",
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _decodeHtml.convert(questions[indexQuestionActuelle]['question']),
                        style: const TextStyle(fontSize: 18),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 25),
                      _afficherOptions(),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: indexOptionSelectionnee != null ? _passerALaQuestionSuivante : null,
                        icon: const Icon(Icons.navigate_next),
                        label: const Text("Continuer"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
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

  Widget _afficherOptions() {
    final List<Color> palette = [
      Colors.teal.shade400,
      Colors.amber.shade700,
      Colors.indigo.shade400,
      Colors.redAccent,
    ];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: reponsesMelangees.length,
      itemBuilder: (_, index) {
        final reponse = _decodeHtml.convert(reponsesMelangees[index]);
        Color couleur;

        if (afficherCorrection) {
          if (index == indexBonneReponse) {
            couleur = Colors.green;
          } else if (index == indexOptionSelectionnee) {
            couleur = Colors.red;
          } else {
            couleur = palette[index % palette.length].withOpacity(0.5);
          }
        } else {
          couleur = indexOptionSelectionnee == index
              ? _assombrir(palette[index % palette.length])
              : palette[index % palette.length];
        }

        return GestureDetector(
          onTap: () {
            if (!afficherCorrection) {
              setState(() => indexOptionSelectionnee = index);
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: couleur,
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
              ],
            ),
            child: Text(
              reponse,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
    );
  }
}
