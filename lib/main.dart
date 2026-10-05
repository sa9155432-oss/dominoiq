import 'package:flutter/material.dart';
import 'dart:math';

void main() {
  runApp(const DominoApp());
}

class DominoApp extends StatelessWidget {
  const DominoApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'دومينو احترافية - Alpha',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF132F3F), // لون خلفية داكن مشابه للصور
        useMaterial3: true,
      ),
      home: const DominoMenuPage(),
    );
  }
}

class DominoTile {
  final int left;
  final int right;
  bool isFaceUp;

  DominoTile(this.left, this.right, {this.isFaceUp = true});

  int get sum => left + right;
  bool get isDouble => left == right;
}

class DominoMenuPage extends StatelessWidget {
  const DominoMenuPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('دومينو الاحترافية', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: const Color(0xFF0B1D28),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.casino_rounded, size: 90, color: Colors.amberAccent),
              const SizedBox(height: 24),
              const Text(
                'اختر نمط اللعب يا boss man',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white70),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DominoGamePage(playersCount: 2))),
                  icon: const Icon(Icons.person),
                  label: const Text('لعب فردي (ضد بوت)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B3B4B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DominoGamePage(playersCount: 4))),
                  icon: const Icon(Icons.people),
                  label: const Text('لعب جماعي (4 لاعبين)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B3B4B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DominoGamePage extends StatefulWidget {
  final int playersCount;
  const DominoGamePage({Key? key, required this.playersCount}) : super(key: key);

  @override
  State<DominoGamePage> createState() => _DominoGamePageState();
}

class _DominoGamePageState extends State<DominoGamePage> {
  List<DominoTile> stockPile = [];
  List<List<DominoTile>> playersHands = [];
  List<DominoTile> boardTiles = [];
  int currentTurn = 0;
  String gameMessage = 'دورك للعب يا boss man.';
  int? boardLeftEnd;
  int? boardRightEnd;

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  void _initializeGame() {
    stockPile.clear();
    boardTiles.clear();
    playersHands = List.generate(widget.playersCount, (_) => []);
    boardLeftEnd = null;
    boardRightEnd = null;

    List<DominoTile> allTiles = [];
    for (int i = 0; i <= 6; i++) {
      for (int j = i; j <= 6; j++) {
        allTiles.add(DominoTile(i, j));
      }
    }
    allTiles.shuffle(Random());

    int tilesPerPlayer = widget.playersCount == 2 ? 7 : 5;
    for (int p = 0; p < widget.playersCount; p++) {
      for (int t = 0; t < tilesPerPlayer; t++) {
        playersHands[p].add(allTiles.removeAt(0));
      }
    }
    stockPile = allTiles;
    currentTurn = 0;
    gameMessage = 'ابدأ اللعب يا boss man.';
    setState(() {});
  }

  void _playTile(int playerIndex, DominoTile tile, bool playOnRight) {
    if (boardTiles.isEmpty) {
      boardTiles.add(tile);
      boardLeftEnd = tile.left;
      boardRightEnd = tile.right;
    } else {
      if (playOnRight) {
        if (tile.left == boardRightEnd) {
          boardRightEnd = tile.right;
          boardTiles.add(tile);
        } else if (tile.right == boardRightEnd) {
          boardRightEnd = tile.left;
          boardTiles.add(DominoTile(tile.right, tile.left));
        }
      } else {
        if (tile.right == boardLeftEnd) {
          boardLeftEnd = tile.left;
          boardTiles.insert(0, tile);
        } else if (tile.left == boardLeftEnd) {
          boardLeftEnd = tile.right;
          boardTiles.insert(0, DominoTile(tile.right, tile.left));
        }
      }
    }
    playersHands[playerIndex].remove(tile);
  }

  void _playerAttemptPlay(DominoTile tile) {
    if (currentTurn != 0) return;

    if (boardTiles.isEmpty) {
      setState(() {
        _playTile(0, tile, true);
        _advanceTurn();
      });
      return;
    }

    bool matchesLeft = (tile.left == boardLeftEnd || tile.right == boardLeftEnd);
    bool matchesRight = (tile.left == boardRightEnd || tile.right == boardRightEnd);

    if (matchesLeft && matchesRight) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1B3B4B),
          title: const Text('اختر مكان اللعب'),
          content: const Text('هذا الحجر يناسب الطرفين، أين تريد وضعه؟'),
          actions: [
            TextButton(onPressed: () { Navigator.pop(ctx); setState(() { _playTile(0, tile, false); _advanceTurn(); }); }, child: const Text('اليسار')),
            TextButton(onPressed: () { Navigator.pop(ctx); setState(() { _playTile(0, tile, true); _advanceTurn(); }); }, child: const Text('اليمين')),
          ],
        ),
      );
    } else if (matchesLeft) {
      setState(() {
        _playTile(0, tile, false);
        _advanceTurn();
      });
    } else if (matchesRight) {
      setState(() {
        _playTile(0, tile, true);
        _advanceTurn();
      });
    } else {
      setState(() {
        gameMessage = 'هذا الحجر لا يناسب الأطراف الحالية!';
      });
    }
  }

  void _advanceTurn() {
    if (playersHands[0].isEmpty) {
      _showGameOverDialog('تهانينا! أنت الفائز يا boss man.');
      return;
    }

    for (int i = 1; i < widget.playersCount; i++) {
      if (playersHands[i].isEmpty) {
        _showGameOverDialog('فاز البوت رقم $i. حاول مرة أخرى.');
        return;
      }
    }

    currentTurn = (currentTurn + 1) % widget.playersCount;
    if (currentTurn != 0) {
      _executeAiTurn(currentTurn);
    } else {
      setState(() {
        gameMessage = 'دورك للعب يا boss man.';
      });
    }
  }

  void _executeAiTurn(int aiIndex) {
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      DominoTile? playableTile;
      bool playRight = true;

      for (var tile in playersHands[aiIndex]) {
        if (boardTiles.isEmpty) {
          playableTile = tile;
          break;
        }
        if (tile.left == boardRightEnd || tile.right == boardRightEnd) {
          playableTile = tile;
          playRight = true;
          break;
        }
        if (tile.left == boardLeftEnd || tile.right == boardLeftEnd) {
          playableTile = tile;
          playRight = false;
          break;
        }
      }

      setState(() {
        if (playableTile != null) {
          _playTile(aiIndex, playableTile, playRight);
          gameMessage = 'البوت رقم $aiIndex لعب حجراً.';
        } else if (stockPile.isNotEmpty) {
          playersHands[aiIndex].add(stockPile.removeAt(0));
          gameMessage = 'البوت رقم $aiIndex سحب من البنك.';
        } else {
          gameMessage = 'البوت رقم $aiIndex تخطى دوره.';
        }
        _advanceTurn();
      });
    });
  }

  void _showGameOverDialog(String title) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1B3B4B),
        title: Text(title),
        content: const Text('هل تريد بدء جولة جديدة؟'),
        actions: [
          TextButton(onPressed: () { Navigator.pop(ctx); _initializeGame(); }, child: const Text('إعادة اللعب')),
        ],
      ),
    );
  }

  // رسم حجر دومينو واقعي مشابه للصور المطلوبة[span_5](start_span)[span_5](end_span)[span_6](start_span)[span_6](end_span)[span_7](start_span)[span_7](end_span)[span_8](start_span)[span_8](end_span)[span_9](start_span)[span_9](end_span)
  Widget _buildDominoTileWidget(DominoTile tile, {bool isPlayable = true, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 85,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: isPlayable ? Colors.white : Colors.grey.shade400,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.black87, width: 1.5),
          boxShadow: const [
            BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2))
          ],
        ),
        child: Column(
          children: [
            Expanded(child: Center(child: Text('${tile.left}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black)))),
            Container(height: 1, color: Colors.black54),
            Expanded(child: Center(child: Text('${tile.right}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black)))),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('دومينو', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: const Color(0xFF0B1D28),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Text('${stockPile.length}/14', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amberAccent)),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          // معلومات الخصم العلوي
          Container(
            padding: const EdgeInsets.all(8),
            color: const Color(0xFF0B1D28),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircleAvatar(radius: 16, backgroundColor: Colors.amber, child: Icon(Icons.person, size: 18, color: Colors.black)),
                const SizedBox(width: 8),
                Text('الخصم (متبقي: ${playersHands.length > 1 ? playersHands[1].length : 0})', style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),

          // طاولة اللعب الاحترافية
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF102634),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Center(
                child: boardTiles.isEmpty
                    ? const Text('الطاولة فارغة، العب أول حجر', style: TextStyle(color: Colors.white57))
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: boardTiles.map((tile) => _buildDominoTileWidget(tile, isPlayable: false)).toList(),
                        ),
                      ),
              ),
            ),
          ),

          // رسالة الحالة والنتيجة السفلية
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(gameMessage, style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold)),
                const Text('النتيجة: 0/100', style: TextStyle(color: Colors.white54)),
              ],
            ),
          ),

          // أحجار اللاعب في الأسفل
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF0B1D28),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                SizedBox(
                  height: 90,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: playersHands[0].length,
                    itemBuilder: (ctx, idx) {
                      final tile = playersHands[0][idx];
                      return _buildDominoTileWidget(
                        tile,
                        isPlayable: currentTurn == 0,
                        onTap: currentTurn == 0 ? () => _playerAttemptPlay(tile) : null,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
