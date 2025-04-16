import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sudoku_dart/sudoku_dart.dart';

class SudokuScreen extends StatefulWidget {
  const SudokuScreen({super.key});

  @override
  State<SudokuScreen> createState() => _SudokuScreenState();
}

class _SudokuScreenState extends State<SudokuScreen> {
  late List<List<int>> _puzzle;
  late List<List<int>> _solution;
  late List<List<bool>> _editable;
  int _selectedNumber = 0;
  int _selectedRow = -1;
  int _selectedCol = -1;
  String _difficulty = 'Easy';
  int _mistakes = 0;
  bool _isComplete = false;
  bool _isLoading = true;

  final Map<String, Level> _difficultyLevels = {
    'Easy': Level.easy,
    'Medium': Level.medium,
    'Hard': Level.hard,
    'Expert': Level.expert,
  };

  @override
  void initState() {
    super.initState();
    _generateNewPuzzle();
  }

  Future<void> _generateNewPuzzle() async {
    setState(() => _isLoading = true);

    try {
      final sudoku = Sudoku.generate(_difficultyLevels[_difficulty]!);

      // Convert puzzle to 2D list and replace -1 with 0 for empty cells
      _puzzle = List.generate(9, (i) =>
          List.generate(9, (j) => sudoku.puzzle[i*9 + j] == -1 ? 0 : sudoku.puzzle[i*9 + j]));

      // Convert solution to 2D list
      _solution = List.generate(9, (i) =>
          List.generate(9, (j) => sudoku.solution[i*9 + j]));

      _editable = List.generate(9, (i) =>
          List.generate(9, (j) => _puzzle[i][j] == 0));

      _mistakes = 0;
      _isComplete = false;
    } catch (e) {
      debugPrint('Error generating puzzle: $e');
      // Fallback to empty board
      _puzzle = List.generate(9, (_) => List.filled(9, 0));
      _editable = List.generate(9, (_) => List.filled(9, true));
    }

    setState(() => _isLoading = false);
  }

  void _handleCellTap(int row, int col) {
    if (!_editable[row][col] || _isComplete || _isLoading) return;

    setState(() {
      _selectedRow = row;
      _selectedCol = col;
    });
  }

  void _handleNumberSelect(int number) {
    if (_selectedRow == -1 || _selectedCol == -1 || _isComplete || _isLoading) return;

    setState(() {
      if (_puzzle[_selectedRow][_selectedCol] == number) {
        // Clear the cell
        _puzzle[_selectedRow][_selectedCol] = 0;
      } else {
        _puzzle[_selectedRow][_selectedCol] = number;

        // Check for mistakes
        if (number != _solution[_selectedRow][_selectedCol]) {
          _mistakes++;
          if (_mistakes >= 3) {
            _showMistakeDialog();
          }
        } else {
          _checkCompletion();
        }
      }
    });
  }

  void _checkCompletion() {
    for (int i = 0; i < 9; i++) {
      for (int j = 0; j < 9; j++) {
        if (_puzzle[i][j] != _solution[i][j]) return;
      }
    }
    setState(() => _isComplete = true);
    _showCompletionDialog();
  }

