import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

// Modelo de Producto
class Producto {
  final int id;
  final String description;
  final int stock;
  final String price;

  Producto({
    required this.id,
    required this.description,
    required this.stock,
    required this.price,
  });

  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      id: json['id'],
      description: json['description'],
      stock: json['stock'],
      price: json['price'],
    );
  }
}

// Función para obtener productos de la API
Future<List<Producto>> obtenerProductos() async {
  final Map<String, dynamic> requestBody = {
    "search": {
      "scopes": [],
      "filters": [],
      "sorts": [
        {"field": "id", "direction": "desc"}
      ],
      "selects": [
        {"field": "id"},
        {"field": "description"},
        {"field": "stock"},
        {"field": "price"}
      ],
      "includes": [],
      "aggregates": [],
      "instructions": [],
      "gates": ["create", "update", "delete"],
      "page": 1,
      "limit": 10
    }
  };

  try {
    final response = await http.post(
      Uri.parse('http://127.0.0.1:8000/api/products/search'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body);
      if (jsonResponse.containsKey('data')) {
        if (jsonResponse['data'] is List) {
          List<dynamic> productos = jsonResponse['data'];
          return productos.map((data) => Producto.fromJson(data)).toList();
        } else {
          throw Exception('La estructura de la respuesta no es correcta.');
        }
      } else {
        throw Exception('No se encontró la clave "data" en la respuesta.');
      }
    } else {
      print('Respuesta del servidor: ${response.body}');
      throw Exception('Error al cargar los productos.');
    }
  } catch (e) {
    print('Excepción: $e');
    rethrow;
  }
}

// Pantalla de la lista de productos con un diseño de tarjetas
class ProductListScreen extends StatefulWidget {
  @override
  _ProductListScreenState createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  List<Producto> _allProducts = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final products = await obtenerProductos();
      setState(() {
        _allProducts = products;
      });
    } catch (e) {
      print('Error loading products: $e');
    }
  }

  Future<void> _refreshProductos() async {
    await _loadProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lista de Productos'),
        // Se elimina la propiedad backgroundColor para usar el color por defecto
        backgroundColor: null,
        elevation:
            0, // Opcional: quita la sombra si deseas un diseño más limpio
      ),
      body: Center(
        child: RefreshIndicator(
          onRefresh: _refreshProductos,
          child: _allProducts.isEmpty
              ? CircularProgressIndicator()
              : ListView.builder(
                  padding: const EdgeInsets.all(10.0),
                  itemCount: _allProducts.length,
                  itemBuilder: (context, index) {
                    final producto = _allProducts[index];
                    return Card(
                      margin:
                          EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                      elevation: 5,
                      child: Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              producto.description,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "ID: ${producto.id}",
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                                Text(
                                  "Stock: ${producto.stock}",
                                  style: TextStyle(color: Colors.green[700]),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Price: \$${producto.price}",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.blueGrey[900],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Product App',
    home: ProductListScreen(),
  ));
}
