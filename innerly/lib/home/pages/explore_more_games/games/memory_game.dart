import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:confetti/confetti.dart';

class MemoryGameScreen extends StatefulWidget {
  const MemoryGameScreen({super.key});

  @override
  State<MemoryGameScreen> createState() => _MemoryGameScreenState();
}

class _MemoryGameScreenState extends State<MemoryGameScreen> {
  List<String> cards = [];
  List<bool> revealed = [];
  int? firstCardIndex;
  int level = 1;
  int _matches = 0;
  int _attempts = 0;
  bool _isProcessing = false;
  late ConfettiController _confettiController;

  final List<String> _therapeuticSymbols = [
    '🌸', '🌊', '🎵', '🕊️', '🌳', '🕯️',
    '🌈', '🍃', '🎨', '🧘', '🎶', '🫧'
  ];

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _initializeGame();
  }

  void _initializeGame() {
    final symbols = _therapeuticSymbols.sublist(0, 2 + level);
    cards = [...symbols, ...symbols]..shuffle();
    revealed = List.filled(cards.length, false);
    _matches = 0;
    _attempts = 0;
    _isProcessing = false;
  }

  void _handleCardTap(int index) async {
    if (_isProcessing || revealed[index] || index == firstCardIndex) return;

    setState(() {
      revealed[index] = true;
      _isProcessing = true;
    });

    if (firstCardIndex == null) {
      firstCardIndex = index;
      _isProcessing = false;
    } else {
      _attempts++;
      await Future.delayed(const Duration(milliseconds: 500));

      if (cards[firstCardIndex!] == cards[index]) {
        _matches++;
        if (_matches == cards.length ~/ 2) {
          _confettiController.play();
          await Future.delayed(const Duration(milliseconds: 500));
          _showLevelComplete();
        }
      } else {
        setState(() {
          revealed[index] = false;
          revealed[firstCardIndex!] = false;
        });
      }

      setState(() {
        firstCardIndex = null;
        _isProcessing = false;
      });
    }
  }

  void _showLevelComplete() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFDF3E7),
        title: Text('Level $level Complete!',
            style: GoogleFonts.amita(color: Colors.green)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Attempts: $_attempts',
                style: GoogleFonts.amita(fontSize: 18)),
            const SizedBox(height: 10),
            Text('⭐ ${5 - _attempts ~/ 2} / 5 Stars',
                style: GoogleFonts.amita(color: Colors.amber)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                level++;
                _initializeGame();
              });
            },
            child: Text('Next Level', style: GoogleFonts.amita()),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return LinearProgressIndicator(
      value: _matches / (cards.length / 2),
      backgroundColor: Colors.grey[200],
      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6C9A8B)),
      minHeight: 10,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Memory Therapy - Level $level',
            style: GoogleFonts.aboreto()),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              _buildProgressIndicator(),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      childAspectRatio: 0.8,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                    ),
                    itemCount: cards.length,
                    itemBuilder: (context, index) => AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: GestureDetector(
                        onTap: () => _handleCardTap(index),
                        child: Container(
                          key: ValueKey('${revealed[index]}_$index'),
                          decoration: BoxDecoration(
                            color: revealed[index]
                                ? const Color(0xFFDAF5FB)
                                : const Color(0xFF6C9A8B),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Center(
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 200),
                              opacity: revealed[index] ? 1 : 0,
                              child: Text(
                                cards[index],
                                style: const TextStyle(fontSize: 32),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }
}