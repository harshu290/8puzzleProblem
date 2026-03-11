import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const EightPuzzleApp());
}
class EightPuzzleApp extends StatefulWidget {
  const EightPuzzleApp({super.key});
  static _EightPuzzleAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_EightPuzzleAppState>();
  @override
  State<EightPuzzleApp> createState() => _EightPuzzleAppState();
}

class _EightPuzzleAppState extends State<EightPuzzleApp> {
  ThemeMode _themeMode = ThemeMode.dark;

  void toggleTheme() =>
      setState(() => _themeMode =
      _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);

  bool get isDark => _themeMode == ThemeMode.dark;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '8 Puzzle Game',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6C63FF), brightness: Brightness.light),
        scaffoldBackgroundColor: const Color(0xFFF5F3FF),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6C63FF), brightness: Brightness.dark),
        scaffoldBackgroundColor: const Color(0xFF0F0E17),
      ),
      home: const SplashScreen(),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  SPLASH SCREEN
// ═══════════════════════════════════════════════════════════
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale, _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
    Future.delayed(const Duration(seconds: 2), _navigate);
  }

  Future<void> _navigate() async {
    final prefs = await SharedPreferences.getInstance();
    final user  = prefs.getString('current_user');
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(
      builder: (_) => user != null ? const HomeScreen() : const AuthScreen(),
    ));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF0F0E17), const Color(0xFF1A1A2E)]
                : [const Color(0xFF6C63FF), const Color(0xFFFF6584)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 120, height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(38),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                        color: Colors.white.withAlpha(76), width: 2),
                  ),
                  child: const Center(
                      child: Text('🧩',
                          style: TextStyle(fontSize: 64))),
                ),
                const SizedBox(height: 24),
                const Text('8 Puzzle',
                    style: TextStyle(fontSize: 48,
                        fontWeight: FontWeight.w900, color: Colors.white)),
                const Text('A* Algorithm Solver',
                    style: TextStyle(fontSize: 16,
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2)),
                const SizedBox(height: 40),
                const CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  AUTH SCREEN
