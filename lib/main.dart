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
      title: 'لعبة الدومينو - Alpha',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      home: const DominoMenuPage(),
    );
  }
}

// ==========================================
// نموذج حجر الدومينو
// ==========================================
class DominoTile {
  final int left;
  final int right;
  bool isFaceUp;

  DominoTile(this.left, this.right, {this.isFaceUp = true});

  int get sum => left + right;
  bool get isDouble => left == right;
}

// ==========================================
// صفحة القائمة الرئيسية
// ==========================================
class DominoMenuPage extends StatelessWidget {
  const DominoMenuPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('طاولة الدومينو اللعينة', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.casino_rounded, size: 80, color: scheme.primary),
              const SizedBox(height: 24),
              Text(
                'اختر نمط اللعب يا boss man',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: scheme.onSurface),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DominoGamePage(playersCount: 2))),
                  icon: const Icon(Icons.person_outline),
                  label: const Text('لعب فردي (ضد بوت - لاعبين اثنين)'),
                  style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DominoGamePage(playersCount: 4))),
                  icon: const Icon(Icons.people_outline),
                  label: const Text('لعب جماعي (4 لاعبين وبوتات)'),
                  style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// صفحة اللعب الرئيسية
// ==========================================
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
  int currentTurn = 0; // 0 = Player, others = AI bots
  String gameMessage = 'ابدأ اللعب يا boss man!';
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

    // توليد حجارة الدومينو (من 0-0 إلى 6-6)
    List<DominoTile> allTiles = [];
    for (int i = 0; i <= 6; i++) {
      for (int j = i; j <= 6; j++) {
        allTiles.add(DominoTile(i, j));
      }
    }
    allTiles.shuffle(Random());

    // توزيع الحجارة (7 لكل لاعب في حالة لاعبين، أو 5 في حالة 4 لاعبين)
    int tilesPerPlayer = widget.playersCount == 2 ? 7 : 5;
    for (int p = 0; p < widget.playersCount; p++) {
      for (int t = 0; t < tilesPerPlayer; t++) {
        playersHands[p].add(allTiles.removeAt(0));
      }
    }
    stockPile = allTiles;
    currentTurn = 0;
    gameMessage = 'دورك للعب يا boss man.';
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
          // عكس الحجر إذا تطلب الأمر
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

  bool _canPlayAny(int playerIndex) {
    if (boardTiles.isEmpty) return true;
    for (var tile in playersHands[playerIndex]) {
      if (tile.left == boardLeftEnd || tile.right == boardLeftEnd ||
          tile.left == boardRightEnd || tile.right == boardRightEnd) {
        return true;
      }
    }
    return false;
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

    // التحقق من إمكانية اللعب يساراً أو يميناً
    bool matchesLeft = (tile.left == boardLeftEnd || tile.right == boardLeftEnd);
    bool matchesRight = (tile.left == boardRightEnd || tile.right == boardRightEnd);

    if (matchesLeft && matchesRight) {
      // إظهار خيار للعميل
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
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
        gameMessage = 'هذا الحجر لا يناسب الأطراف الحالية يا boss man!';
      });
    }
  }

  void _advanceTurn() {
    // التحقق من الفوز
    if (playersHands[0].isEmpty) {
      gameMessage = 'لقد فزت باللعبة يا boss man!';
      _showGameOverDialog('تهانينا! أنت الفائز.');
      return;
    }

    for (int i = 1; i < widget.playersCount; i++) {
      if (playersHands[i].isEmpty) {
        gameMessage = 'اللاعب الآلي رقم $i فاز باللعبة!';
        _showGameOverDialog('فاز البوت رقم $i. حاول مرة أخرى.');
        return;
      }
    }

    currentTurn = (currentTurn + 1) % widget.playersCount;
    
    // إذا كان الدور للـ AI
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
      
      // ذكاء اصطناعي بسيط: البحث عن أول حجر صالح واللعب به
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
          // سحب من البنك إذا لم يجد حجراً
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
        title: Text(title),
        content: const Text('هل تريد بدء جولة جديدة؟'),
        actions: [
          TextButton(onPressed: () { Navigator.pop(ctx); _initializeGame(); }, child: const Text('إعادة اللعب')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('طاولة الدومينو (${widget.playersCount} لاعبين)'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // لوحة الرسائل وحالة اللعبة
          Container(
            padding: const EdgeInsets.all(12),
            color: scheme.surfaceContainerHighest.withOpacity(0.5),
            width: double.infinity,
            child: Text(
              gameMessage,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: scheme.primary),
            ),
          ),
          
          // مساحة اللعب (الطاولة الوسطية)
          Expanded(
            flex: 3,
            child: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.teal.shade900,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: boardTiles.isEmpty
                    .isNotEmpty == true && false // تعبير بسيط
                    ? const Text('الطاولة فارغة، العب أول حجر', style: TextStyle(color: Colors.white70))
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: boardTiles.map((tile) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${tile.left} | ${tile.right}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),
                            ),
                          )).toList(),
                        ),
                      ),
              ),
            ),
          ),

          // معلومات البنك والأطراف الحالية
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('الحجارة المتبقية بالبنك: ${stockPile.length}'),
                Text('الأطراف: [${boardLeftEnd ?? "?"} ... ${boardRightEnd ?? "?"}]', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const Divider(),

          // أوراق اللاعب الحالي (أنت)
          Expanded(
            flex: 2,
            child: Column(
              children: [
                const Text('أحجارك يا boss man:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: playersHands[0].length,
                    itemBuilder: (ctx, idx) {
                      final tile = playersHands[0][idx];
                      return GestureDetector(
                        onTap: currentTurn == 0 ? () => _playerAttemptPlay(tile) : null,
                        child: Container(
                          width: 60,
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(
                            color: currentTurn == 0 ? Colors.amber.shade100 : Colors.grey.shade300,
                            border: Border.all(color: Colors.black, width: 2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('${tile.left}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              const Divider(color: Colors.black, thickness: 1, height: 4),
                              Text('${tile.right}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (currentTurn == 0 && !_canPlayAny(0) && stockPile.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          playersHands[0].add(stockPile.removeAt(0));
                          gameMessage = 'سحبت حجراً من البنك يا boss man.';
                        });
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('سحب حجر من البنك'),
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
