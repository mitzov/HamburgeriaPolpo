import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// ============================================================
// ENTRY POINT
// ============================================================
void main() {
  runApp(const TotemApp());
}

// ============================================================
// COSTANTI
// ============================================================
const String kBaseUrl = 'http://localhost:5000/api';

// Palette colori
const Color kBg = Color(0xFF0F0F0F);
const Color kSurface = Color(0xFF1A1A1A);
const Color kCard = Color(0xFF242424);
const Color kAccent = Color(0xFFFF6B35);
const Color kAccentLight = Color(0xFFFF8C5A);
const Color kGold = Color(0xFFFFD166);
const Color kText = Color(0xFFF5F5F0);
const Color kTextMuted = Color(0xFF888884);
const Color kGreen = Color(0xFF06D6A0);
const Color kRed = Color(0xFFEF476F);

// ============================================================
// MODELLI
// ============================================================

class Categoria {
  final int id;
  final String nome;
  final String descrizione;
  final int ordineVisualizzazione;

  Categoria({
    required this.id,
    required this.nome,
    required this.descrizione,
    required this.ordineVisualizzazione,
  });

  factory Categoria.fromJson(Map<String, dynamic> j) => Categoria(
        id: j['id'],
        nome: j['nome'] ?? '',
        descrizione: j['descrizione'] ?? '',
        ordineVisualizzazione: j['ordine_visualizzazione'] ?? 0,
      );
}

class Prodotto {
  final int id;
  final int idCategoria;
  final String nome;
  final String descrizione;
  final double prezzo;
  final bool disponibile;
  final String? immagineUrl;

  Prodotto({
    required this.id,
    required this.idCategoria,
    required this.nome,
    required this.descrizione,
    required this.prezzo,
    required this.disponibile,
    this.immagineUrl,
  });

  factory Prodotto.fromJson(Map<String, dynamic> j) => Prodotto(
        id: j['id'],
        idCategoria: j['id_categoria'],
        nome: j['nome'] ?? '',
        descrizione: j['descrizione'] ?? '',
        prezzo: double.parse(j['prezzo'].toString()),
        disponibile: j['disponibile'] == 1 || j['disponibile'] == true,
        immagineUrl: j['immagine_url'],
      );
}

class CarrelloItem {
  final Prodotto prodotto;
  int quantita;

  CarrelloItem({required this.prodotto, this.quantita = 1});

  double get subtotale => prodotto.prezzo * quantita;
}

// ============================================================
// API SERVICE
// ============================================================

class ApiService {
  static Future<List<Categoria>> getCategorie() async {
    final r = await http.get(Uri.parse('$kBaseUrl/categorie'));
    if (r.statusCode != 200) throw Exception('Errore nel caricamento categorie');
    final List<dynamic> data = jsonDecode(r.body);
    return data.map((j) => Categoria.fromJson(j)).toList();
  }

  static Future<List<Prodotto>> getProdotti(int idCategoria) async {
    final r = await http.get(Uri.parse('$kBaseUrl/categorie/$idCategoria/prodotti'));
    if (r.statusCode != 200) throw Exception('Errore nel caricamento prodotti');
    final List<dynamic> data = jsonDecode(r.body);
    return data.map((j) => Prodotto.fromJson(j)).toList();
  }

  static Future<Map<String, dynamic>> inviaOrdine({
    required double totale,
    required List<Map<String, dynamic>> righe,
  }) async {
    final r = await http.post(
      Uri.parse('$kBaseUrl/ordini'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'totale': totale, 'righe': righe}),
    );
    if (r.statusCode != 201) throw Exception('Errore nell\'invio dell\'ordine');
    return jsonDecode(r.body);
  }
}

// ============================================================
// CARRELLO (State Management senza dipendenze esterne)
// ============================================================

class CarrelloNotifier extends ChangeNotifier {
  final List<CarrelloItem> _items = [];

  List<CarrelloItem> get items => List.unmodifiable(_items);

  int get quantitaTotale => _items.fold(0, (s, i) => s + i.quantita);

  double get totale => _items.fold(0.0, (s, i) => s + i.subtotale);

  bool get isEmpty => _items.isEmpty;

  void aggiungi(Prodotto p) {
    final idx = _items.indexWhere((i) => i.prodotto.id == p.id);
    if (idx >= 0) {
      _items[idx].quantita++;
    } else {
      _items.add(CarrelloItem(prodotto: p));
    }
    notifyListeners();
  }