// ═══════════════════════════════════════════════════════════
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _luCtrl = TextEditingController();
  final _lpCtrl = TextEditingController();
  final _suCtrl = TextEditingController();
  final _spCtrl = TextEditingController();
  final _sp2Ctrl= TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() => setState(() => _error = null));
  }

  @override
  void dispose() {
    _tab.dispose();
    _luCtrl.dispose(); _lpCtrl.dispose();
    _suCtrl.dispose(); _spCtrl.dispose(); _sp2Ctrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() { _loading = true; _error = null; });
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('pass_${_luCtrl.text.trim()}');
    if (saved == null || saved != _lpCtrl.text.trim()) {
      setState(() { _loading = false; _error = 'Invalid username or password.'; });
      return;
    }
    await prefs.setString('current_user', _luCtrl.text.trim());
    setState(() => _loading = false);
    if (mounted) Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => const HomeScreen()));
  }

  Future<void> _signup() async {
    if (_spCtrl.text != _sp2Ctrl.text) {
      setState(() => _error = 'Passwords do not match!'); return;
    }
    if (_suCtrl.text.trim().length < 3) {
      setState(() => _error = 'Username must be 3+ characters.'); return;
    }
    if (_spCtrl.text.trim().length < 4) {
      setState(() => _error = 'Password must be 4+ characters.'); return;
    }
    setState(() { _loading = true; _error = null; });
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString('pass_${_suCtrl.text.trim()}') != null) {
      setState(() { _loading = false; _error = 'Username already taken.'; });
      return;
    }
    await prefs.setString('pass_${_suCtrl.text.trim()}', _spCtrl.text.trim());
    await prefs.setString('current_user', _suCtrl.text.trim());
    setState(() => _loading = false);
    if (mounted) Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => const HomeScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF0F0E17), const Color(0xFF1A1A2E)]
                : [const Color(0xFFF5F3FF), const Color(0xFFEDE9FF)],
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(children: [
              const SizedBox(height: 40),
              const Text('🧩', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 12),
              Text('8 Puzzle Game', style: TextStyle(
                  fontSize: 34, fontWeight: FontWeight.w900,
                  color: cs.primary)),
              const SizedBox(height: 6),
              Text('Sign in to save your scores!', style: TextStyle(
                  color: cs.onSurface.withAlpha(153),
                  fontWeight: FontWeight.w600)),
              const SizedBox(height: 36),

              // Tab bar
              Container(
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withAlpha(128),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: TabBar(
                  controller: _tab,
                  dividerColor: Colors.transparent,
                  indicator: BoxDecoration(
                      color: cs.primary,
                      borderRadius: BorderRadius.circular(50)),
                  labelColor: Colors.white,
                  unselectedLabelColor: cs.onSurface.withAlpha(153),
                  labelStyle: const TextStyle(fontWeight: FontWeight.w800),
                  tabs: const [Tab(text: 'Login'), Tab(text: 'Sign Up')],
                ),
              ),

              const SizedBox(height: 24),

              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withAlpha(76)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_error!,
                        style: const TextStyle(color: Colors.red,
                            fontWeight: FontWeight.w600, fontSize: 13))),
                  ]),
                ),

              SizedBox(
                height: 330,
                child: TabBarView(
                  controller: _tab,
                  children: [
                    // LOGIN
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _field(_luCtrl, 'Username', Icons.person),
                          const SizedBox(height: 16),
                          _field(_lpCtrl, 'Password', Icons.lock, obscure: true),
                          const SizedBox(height: 28),
                          _submitBtn('Login ', _login),
                        ]),
                    // SIGNUP
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _field(_suCtrl, 'Username', Icons.person),
                          const SizedBox(height: 14),
                          _field(_spCtrl, 'Password', Icons.lock, obscure: true),
                          const SizedBox(height: 14),
                          _field(_sp2Ctrl, 'Confirm Password',
                              Icons.lock_outline, obscure: true),
                          const SizedBox(height: 24),
                          _submitBtn('Create Account ', _signup),
                        ]),
                  ],
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String hint,
      IconData icon, {bool obscure = false}) {
    final cs = Theme.of(context).colorScheme;
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      style: const TextStyle(fontWeight: FontWeight.w700),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: cs.primary),
        filled: true,
        fillColor: cs.surface,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: cs.primary, width: 2)),
      ),
    );
  }

  Widget _submitBtn(String label, VoidCallback onTap) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: _loading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
        ),
        child: _loading
            ? const SizedBox(width: 22, height: 22,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: Colors.white))
            : Text(label, style: const TextStyle(
            fontSize: 16, fontWeight: FontWeight.w800)),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  HOME SCREEN
// ═══════════════════════════════════════════════════════════
enum Difficulty { easy, medium, hard }

