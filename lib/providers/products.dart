import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Product {
  final String? id;
  final String? title;
  final String? description;
  final double? price;
  final String? imageUrl;

  Product({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.imageUrl,
  });
}

class Products with ChangeNotifier {
  List<Product?> productsList = [];

  String? authToken;

  void getData(authTok, productlist) {
    productsList = productlist;
    authToken = authTok;
  }

  Future<void> fetchData() async {
    final url =
        "https://first-project-e30ac-default-rtdb.firebaseio.com/product.json?auth=$authToken";
    try {
      final http.Response res = await http.get(Uri.parse(url));
      if (json.decode(res.body) != null) {
        final extractedData = json.decode(res.body) as Map<String, dynamic>;
        extractedData.forEach((prodId, prodData) {
          final prodIndex =
              productsList.indexWhere((element) => element?.id == prodId);
          if (prodIndex >= 0) {
            productsList[prodIndex] = Product(
              id: prodId,
              title: prodData['title'],
              description: prodData['description'],
              price: prodData['price'],
              imageUrl: prodData['imageUrl'],
            );
          } else {
            productsList.add(Product(
              id: prodId,
              title: prodData['title'],
              description: prodData['description'],
              price: prodData['price'],
              imageUrl: prodData['imageUrl'],
            ));
          }
        });
      } else {
        productsList = [];
      }
      notifyListeners();
    } catch (error) {
      print('my error = $error');
    }
  }

  Future<void> updateData(String? id) async {
    final url =
        "https://first-project-e30ac-default-rtdb.firebaseio.com/product/$id.json?auth=$authToken";

    final prodIndex = productsList.indexWhere((element) => element?.id == id);
    if (prodIndex >= 0) {
      await http.patch(Uri.parse(url),
          body: json.encode({
            "title": "new title 4",
            "description": "new description 2",
            "price": 199.8,
            "imageUrl":
                "https://cdn.pixabay.com/photo/2015/06/19/21/24/the-road-815297__340.jpg",
          }));

      productsList[prodIndex] = Product(
        id: id,
        title: "new title 4",
        description: "new description 2",
        price: 199.8,
        imageUrl:
            "https://cdn.pixabay.com/photo/2015/06/19/21/24/the-road-815297__340.jpg",
      );

      notifyListeners();
    } else {
      print("...");
    }
  }

  Future<void> add(
      {String? id,
      String? title,
      String? description,
      double? price,
      String? imageUrl}) async {
    final url =
        "https://first-project-e30ac-default-rtdb.firebaseio.com/product.json?auth=$authToken";
    try {
      http.Response res = await http.post(Uri.parse(url),
          body: json.encode({
            "title": title,
            "description": description,
            "price": price,
            "imageUrl": imageUrl,
          }));
      print(json.decode(res.body));

      productsList.add(Product(
        id: json.decode(res.body)['name'],
        title: title,
        description: description,
        price: price,
        imageUrl: imageUrl,
      ));
      notifyListeners();
    } catch (error) {
      throw error;
    }
  }

  Future<void> delete(String? id) async {
    final url =
        "https://first-project-e30ac-default-rtdb.firebaseio.com/product/$id.json?auth=$authToken";
    final prodIndex = productsList.indexWhere((element) => element?.id == id);
    var prodItem = productsList[prodIndex];
    productsList.removeAt(prodIndex);
    notifyListeners();

    var res = await http.delete(Uri.parse(url));
    if (res.statusCode >= 400) {
      productsList.insert(prodIndex, prodItem);
      notifyListeners();
      print("Could not deleted item");
    } else {
      prodItem = null;
      print("Item deleted");
    }
  }
}