  void rimuovi(int idProdotto) {
    final idx = _items.indexWhere((i) => i.prodotto.id == idProdotto);
    if (idx >= 0) {
      if (_items[idx].quantita > 1) {
        _items[idx].quantita--;
      } else {
        _items.removeAt(idx);
      }
    }
    notifyListeners();
  }

  void eliminaDalCarrello(int idProdotto) {
    _items.removeWhere((i) => i.prodotto.id == idProdotto);
    notifyListeners();
  }

  void svuota() {
    _items.clear();
    notifyListeners();
  }

  int quantitaPerProdotto(int idProdotto) {
    final idx = _items.indexWhere((i) => i.prodotto.id == idProdotto);
    return idx >= 0 ? _items[idx].quantita : 0;
  }

  List<Map<String, dynamic>> toRigheOrdine() {
    return _items
        .map((i) => {
              'id_prodotto': i.prodotto.id,
              'quantita': i.quantita,
              'prezzo_unitario': i.prodotto.prezzo,
            })
        .toList();
  }
}

// ============================================================
// APP ROOT
// ============================================================

class TotemApp extends StatelessWidget {
  const TotemApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<CarrelloNotifier>(
      create: (_) => CarrelloNotifier(),
      child: MaterialApp(
        title: 'Totem Ordinazione',
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(),
        home: const SplashScreen(),
      ),
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: kBg,
      colorScheme: const ColorScheme.dark(
        primary: kAccent,
        secondary: kGold,
        surface: kSurface,
        error: kRed,
      ),
      fontFamily: 'SF Pro Display',
      appBarTheme: const AppBarTheme(
        backgroundColor: kSurface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: kText,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: kAccent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      cardTheme: CardTheme(
        color: kCard,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}

// ============================================================
// PROVIDER SEMPLICE (senza package provider)
// ============================================================

class ChangeNotifierProvider<T extends ChangeNotifier> extends StatefulWidget {
  final T Function(BuildContext) create;
  final Widget child;

  const ChangeNotifierProvider({super.key, required this.create, required this.child});

  @override
  State<ChangeNotifierProvider<T>> createState() => _ChangeNotifierProviderState<T>();

  static T of<T extends ChangeNotifier>(BuildContext context) {
    final state = context.findAncestorStateOfType<_ChangeNotifierProviderState<T>>();
    if (state == null) throw Exception('Provider<$T> non trovato nel contesto');
    return state._notifier;
  }
}

class _ChangeNotifierProviderState<T extends ChangeNotifier>
    extends State<ChangeNotifierProvider<T>> {
  late T _notifier;

  @override
  void initState() {
    super.initState();
    _notifier = widget.create(context);
    _notifier.addListener(_onNotify);
  }

  void _onNotify() => setState(() {});

  @override
  void dispose() {
    _notifier.removeListener(_onNotify);
    _notifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

// Helper widget per accedere al carrello
class CarrelloConsumer extends StatelessWidget {
  final Widget Function(BuildContext context, CarrelloNotifier carrello) builder;

  const CarrelloConsumer({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    final carrello = ChangeNotifierProvider.of<CarrelloNotifier>(context);
    return builder(context, carrello);
  }
}

// ============================================================
// SPLASH SCREEN
// ============================================================

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.6, curve: Curves.easeOut)),
    );
    _scaleAnim = Tween<double>(begin: 0.8, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.7, curve: Curves.elasticOut)),
    );
    _ctrl.forward();

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const MenuScreen(),
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => Center(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: ScaleTransition(
              scale: _scaleAnim,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: kAccent,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: kAccent.withOpacity(0.4),
                          blurRadius: 40,
                          spreadRadius: 10,
                        )
                      ],
                    ),
                    child: const Icon(Icons.restaurant_menu, size: 64, color: Colors.white),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'ORDINA QUI',
                    style: TextStyle(
                      color: kText,
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 6,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Tocca per iniziare',
                    style: TextStyle(
                      color: kTextMuted,
                      fontSize: 16,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 60),
                  SizedBox(
                    width: 160,
                    child: LinearProgressIndicator(
                      backgroundColor: kSurface,
                      valueColor: const AlwaysStoppedAnimation<Color>(kAccent),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// MENU SCREEN (principale)
// ============================================================

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> with TickerProviderStateMixin {
  List<Categoria> _categorie = [];
  List<Prodotto> _prodotti = [];
  bool _loadingCategorie = true;
  bool _loadingProdotti = false;
  int _categoriaSelezionata = 0;
  String? _errore;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _caricaCategorie();
  }

  Future<void> _caricaCategorie() async {
    try {
      final cats = await ApiService.getCategorie();
      setState(() {
        _categorie = cats;
        _loadingCategorie = false;
      });
      _tabController = TabController(length: cats.length, vsync: this);
      _tabController.addListener(() {
        if (!_tabController.indexIsChanging) {
          _categoriaSelezionata = _tabController.index;
          _caricaProdotti(_categorie[_categoriaSelezionata].id);
        }
      });
      if (cats.isNotEmpty) {
        _caricaProdotti(cats[0].id);
      }
    } catch (e) {
      setState(() {
        _errore = e.toString();
        _loadingCategorie = false;
      });
    }
  }

  Future<void> _caricaProdotti(int idCategoria) async {
    setState(() => _loadingProdotti = true);
    try {
      final prods = await ApiService.getProdotti(idCategoria);
      setState(() {
        _prodotti = prods;
        _loadingProdotti = false;
      });
    } catch (e) {
      setState(() {
        _errore = e.toString();
        _loadingProdotti = false;
      });
    }
  }

  @override
  void dispose() {
    if (_categorie.isNotEmpty) _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Column(
        children: [
          _buildHeader(),
          if (_loadingCategorie)
            const Expanded(child: Center(child: _LoadingWidget()))
          else if (_errore != null)
            Expanded(child: _ErrorWidget(errore: _errore!, onRetry: _caricaCategorie))
          else ...[
            _buildCategoryTabs(),
            Expanded(
              child: _loadingProdotti
                  ? const Center(child: _LoadingWidget())
                  : _buildProdottiGrid(),
            ),
          ],
          _buildCarrelloBar(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: kSurface,
      padding: const EdgeInsets.fromLTRB(24, 56, 24, 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: kAccent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.restaurant_menu, size: 22, color: Colors.white),
          ),
          const SizedBox(width: 14),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Il Nostro Menù',
                style: TextStyle(
                  color: kText,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
              Text(
                'Scegli i tuoi prodotti preferiti',
                style: TextStyle(color: kTextMuted, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    if (_categorie.isEmpty) return const SizedBox.shrink();
    return Container(
      color: kSurface,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: kAccent,
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.label,
        labelColor: kAccent,
        unselectedLabelColor: kTextMuted,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        tabs: _categorie.map((c) => Tab(text: c.nome)).toList(),
      ),
    );
  }

  Widget _buildProdottiGrid() {
    if (_prodotti.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sentiment_dissatisfied, size: 64, color: kTextMuted),
            SizedBox(height: 16),
            Text('Nessun prodotto disponibile', style: TextStyle(color: kTextMuted, fontSize: 16)),
          ],
        ),
      );
    }

    return CarrelloConsumer(
      builder: (ctx, carrello) => GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 300,
          childAspectRatio: 0.72,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: _prodotti.length,
        itemBuilder: (ctx, i) => _ProdottoCard(
          prodotto: _prodotti[i],
          quantitaInCarrello: carrello.quantitaPerProdotto(_prodotti[i].id),
          onAggiungi: () => carrello.aggiungi(_prodotti[i]),
          onRimuovi: () => carrello.rimuovi(_prodotti[i].id),
        ),
      ),
    );
  }

  Widget _buildCarrelloBar() {
    return CarrelloConsumer(
      builder: (ctx, carrello) {
        if (carrello.isEmpty) return const SizedBox.shrink();
        return GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CarrelloScreen()),
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [kAccent, Color(0xFFFF4500)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: kAccent.withOpacity(0.45),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${carrello.quantitaTotale}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    'Visualizza carrello',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                    ),
                  ),
                ),
                Text(
                  '€${carrello.totale.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ============================================================
// PRODOTTO CARD
// ============================================================

class _ProdottoCard extends StatefulWidget {
  final Prodotto prodotto;
  final int quantitaInCarrello;
  final VoidCallback onAggiungi;
  final VoidCallback onRimuovi;

  const _ProdottoCard({
    required this.prodotto,
    required this.quantitaInCarrello,
    required this.onAggiungi,
    required this.onRimuovi,
  });

  @override
  State<_ProdottoCard> createState() => _ProdottoCardState();
}

class _ProdottoCardState extends State<_ProdottoCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _bounceCtrl;
  late Animation<double> _bounceAnim;

  @override
  void initState() {
    super.initState();
    _bounceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 180));
    _bounceAnim = Tween<double>(begin: 1.0, end: 0.93).animate(
      CurvedAnimation(parent: _bounceCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    super.dispose();
  }

  void _handleTap() async {
    await _bounceCtrl.forward();
    await _bounceCtrl.reverse();
    widget.onAggiungi();
  }

  @override
  Widget build(BuildContext context) {
    final bool inCarrello = widget.quantitaInCarrello > 0;

    return ScaleTransition(
      scale: _bounceAnim,
      child: Container(
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: inCarrello ? kAccent.withOpacity(0.5) : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Immagine / placeholder
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: widget.prodotto.immagineUrl != null
                    ? Image.network(
                        widget.prodotto.immagineUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
                      )
                    : _buildImagePlaceholder(),
              ),
            ),
            // Info
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.prodotto.nome,
                      style: const TextStyle(
                        color: kText,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.prodotto.descrizione.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        widget.prodotto.descrizione,
                        style: const TextStyle(color: kTextMuted, fontSize: 12, height: 1.3),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const Spacer(),
                    Row(
                      children: [
                        Text(
                          '€${widget.prodotto.prezzo.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: kAccent,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Spacer(),
                        // Controllo quantità
                        if (inCarrello)
                          _buildQuantityControl()
                        else
                          GestureDetector(
                            onTap: _handleTap,
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: kAccent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.add, color: Colors.white, size: 22),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityControl() {
    return Row(
      children: [
        GestureDetector(
          onTap: widget.onRimuovi,
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: kSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: kAccent.withOpacity(0.3)),
            ),
            child: const Icon(Icons.remove, color: kAccent, size: 16),
          ),
        ),
        Container(
          width: 30,
          alignment: Alignment.center,
          child: Text(
            '${widget.quantitaInCarrello}',
            style: const TextStyle(
              color: kAccent,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
        ),
        GestureDetector(
          onTap: widget.onAggiungi,
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: kAccent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: kSurface,
      child: Center(
        child: Icon(
          Icons.fastfood,
          size: 48,
          color: kTextMuted.withOpacity(0.4),
        ),
      ),
    );
  }
}

// ============================================================
// CARRELLO SCREEN
// ============================================================

class CarrelloScreen extends StatelessWidget {
  const CarrelloScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kSurface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: kText, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: CarrelloConsumer(
          builder: (_, carrello) => Text(
            'Carrello (${carrello.quantitaTotale} ${carrello.quantitaTotale == 1 ? "prodotto" : "prodotti"})',
            style: const TextStyle(color: kText, fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
        actions: [
          CarrelloConsumer(
            builder: (ctx, carrello) => carrello.isEmpty
                ? const SizedBox.shrink()
                : TextButton(
                    onPressed: () => _showSvuotaDialog(ctx, carrello),
                    child: const Text('Svuota', style: TextStyle(color: kRed, fontSize: 14)),
                  ),
          ),
        ],
      ),
      body: CarrelloConsumer(
        builder: (ctx, carrello) {
          if (carrello.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 80, color: kTextMuted.withOpacity(0.4)),
                  const SizedBox(height: 20),
                  const Text('Il tuo carrello è vuoto',
                      style: TextStyle(color: kTextMuted, fontSize: 18)),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Sfoglia il menù'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: carrello.items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _CarrelloItemCard(
                    item: carrello.items[i],
                    onAggiungi: () => carrello.aggiungi(carrello.items[i].prodotto),
                    onRimuovi: () => carrello.rimuovi(carrello.items[i].prodotto.id),
                    onElimina: () => carrello.eliminaDalCarrello(carrello.items[i].prodotto.id),
                  ),
                ),
              ),
              _buildSommario(ctx, carrello),
            ],
          );
        },
      ),
    );
  }

  void _showSvuotaDialog(BuildContext context, CarrelloNotifier carrello) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Svuota carrello?', style: TextStyle(color: kText)),
        content: const Text('Tutti i prodotti verranno rimossi.',
            style: TextStyle(color: kTextMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annulla', style: TextStyle(color: kTextMuted)),
          ),
          TextButton(
            onPressed: () {
              carrello.svuota();
              Navigator.of(context).pop();
            },
            child: const Text('Svuota', style: TextStyle(color: kRed, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildSommario(BuildContext context, CarrelloNotifier carrello) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
      decoration: BoxDecoration(
        color: kSurface,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, -4)),
        ],
      ),
      child: Column(
        children: [
          // Riepilogo prezzi
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${carrello.quantitaTotale} prodotti',
                style: const TextStyle(color: kTextMuted, fontSize: 15),
              ),
              Text(
                '€${carrello.totale.toStringAsFixed(2)}',
                style: const TextStyle(color: kText, fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const Divider(color: Color(0xFF333333), height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Totale', style: TextStyle(color: kText, fontSize: 20, fontWeight: FontWeight.w800)),
              Text(
                '€${carrello.totale.toStringAsFixed(2)}',
                style: const TextStyle(color: kAccent, fontSize: 24, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ConfermaScreen()),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                backgroundColor: kAccent,
              ),
              child: const Text(
                'Procedi con l\'ordine',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// CARRELLO ITEM CARD
// ============================================================

class _CarrelloItemCard extends StatelessWidget {
  final CarrelloItem item;
  final VoidCallback onAggiungi;
  final VoidCallback onRimuovi;
  final VoidCallback onElimina;

  const _CarrelloItemCard({
    required this.item,
    required this.onAggiungi,
    required this.onRimuovi,
    required this.onElimina,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(item.prodotto.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: kRed.withOpacity(0.15),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.delete_outline, color: kRed, size: 28),
      ),
      onDismissed: (_) => onElimina(),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            // Icona prodotto
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: kSurface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: item.prodotto.immagineUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(item.prodotto.immagineUrl!, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.fastfood, color: kTextMuted, size: 28)),
                    )
                  : const Icon(Icons.fastfood, color: kTextMuted, size: 28),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.prodotto.nome,
                      style: const TextStyle(color: kText, fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(
                    '€${item.prodotto.prezzo.toStringAsFixed(2)} cad.',
                    style: const TextStyle(color: kTextMuted, fontSize: 13),
                  ),
                ],
              ),
            ),
            // Quantità + subtotale
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '€${item.subtotale.toStringAsFixed(2)}',
                  style: const TextStyle(color: kAccent, fontSize: 16, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _QtyButton(icon: Icons.remove, onTap: onRimuovi, outlined: true),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        '${item.quantita}',
                        style: const TextStyle(color: kText, fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                    ),
                    _QtyButton(icon: Icons.add, onTap: onAggiungi),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool outlined;

  const _QtyButton({required this.icon, required this.onTap, this.outlined = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: outlined ? Colors.transparent : kAccent,
          borderRadius: BorderRadius.circular(9),
          border: outlined ? Border.all(color: kAccent.withOpacity(0.4)) : null,
        ),
        child: Icon(icon, color: outlined ? kAccent : Colors.white, size: 16),
      ),
    );
  }
}

// ============================================================
// CONFERMA SCREEN
// ============================================================

class ConfermaScreen extends StatefulWidget {
  const ConfermaScreen({super.key});

  @override
  State<ConfermaScreen> createState() => _ConfermaScreenState();
}

class _ConfermaScreenState extends State<ConfermaScreen>
    with SingleTickerProviderStateMixin {
  bool _invioInCorso = false;
  bool _ordineInviato = false;
  String? _numeroOrdine;
  String? _errore;

  late AnimationController _successCtrl;
  late Animation<double> _successScale;

  @override
  void initState() {
    super.initState();
    _successCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _successScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _successCtrl, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _successCtrl.dispose();
    super.dispose();
  }

  Future<void> _inviaOrdine(CarrelloNotifier carrello) async {
    setState(() {
      _invioInCorso = true;
      _errore = null;
    });

    try {
      final result = await ApiService.inviaOrdine(
        totale: carrello.totale,
        righe: carrello.toRigheOrdine(),
      );
      carrello.svuota();
      setState(() {
        _ordineInviato = true;
        _numeroOrdine = result['numero_ordine'];
        _invioInCorso = false;
      });
      _successCtrl.forward();
    } catch (e) {
      setState(() {
        _errore = 'Errore durante l\'invio: ${e.toString()}';
        _invioInCorso = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: _ordineInviato
          ? null
          : AppBar(
              backgroundColor: kSurface,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: kText, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: const Text('Conferma Ordine',
                  style: TextStyle(color: kText, fontWeight: FontWeight.w700)),
            ),
      body: _ordineInviato
          ? _buildSuccessView()
          : CarrelloConsumer(builder: (ctx, carrello) => _buildRiepilogo(ctx, carrello)),
    );
  }

  Widget _buildRiepilogo(BuildContext context, CarrelloNotifier carrello) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'Riepilogo ordine',
                style: TextStyle(color: kText, fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              const Text(
                'Controlla i tuoi prodotti prima di confermare',
                style: TextStyle(color: kTextMuted, fontSize: 14),
              ),
              const SizedBox(height: 24),
              ...carrello.items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: kCard,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: kAccent.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${item.quantita}x',
                              style: const TextStyle(
                                  color: kAccent, fontSize: 12, fontWeight: FontWeight.w800),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(item.prodotto.nome,
                                style: const TextStyle(color: kText, fontSize: 15, fontWeight: FontWeight.w600)),
                          ),
                          Text(
                            '€${item.subtotale.toStringAsFixed(2)}',
                            style: const TextStyle(
                                color: kTextMuted, fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  )),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: kAccent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: kAccent.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('TOTALE DA PAGARE',
                        style: TextStyle(
                            color: kText, fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                    Text('€${carrello.totale.toStringAsFixed(2)}',
                        style: const TextStyle(
                            color: kAccent, fontSize: 26, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
              if (_errore != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: kRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kRed.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: kRed, size: 20),
                      const SizedBox(width: 10),
                      Expanded(child: Text(_errore!, style: const TextStyle(color: kRed, fontSize: 13))),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        // Bottom bar
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          color: kSurface,
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _invioInCorso ? null : () => _inviaOrdine(carrello),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                backgroundColor: kAccent,
                disabledBackgroundColor: kAccent.withOpacity(0.4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              child: _invioInCorso
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5))
                  : const Text(
                      '✓  Conferma e invia ordine',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessView() {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: ScaleTransition(
            scale: _successScale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: kGreen.withOpacity(0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: kGreen, width: 2.5),
                  ),
                  child: const Icon(Icons.check_rounded, color: kGreen, size: 64),
                ),
                const SizedBox(height: 36),
                const Text(
                  'Ordine inviato!',
                  style: TextStyle(color: kText, fontSize: 32, fontWeight: FontWeight.w900),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Il tuo ordine è stato ricevuto e\n è in fase di preparazione.',
                  style: TextStyle(color: kTextMuted, fontSize: 16, height: 1.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                if (_numeroOrdine != null)
                  Column(
                    children: [
                      const Text('Il tuo numero ordine è',
                          style: TextStyle(color: kTextMuted, fontSize: 14)),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        decoration: BoxDecoration(
                          color: kGold.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: kGold.withOpacity(0.4), width: 1.5),
                        ),
                        child: Text(
                          _numeroOrdine!,
                          style: const TextStyle(
                            color: kGold,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Tieni a mente questo numero',
                        style: TextStyle(color: kTextMuted, fontSize: 13),
                      ),
                    ],
                  ),
                const SizedBox(height: 60),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Torna alla schermata principale svuotando lo stack
                      Navigator.of(context).pushAndRemoveUntil(
                        PageRouteBuilder(
                          pageBuilder: (_, __, ___) => const MenuScreen(),
                          transitionsBuilder: (_, anim, __, child) =>
                              FadeTransition(opacity: anim, child: child),
                          transitionDuration: const Duration(milliseconds: 500),
                        ),
                        (_) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      backgroundColor: kAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                    child: const Text(
                      'Nuovo ordine',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// WIDGET AUSILIARI
// ============================================================

class _LoadingWidget extends StatelessWidget {
  const _LoadingWidget();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(color: kAccent, strokeWidth: 3),
        const SizedBox(height: 16),
        Text('Caricamento...', style: TextStyle(color: kTextMuted, fontSize: 15)),
      ],
    );
  }
}

class _ErrorWidget extends StatelessWidget {
  final String errore;
  final VoidCallback onRetry;

  const _ErrorWidget({required this.errore, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 64, color: kTextMuted),
            const SizedBox(height: 20),
            const Text('Impossibile connettersi',
                style: TextStyle(color: kText, fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(errore,
                style: const TextStyle(color: kTextMuted, fontSize: 13),
                textAlign: TextAlign.center),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Riprova'),
            ),
          ],
        ),
      ),
    );
  }
}