extension DifficultyExt on Difficulty {
  String get label {
    switch (this) {
      case Difficulty.easy:   return 'Easy';
      case Difficulty.medium: return 'Medium';
      case Difficulty.hard:   return 'Hard';
    }
  }
  int get shuffleMoves {
    switch (this) {
      case Difficulty.easy:   return 20;
      case Difficulty.medium: return 50;
      case Difficulty.hard:   return 100;
    }
  }
  String get emoji {
    switch (this) {
      case Difficulty.easy:   return '🟢';
      case Difficulty.medium: return '🟡';
      case Difficulty.hard:   return '🔴';
    }
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Difficulty _selected = Difficulty.medium;
  String _username = 'Player';

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() =>
    _username = prefs.getString('current_user') ?? 'Player');
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_user');
    if (mounted) Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => const AuthScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final cs     = Theme.of(context).colorScheme;
    final appState = EightPuzzleApp.of(context);
    final isDark   = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF0F0E17), const Color(0xFF1A1A2E)]
                : [const Color(0xFFF5F3FF), const Color(0xFFEDE9FF)],
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // Top bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Hey, $_username 👋',
                              style: TextStyle(fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: cs.primary)),
                          Text('Ready to solve?',
                              style: TextStyle(
                                  color: cs.onSurface.withAlpha(128),
                                  fontWeight: FontWeight.w600)),
                        ]),
                    Row(children: [
                      _iconBtn(
                          icon: isDark
                              ? Icons.light_mode_rounded
                              : Icons.dark_mode_rounded,
                          onTap: () => appState?.toggleTheme()),
                      const SizedBox(width: 8),
                      _iconBtn(
                          icon: Icons.logout_rounded,
                          onTap: _logout),
                    ]),
                  ],
                ),

                const SizedBox(height: 40),

                // Hero icon
                Center(
                  child: Container(
                    width: 150, height: 150,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [cs.primary, cs.tertiary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(36),
                      boxShadow: [BoxShadow(
                        color: cs.primary.withAlpha(102),
                        blurRadius: 32, offset: const Offset(0, 12),
                      )],
                    ),
                    child: const Center(
                        child: Text('🧩',
                            style: TextStyle(fontSize: 80))),
                  ),
                ),

                const SizedBox(height: 20),

                Center(child: Text('8 Puzzle Game',
                    style: TextStyle(fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: cs.primary))),
                Center(child: Text('A* Algorithm Solver',
                    style: TextStyle(
                        color: cs.onSurface.withAlpha(128),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5))),

                const SizedBox(height: 36),

                Text('Select Difficulty',
                    style: TextStyle(fontWeight: FontWeight.w800,
                        fontSize: 16, color: cs.onSurface)),
                const SizedBox(height: 14),

                // Difficulty selector
                Row(
                  children: Difficulty.values.map((d) {
                    final sel = _selected == d;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selected = d),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: sel ? cs.primary
                                : cs.surfaceContainerHighest.withAlpha(128),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: sel ? [BoxShadow(
                              color: cs.primary.withAlpha(89),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            )] : [],
                          ),
                          child: Column(children: [
                            Text(d.emoji,
                                style: const TextStyle(fontSize: 22)),
                            const SizedBox(height: 4),
                            Text(d.label,
                                style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    color: sel ? Colors.white
                                        : cs.onSurface.withAlpha(178))),
                          ]),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const Spacer(),

                // Play button
                SizedBox(
                  width: double.infinity, height: 60,
                  child: ElevatedButton(
                    onPressed: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) =>
                            GameScreen(difficulty: _selected))),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      elevation: 8,
                      shadowColor: cs.primary.withAlpha(128),
                    ),
                    child: const Text('Play Now ',
                        style: TextStyle(fontSize: 22,
                            fontWeight: FontWeight.w900)),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _iconBtn({required IconData icon, required VoidCallback? onTap}) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withAlpha(153),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 20, color: cs.onSurface),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  PUZZLE MODEL + A* SOLVER
// ═══════════════════════════════════════════════════════════
class PuzzleModel {
  static const List<int> goalState = [1,2,3,4,5,6,7,8,0];
  List<int> state;
  int moveCount;
  bool isSolved;

  PuzzleModel({required this.state, this.moveCount = 0,
    this.isSolved = false});

  factory PuzzleModel.shuffled(Difficulty difficulty) {
    final m = PuzzleModel(state: List.from(goalState));
    m._shuffle(difficulty.shuffleMoves);
    return m;
  }

  void _shuffle(int moves) {
    final rand = Random();
    int blank = state.indexOf(0);
    for (int i = 0; i < moves; i++) {
      final nb = _getNeighbors(blank);
      final pick = nb[rand.nextInt(nb.length)];
      _swap(blank, pick);
      blank = pick;
    }
  }

  List<int> _getNeighbors(int idx) {
    final nb = <int>[];
    final r = idx ~/ 3, c = idx % 3;
    if (r > 0) nb.add(idx - 3);
    if (r < 2) nb.add(idx + 3);
    if (c > 0) nb.add(idx - 1);
    if (c < 2) nb.add(idx + 1);
    return nb;
  }