  void _showMistakeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFDF3E7),
        title: Text('Mindful Moment', style: GoogleFonts.amita()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('You\'ve made $_mistakes errors', style: GoogleFonts.amita()),
            const SizedBox(height: 10),
            Text('Take a deep breath and try again', style: GoogleFonts.amita()),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _generateNewPuzzle();
            },
            child: Text('New Puzzle', style: GoogleFonts.amita()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Highlight correct cells
              setState(() {
                for (int i = 0; i < 9; i++) {
                  for (int j = 0; j < 9; j++) {
                    if (_puzzle[i][j] != 0 && _puzzle[i][j] != _solution[i][j]) {
                      _puzzle[i][j] = _solution[i][j];
                    }
                  }
                }
              });
            },
            child: Text('Show Errors', style: GoogleFonts.amita()),
          ),
        ],
      ),
    );
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFDF3E7),
        title: Text('Excellent Work!', style: GoogleFonts.amita()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Difficulty: $_difficulty', style: GoogleFonts.amita()),
            Text('Mistakes: $_mistakes', style: GoogleFonts.amita()),
            const SizedBox(height: 10),
            Text('You\'ve completed this brain exercise!', style: GoogleFonts.amita()),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _generateNewPuzzle();
            },
            child: Text('Next Puzzle', style: GoogleFonts.amita()),
          ),
        ],
      ),
    );
  }

  void _changeDifficulty(String difficulty) {
    setState(() {
      _difficulty = difficulty;
      _generateNewPuzzle();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mindful Sudoku', style: GoogleFonts.aboreto()),
        backgroundColor: const Color(0xFFFDF3E7),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _generateNewPuzzle,
            tooltip: 'New Puzzle',
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showHelpDialog(),
            tooltip: 'Help',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
        color: const Color(0xFFFDF3E7),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _difficultyLevels.keys.map((difficulty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ChoiceChip(
                        label: Text(difficulty, style: GoogleFonts.amita()),
                        selected: _difficulty == difficulty,
                        selectedColor: const Color(0xFF6C9A8B),
                        onSelected: (_) => _changeDifficulty(difficulty),
                        labelStyle: TextStyle(
                          color: _difficulty == difficulty
                              ? Colors.white
                              : const Color(0xFF6C9A8B),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: GridView.builder(
                        padding: const EdgeInsets.all(8.0),
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 9,
                        ),
                        itemCount: 81,
                        itemBuilder: (context, index) {
                          final row = index ~/ 9;
                          final col = index % 9;
                          final isSelected = row == _selectedRow && col == _selectedCol;
                          final isHighlighted = row == _selectedRow ||
                              col == _selectedCol ||
                              (row ~/ 3 == _selectedRow ~/ 3 &&
                                  col ~/ 3 == _selectedCol ~/ 3);
                          final isError = _editable[row][col] &&
                              _puzzle[row][col] != 0 &&
                              _puzzle[row][col] != _solution[row][col];

                          return GestureDetector(
                            onTap: () => _handleCellTap(row, col),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 100),
                              margin: EdgeInsets.all(
                                isSelected ? 1.0 : 2.0,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFFDAF5FB)
                                    : isHighlighted && _selectedRow != -1
                                    ? const Color(0xFFE8F4F8).withOpacity(0.5)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF6C9A8B)
                                      : (row % 3 == 0 && row != 0) ||
                                      (col % 3 == 0 && col != 0)
                                      ? const Color(0xFF6C9A8B).withOpacity(0.8)
                                      : Colors.grey.withOpacity(0.3),
                                  width: isSelected ? 2.0 : 1.0,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  _puzzle[row][col] == 0 ? '' : _puzzle[row][col].toString(),
                                  style: TextStyle(
                                    fontSize: 22,
                                    color: isError
                                        ? Colors.red[300]
                                        : _editable[row][col]
                                        ? const Color(0xFF2A4B5B)
                                        : const Color(0xFF6C9A8B),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Container(
              height: 100,
              color: const Color(0xFFE8F4F8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  9,
                      (index) => GestureDetector(
                    onTap: () => _handleNumberSelect(index + 1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _selectedNumber == index + 1
                            ? const Color(0xFF6C9A8B)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          (index + 1).toString(),
                          style: TextStyle(
                            fontSize: 20,
                            color: _selectedNumber == index + 1
                                ? Colors.white
                                : const Color(0xFF6C9A8B),
                            fontWeight: FontWeight.bold,
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
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFDF3E7),
        title: Text('How to Play', style: GoogleFonts.amita()),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('1. Select a difficulty level', style: GoogleFonts.amita()),
              const SizedBox(height: 8),
              Text('2. Tap an empty cell', style: GoogleFonts.amita()),
              const SizedBox(height: 8),
              Text('3. Select a number from the bottom', style: GoogleFonts.amita()),
              const SizedBox(height: 8),
              Text('4. Fill all cells correctly to complete', style: GoogleFonts.amita()),
              const SizedBox(height: 16),
              Text('Therapeutic Benefits:', style: GoogleFonts.amita(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('• Improves concentration', style: GoogleFonts.amita()),
              Text('• Enhances problem-solving', style: GoogleFonts.amita()),
              Text('• Reduces stress', style: GoogleFonts.amita()),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Got it!', style: GoogleFonts.amita()),
          ),
        ],
      ),
    );
  }
}