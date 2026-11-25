import 'package:flutter/foundation.dart';
import 'package:app/features/kuis/data/repositories/artifact_match_service.dart';

class QuizQuestion {
  final String prompt;
  final List<String> options;

  const QuizQuestion({required this.prompt, required this.options});
}

class ArtifactMatchViewModel extends ChangeNotifier {
  static const List<QuizQuestion> questions = [
    QuizQuestion(
      prompt: 'Apa gaya petualangan atau aktivitas liburan impianmu?',
      options: [
        'Menjelajah alam bebas',
        'Menyusun strategi & taktik',
        'Mempelajari dokumen sejarah kuno',
        'Mengamati benda seni & simbolik',
      ],
    ),
    QuizQuestion(
      prompt: 'Sifat apa yang paling mencerminkan dirimu?',
      options: [
        'Tangguh & tak kenal menyerah',
        'Cekatan & solutif',
        'Tenang & penuh perhitungan',
        'Setia & berdedikasi tinggi',
      ],
    ),
    QuizQuestion(
      prompt: 'Di era perjuangan dulu, peran apa yang paling kamu bayangkan?',
      options: [
        'Pasukan di garis depan',
        'Pengatur taktik pertahanan',
        'Juru runding & arsiparis',
        'Penggerak semangat rakyat',
      ],
    ),
  ];

  final Map<int, String> _answers = {};
  bool _isLoading = false;
  String? _errorMessage;
  ArtifactMatchResult? _result;

  Map<int, String> get answers => _answers;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  ArtifactMatchResult? get result => _result;

  bool get isAllAnswered => _answers.length == questions.length;

  void selectAnswer(int questionIndex, String answer) {
    _answers[questionIndex] = answer;
    notifyListeners();
  }

  void resetQuiz() {
    _answers.clear();
    _result = null;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> submitQuiz({String? visitorName}) async {
    if (!isAllAnswered) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ArtifactMatchService.createMatch(
        answers: _answers.values.toList(),
      );
      _result = res;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
