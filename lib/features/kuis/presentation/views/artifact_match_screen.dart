import 'package:flutter/material.dart';

import 'package:app/core/network/api_client.dart';
import 'package:app/features/kuis/data/repositories/artifact_match_service.dart';

class ArtifactMatchScreen extends StatefulWidget {
  const ArtifactMatchScreen({super.key});

  @override
  State<ArtifactMatchScreen> createState() => _ArtifactMatchScreenState();
}

class _ArtifactMatchScreenState extends State<ArtifactMatchScreen> {
  static const Color _darkGreen = Color(0xFF3F5243);
  static const Color _gold = Color(0xFFCBB26A);

  static const List<_QuizQuestion> _questions = [
    _QuizQuestion(
      prompt: 'Apa gaya petualangan atau aktivitas liburan impianmu?',
      options: [
        'Menjelajah alam bebas',
        'Menyusun strategi & taktik',
        'Mempelajari dokumen sejarah kuno',
        'Mengamati benda seni & simbolik',
      ],
    ),
    _QuizQuestion(
      prompt: 'Sifat apa yang paling mencerminkan dirimu?',
      options: [
        'Tangguh & tak kenal menyerah',
        'Cekatan & solutif',
        'Tenang & penuh perhitungan',
        'Setia & berdedikasi tinggi',
      ],
    ),
    _QuizQuestion(
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
  ArtifactMatchResult? _result;

  Future<void> _analyzeAnswers() async {
    if (_answers.length != _questions.length || _isLoading) return;

    setState(() {
      _isLoading = true;
      _result = null;
    });

    try {
      final result = await ArtifactMatchService.createMatch(
        answers: List.generate(_questions.length, (index) => _answers[index]!),
      );
      if (!mounted) return;
      setState(() => _result = result);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is ApiException
                ? error.message
                : 'Analisis gagal. Silakan coba lagi.',
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F3EA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F3EA),
        foregroundColor: _darkGreen,
        title: const Text(
          'Kuis Penjelajah',
          style: TextStyle(
            fontFamily: 'PlayfairDisplay',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildIntroCard(),
              const SizedBox(height: 20),
              for (var index = 0; index < _questions.length; index++)
                _buildQuestion(index, _questions[index]),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _answers.length == _questions.length && !_isLoading
                    ? _analyzeAnswers
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _darkGreen,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: _darkGreen.withValues(alpha: 0.35),
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.auto_awesome),
                label: Text(
                  _isLoading
                      ? 'Mencari artefak yang cocok...'
                      : '✨ Analisis Kepribadian & Cari Artefak',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              if (_result case final result?) ...[
                const SizedBox(height: 22),
                _buildResultCard(result),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIntroCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _darkGreen,
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [_darkGreen, Color(0xFF61775F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.explore_outlined, color: _gold, size: 30),
          SizedBox(height: 10),
          Text(
            'Temukan Artefak Jiwamu',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'PlayfairDisplay',
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Jawab tiga pertanyaan singkat dan temukan koleksi Museum Brawijaya yang paling cocok dengan caramu menjelajahi sejarah.',
            style: TextStyle(color: Colors.white70, height: 1.45),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestion(int index, _QuizQuestion question) {
    final selectedAnswer = _answers[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E3DF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PERTANYAAN ${index + 1}',
            style: const TextStyle(
              color: _darkGreen,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            question.prompt,
            style: const TextStyle(
              color: Color(0xFF2C322B),
              fontWeight: FontWeight.bold,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in question.options)
                ChoiceChip(
                  label: Text(option),
                  selected: selectedAnswer == option,
                  showCheckmark: false,
                  selectedColor: const Color(0xFFE8E1CA),
                  backgroundColor: const Color(0xFFFAFAF8),
                  side: BorderSide(
                    color: selectedAnswer == option
                        ? _gold
                        : const Color(0xFFE0E3DF),
                  ),
                  labelStyle: TextStyle(
                    color: selectedAnswer == option
                        ? _darkGreen
                        : const Color(0xFF50574F),
                    fontSize: 12,
                    fontWeight: selectedAnswer == option
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                  onSelected: _isLoading
                      ? null
                      : (selected) {
                          if (!selected) return;
                          setState(() {
                            _answers[index] = option;
                            _result = null;
                          });
                        },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(ArtifactMatchResult result) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _gold, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _darkGreen.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome, color: _gold),
              SizedBox(width: 8),
              Text(
                'ARTEFAK YANG COCOK UNTUKMU',
                style: TextStyle(
                  color: _darkGreen,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            result.matchedArtifact,
            style: const TextStyle(
              color: _darkGreen,
              fontFamily: 'PlayfairDisplay',
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            result.aiExplanation,
            style: const TextStyle(color: Color(0xFF50574F), height: 1.55),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 6),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.check_circle_outline, color: _darkGreen, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Pilihanmu dan hasil kecocokan telah tersimpan di sistem museum.',
                  style: TextStyle(
                    color: _darkGreen,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuizQuestion {
  final String prompt;
  final List<String> options;

  const _QuizQuestion({required this.prompt, required this.options});
}