  bool canMove(int idx) =>
      _getNeighbors(state.indexOf(0)).contains(idx);

  bool move(int idx) {
    if (!canMove(idx)) return false;
    final blank = state.indexOf(0);
    _swap(blank, idx);
    moveCount++;
    isSolved = _checkSolved();
    return true;
  }

  void _swap(int a, int b) {
    final t = state[a]; state[a] = state[b]; state[b] = t;
  }

  bool _checkSolved() {
    for (int i = 0; i < 9; i++) {
      if (state[i] != goalState[i]) return false;
    }
    return true;
  }

  // ── A* ──────────────────────────────────────────────────
  static int _manhattan(List<int> s) {
    int d = 0;
    for (int i = 0; i < 9; i++) {
      if (s[i] == 0) continue;
      final g = s[i] - 1;
      d += (i ~/ 3 - g ~/ 3).abs() + (i % 3 - g % 3).abs();
    }
    return d;
  }

  static List<Map<String, int>>? solve(List<int> start) {
    bool solved(List<int> s) {
      for (int i = 0; i < 9; i++) {
        if (s[i] != goalState[i]) return false;
      }
      return true;
    }

    if (solved(start)) return [];

    final open = <_ANode>[];
    final gScore = <String, int>{};
    final cameFrom = <String, _ACameFrom>{};
    final startKey = start.join(',');

    gScore[startKey] = 0;
    open.add(_ANode(state: List.from(start), g: 0,
        f: _manhattan(start), key: startKey));

    while (open.isNotEmpty) {
      open.sort((a, b) => a.f - b.f);
      final cur = open.removeAt(0);

      if (solved(cur.state)) {
        final path = <Map<String, int>>[];
        String k = cur.key;
        while (cameFrom.containsKey(k)) {
          final cf = cameFrom[k]!;
          path.insert(0,
              {'from': cf.from, 'to': cf.to, 'tile': cf.tile});
          k = cf.prevKey;
        }
        return path;
      }

      final blank = cur.state.indexOf(0);
      final r = blank ~/ 3, c = blank % 3;
      final nb = <int>[];
      if (r > 0) nb.add(blank - 3);
      if (r < 2) nb.add(blank + 3);
      if (c > 0) nb.add(blank - 1);
      if (c < 2) nb.add(blank + 1);

      for (final nIdx in nb) {
        final ns = List<int>.from(cur.state);
        final tile = ns[nIdx];
        ns[nIdx] = 0; ns[blank] = tile;
        final nk = ns.join(',');
        final tg = cur.g + 1;
        if (!gScore.containsKey(nk) || tg < gScore[nk]!) {
          gScore[nk] = tg;
          open.add(_ANode(state: ns, g: tg,
              f: tg + _manhattan(ns), key: nk));
          cameFrom[nk] = _ACameFrom(
              prevKey: cur.key, from: nIdx, to: blank, tile: tile);
        }
      }
    }
    return null;
  }
}

class _ANode {
  final List<int> state;
  final int g, f;
  final String key;
  _ANode({required this.state, required this.g,
    required this.f, required this.key});
}

class _ACameFrom {
  final String prevKey;
  final int from, to, tile;
  _ACameFrom({required this.prevKey, required this.from,
    required this.to, required this.tile});
}

// ═══════════════════════════════════════════════════════════
//  GAME SCREEN
// ═══════════════════════════════════════════════════════════
class GameScreen extends StatefulWidget {
  final Difficulty difficulty;
  const GameScreen({super.key, required this.difficulty});
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late PuzzleModel _puzzle;
  late Timer _timer;
  int _seconds = 0;
  bool _running = false;
  bool _solving = false;
  bool _solved  = false;
  int  _highlightIdx = -1;
  Timer? _animTimer;

  static const List<Color> _tileColors = [
    Colors.transparent,
    Color(0xFFFF6B6B),
    Color(0xFFFFD93D),
    Color(0xFF6BCB77),
    Color(0xFF4D96FF),
    Color(0xFFC77DFF),
    Color(0xFFFF9A3C),
    Color(0xFF00D2FF),
    Color(0xFFFF6FAA),
  ];

