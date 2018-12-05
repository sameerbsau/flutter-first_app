import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';


import './product_card.dart';
import '../../models/product.dart';
import '../../scoped-models/main.dart';

class Products extends StatelessWidget {
  Widget _buildProductList(List<Product> products) {
    Widget buildProduct;
    if (products.length > 0) {
      buildProduct = ListView.builder(
        itemBuilder: (BuildContext context, int index) =>
            ProductCard(products[index]),
        itemCount: products.length,
      );
    } else {
      buildProduct = Center(
        child: Text('No products added to the list'),
      );
    }
    return buildProduct;
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build

    return ScopedModelDescendant<MainModel>(
      builder: (BuildContext context, Widget child, MainModel model) {
        return _buildProductList(model.displayedProducts);
      },
    );
  }
}
