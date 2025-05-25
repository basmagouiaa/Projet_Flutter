import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../service/translate.dart';
import '../service/AppSettings.dart';
import 'Question.dart';
import 'Settings.dart';
import 'a_propos.dart';

class Accueil extends StatefulWidget {
  @override
  _AccueilState createState() => _AccueilState();
}

class _AccueilState extends State<Accueil> {
  TextEditingController _nomUtilisateur = TextEditingController();
  late AudioPlayer _audioPlayer;

  int _nombreQuestions = 5;
  String _categorieKey = 'home.option1';
  String _difficulteKey = 'home.diff1';

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final settings = Provider.of<AppSettings>(context);
    _manageMusic(settings.music);
  }

  Future<void> _manageMusic(bool active) async {
    if (active) {
      await _audioPlayer.play(AssetSource('quiz.mp3'), volume: 0.5);
    } else {
      await _audioPlayer.stop();
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localisation = Provider.of<LocalizationService>(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          localisation.translate('home.welcomePageTitle'),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        backgroundColor: Colors.deepPurple.withOpacity(0.8),
        elevation: 10,
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            color: Theme.of(context).colorScheme.onPrimary,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsPage()),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple.shade300, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              child: Padding(
                padding: const EdgeInsets.all(25.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: CircleAvatar(
                        backgroundImage: AssetImage('images/Quizz.png'),
                        radius: 40,
                      ),
                    ),
                    SizedBox(height: 20),
                    TextFormField(
                      controller: _nomUtilisateur,
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.person, color: Colors.deepPurple),
                        hintText: localisation.translate('home.contestantNameHint'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(color: Colors.deepPurple, width: 2),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    _buildDropdown<int>(
                      label: localisation.translate('home.numberOfQuestionsLabel'),
                      value: _nombreQuestions,
                      items: [5, 10, 20],
                      onChanged: (val) {
                        if (val != null) setState(() => _nombreQuestions = val);
                      },
                    ),
                    SizedBox(height: 20),
                    _buildDropdown<String>(
                      label: localisation.translate('home.selectCategoryLabel'),
                      value: _categorieKey,
                      items: [
                        'home.option1',
                        'home.option2',
                        'home.option3',
                        'home.option4',
                        'home.option5',
                        'home.option6',
                        'home.option7',
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _categorieKey = val);
                      },
                      translateItem: true,
                    ),
                    SizedBox(height: 20),
                    _buildDropdown<String>(
                      label: localisation.translate('home.selectDifficultyLabel'),
                      value: _difficulteKey,
                      items: [
                        'home.diff1',
                        'home.diff2',
                        'home.diff3',
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _difficulteKey = val);
                      },
                      translateItem: true,
                    ),
                    SizedBox(height: 30),
                    Center(
                      child: _buildButton(
                        text: localisation.translate('home.startGameButton'),
                        onPressed: () => _lancerJeu(context),
                      ),
                    ),
                    SizedBox(height: 20),
                    Center(
                      child: _buildButton(
                        text: localisation.translate('home.propos'),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => AboutPage()),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required void Function(T?) onChanged,
    bool translateItem = false,
  }) {
    final localisation = Provider.of<LocalizationService>(context, listen: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
          ),
        ),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.deepPurple, width: 1.5),
            borderRadius: BorderRadius.circular(30),
          ),
          child: DropdownButton<T>(
            value: value,
            isExpanded: true,
            underline: SizedBox(),
            icon: Icon(Icons.arrow_drop_down, color: Colors.deepPurple),
            iconSize: 30,
            style: TextStyle(fontSize: 16, color: Colors.deepPurple),
            onChanged: onChanged,
            items: items.map((item) {
              return DropdownMenuItem<T>(
                value: item,
                child: Text(
                  translateItem ? localisation.translate(item.toString()) : item.toString(),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildButton({required String text, required VoidCallback onPressed}) {
    return ElevatedButton(
      onPressed: onPressed,
      child: Text(text),
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 14),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
    );
  }

  void _lancerJeu(BuildContext context) async {
    final localisation = Provider.of<LocalizationService>(context, listen: false);
    final prefs = await SharedPreferences.getInstance();

    if (_nomUtilisateur.text.isNotEmpty) {
      await prefs.setString("username", _nomUtilisateur.text);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Question(
            nombreQuestions: _nombreQuestions,
            categorie: localisation.translate(_categorieKey),
            difficulte: localisation.translate(_difficulteKey),
          ),
        ),
      );
    } else {
      final snackBar = SnackBar(
        content: Text(localisation.translate('home.userNameEmptyError')),
        backgroundColor: Colors.red,
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }
}