  @override
  void initState() {
    super.initState();
    _puzzle = PuzzleModel.shuffled(widget.difficulty);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_running && mounted) setState(() => _seconds++);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _animTimer?.cancel();
    super.dispose();
  }

  String get _timeStr {
    final m = _seconds ~/ 60;
    final s = _seconds % 60;
    return '${m.toString().padLeft(2,'0')}:${s.toString().padLeft(2,'0')}';
  }

  void _onTap(int idx) {
    if (_solving || _solved || !_puzzle.canMove(idx)) return;
    setState(() {
      _running = true;
      _puzzle.move(idx);
      if (_puzzle.isSolved) _onSolved();
    });
  }

  void _onSolved() {
    _running = false;
    _solved  = true;
    _saveScore();
    Future.delayed(const Duration(milliseconds: 400), _showWin);
  }

  Future<void> _saveScore() async {
    final prefs = await SharedPreferences.getInstance();
    final user = prefs.getString('current_user') ?? '';
    final key  = 'best_${user}_${widget.difficulty.label}';
    final cur  = prefs.getInt(key) ?? 9999;
    if (_puzzle.moveCount < cur) await prefs.setInt(key, _puzzle.moveCount);
  }

  void _showWin() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _WinDialog(
        moves: _puzzle.moveCount,
        seconds: _seconds,
        difficulty: widget.difficulty,
        onPlayAgain: () { Navigator.pop(context); _restart(); },
        onHome: () { Navigator.pop(context); Navigator.pop(context); },
      ),
    );
  }

  void _restart() {
    _animTimer?.cancel();
    setState(() {
      _puzzle = PuzzleModel.shuffled(widget.difficulty);
      _seconds = 0; _running = false; _solved = false;
      _solving = false; _highlightIdx = -1;
    });
  }

  void _autoSolve() async {
    if (_solved) return;
    setState(() { _solving = true; _running = true; });
    final sol = await Future.microtask(
            () => PuzzleModel.solve(List.from(_puzzle.state)));
    if (sol == null || !mounted) {
      setState(() => _solving = false); return;
    }
    int step = 0;
    _animTimer = Timer.periodic(
        const Duration(milliseconds: 450), (_) {
      if (step >= sol.length) { _animTimer?.cancel(); return; }
      final s = sol[step];
      setState(() {
        _highlightIdx = s['from']!;
        _puzzle.move(s['from']!);
        step++;
        if (_puzzle.isSolved) _onSolved();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs     = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF0F0E17), const Color(0xFF1A1A2E)]
                : [const Color(0xFFF5F3FF), const Color(0xFFEDE9FF)],
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(children: [
              const SizedBox(height: 16),

              // App bar
              Row(children: [
                _iconBtn(Icons.arrow_back_rounded,
                        () => Navigator.pop(context)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: cs.primary.withAlpha(38),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Text(
                    '${widget.difficulty.emoji} ${widget.difficulty.label}',
                    style: TextStyle(fontWeight: FontWeight.w800,
                        color: cs.primary),
                  ),
                ),
                const Spacer(),
                _iconBtn(Icons.refresh_rounded, _restart),
              ]),

              const SizedBox(height: 24),

              // Stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _statBox('⏱️', _timeStr, 'Time'),
                  _statBox('👆', '${_puzzle.moveCount}', 'Moves'),
                  _statBox('🧩',
                      '${_puzzle.state.where((v) => v != 0 &&
                          _puzzle.state.indexOf(v) == v - 1).length}/8',
                      'Correct'),
                ],
              ),

              const SizedBox(height: 28),

              // Board
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1A1A2E) : Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [BoxShadow(
                          color: Colors.black.withAlpha(76),
                          blurRadius: 32,
                          offset: const Offset(0, 12),
                        )],
                      ),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                        ),
                        itemCount: 9,
                        itemBuilder: (_, idx) => _buildTile(idx),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Buttons
              Row(children: [
                Expanded(child: _actionBtn(
                  label: _solving ? 'Solving...' : '🤖 Auto Solve',
                  onTap: _solving || _solved ? null : _autoSolve,
                  color: cs.primary,
                )),
                const SizedBox(width: 12),
                Expanded(child: _actionBtn(
                  label: '🔀 Shuffle',
                  onTap: _solving ? null : _restart,
                  color: const Color(0xFFFF9A3C),
                )),
              ]),

              const SizedBox(height: 24),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildTile(int idx) {
    final val     = _puzzle.state[idx];
    final isEmpty = val == 0;
    final isHl    = idx == _highlightIdx;
    final cs      = Theme.of(context).colorScheme;

    if (isEmpty) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: cs.onSurface.withAlpha(25), width: 2),
        ),
      );
    }

    return GestureDetector(
      onTap: () => _onTap(idx),
      child: AnimatedScale(
        scale: isHl ? 1.08 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_tileColors[val],
                _tileColors[val].withAlpha(191)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(
              color: _tileColors[val].withAlpha(128),
              blurRadius: isHl ? 16 : 8,
              offset: const Offset(0, 4),
            )],
          ),
          child: Center(
            child: Text('$val',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: val == 2
                    ? const Color(0xFF333333) : Colors.white,
                shadows: [Shadow(
                  color: Colors.black.withAlpha(51),
                  offset: const Offset(0, 2),
                  blurRadius: 4,
                )],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _statBox(String emoji, String val, String label) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withAlpha(128),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 2),
        Text(val, style: TextStyle(fontSize: 20,
            fontWeight: FontWeight.w900, color: cs.primary)),
        Text(label, style: TextStyle(fontSize: 11,
            fontWeight: FontWeight.w700,
            color: cs.onSurface.withAlpha(128),
            letterSpacing: 1)),
      ]),
    );
  }

  Widget _actionBtn({required String label,
    required VoidCallback? onTap, required Color color}) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          disabledBackgroundColor: color.withAlpha(102),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          elevation: 6,
          shadowColor: color.withAlpha(102),
        ),
        child: Text(label, style: const TextStyle(
            fontSize: 15, fontWeight: FontWeight.w800)),
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withAlpha(153),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 22),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  WIN DIALOG
// ═══════════════════════════════════════════════════════════
class _WinDialog extends StatelessWidget {
  final int moves, seconds;
  final Difficulty difficulty;
  final VoidCallback onPlayAgain, onHome;

