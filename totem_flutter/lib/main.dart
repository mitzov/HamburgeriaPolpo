import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hamburgeria Totem',
      theme: ThemeData(primarySwatch: Colors.deepOrange),
      home: const MenuPage(),
    );
  }
}

class MenuItem {
  final int id;
  final String name;
  final String category;
  final double price;

  MenuItem({required this.id, required this.name, required this.category, required this.price});

  factory MenuItem.fromJson(Map<String, dynamic> j) => MenuItem(
        id: j['id'] as int,
        name: (j['name'] ?? '') as String,
        category: (j['category'] ?? '') as String,
        price: (j['price'] is int) ? (j['price'] as int).toDouble() : (j['price'] as num).toDouble(),
      );
}

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  final String apiUrl = 'http://127.0.0.1:5000';
  List<MenuItem> menu = [];
  final Map<int, int> cart = {}; // productId -> quantity
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchMenu();
  }

  Future<void> fetchMenu() async {
    setState(() => loading = true);
    try {
      final res = await http.get(Uri.parse('$apiUrl/menu'));
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        menu = data.map((e) => MenuItem.fromJson(e)).toList();
      }
    } catch (e) {
      // ignore
    }
    setState(() => loading = false);
  }

  void addToCart(int id) {
    setState(() => cart[id] = (cart[id] ?? 0) + 1);
  }

  double cartTotal() {
    double t = 0;
    for (var entry in cart.entries) {
      final item = menu.firstWhere((m) => m.id == entry.key);
      t += item.price * entry.value;
    }
    return t;
  }

  Future<void> sendOrder() async {
    final items = cart.entries
        .map((e) => {'product_id': e.key, 'quantity': e.value})
        .toList();
    final body = jsonEncode({'items': items, 'total_price': cartTotal()});
    try {
      final res = await http.post(Uri.parse('$apiUrl/orders'), headers: {'Content-Type': 'application/json'}, body: body);
      if (res.statusCode == 201) {
        setState(() => cart.clear());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ordine inviato!')));
        }
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Errore invio ordine')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Errore di rete')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hamburgeria - Totem'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchMenu,
          )
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: menu.length,
                    itemBuilder: (context, i) {
                      final m = menu[i];
                      return ListTile(
                        title: Text(m.name),
                        subtitle: Text('${m.category} • ${m.price.toStringAsFixed(2)} €'),
                        trailing: ElevatedButton(
                          onPressed: () => addToCart(m.id),
                          child: const Text('Aggiungi'),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.grey[100], border: Border(top: BorderSide(color: Colors.grey.shade300))),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Totale: € ${cartTotal().toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ElevatedButton.icon(
                        onPressed: cart.isEmpty ? null : sendOrder,
                        icon: const Icon(Icons.send),
                        label: const Text('Invia ordine'),
                      )
                    ],
                  ),
                )
              ],
            ),
    );
  }
}