  const _WinDialog({required this.moves, required this.seconds,
    required this.difficulty, required this.onPlayAgain,
    required this.onHome});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final m  = seconds ~/ 60;
    final s  = seconds % 60;
    return Dialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('🎉', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 12),
          Text('Puzzle Solved!', style: TextStyle(
              fontSize: 32, fontWeight: FontWeight.w900,
              color: cs.primary)),
          const SizedBox(height: 6),
          Text('${difficulty.emoji} ${difficulty.label} Mode',
              style: TextStyle(fontWeight: FontWeight.w700,
                  color: cs.onSurface.withAlpha(128))),
          const SizedBox(height: 24),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _chip('👆', '$moves', 'Moves'),
                _chip('⏱️',
                    '${m.toString().padLeft(2,'0')}:${s.toString().padLeft(2,'0')}',
                    'Time'),
              ]),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onPlayAgain,
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Play Again 🔀',
                  style: TextStyle(fontSize: 16,
                      fontWeight: FontWeight.w800)),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: onHome,
            child: Text('Back to Home',
                style: TextStyle(fontWeight: FontWeight.w700,
                    color: cs.onSurface.withAlpha(128))),
          ),
        ]),
      ),
    );
  }

  Widget _chip(String emoji, String val, String label) =>
      Column(children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        Text(val, style: const TextStyle(fontSize: 26,
            fontWeight: FontWeight.w900)),
        Text(label, style: const TextStyle(fontSize: 12,
            fontWeight: FontWeight.w700)),
      ]);
}