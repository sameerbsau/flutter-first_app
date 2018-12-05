import 'package:flutter/material.dart';
import 'dart:async';
import 'package:map_view/map_view.dart';

import '../models/product.dart';
import '../widgets/products/products_fab.dart';

import '../widgets/ui_elements/title_default.dart';

class ProductPage extends StatelessWidget {
  final Product product;
  ProductPage(this.product);

  void _showWarningDailogue(BuildContext context) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Are you sure?'),
            content: Text('This action cannot be undone!'),
            actions: <Widget>[
              FlatButton(
                child: Text('DISCARD'),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              FlatButton(
                child: Text('DELETE'),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context, true);
                },
              ),
            ],
          );
        });
  }

  void _showMap() {
    final List<Marker> markers = <Marker>[
      Marker('position', 'Position', product.locationData.lattitude,
          product.locationData.longitude)
    ];
    final CameraPosition cameraPosition = CameraPosition(
        Location(
            product.locationData.lattitude, product.locationData.longitude),
        14.0);
    final mapView = MapView();
    mapView.show(
        MapOptions(
            initialCameraPosition: cameraPosition,
            mapViewType: MapViewType.normal,
            title: 'Product Location'),
        toolbarActions: [ToolbarAction('Close', 1)]);
    mapView.onToolbarAction.listen((int id) {
      if (id == 1) {
        mapView.dismiss();
      }
    });
    mapView.onMapReady.listen((_) {
      mapView.setMarkers(markers);
    });
  }

  Widget _buildAddressPriceRow(String address, double price) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        GestureDetector(
          onTap: _showMap,
          child: Text(
            address,
            style: TextStyle(fontFamily: 'Oswald', color: Colors.grey),
          ),
        ),
        Container(
            margin: EdgeInsets.symmetric(horizontal: 5.0),
            child: Text(
              '|',
              style: TextStyle(color: Colors.black),
            )),
        Text(
          '\$' + price.toString(),
          style: TextStyle(fontFamily: 'Oswald', color: Colors.grey),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return WillPopScope(
      onWillPop: () {
        Navigator.pop(context, false);
        return Future.value(false);
      },
      child: Scaffold(
        // appBar: AppBar(
        //   title: Text(product.title),
        // ),
        body: CustomScrollView(
          slivers: <Widget>[
            SliverAppBar(
              expandedHeight: 500.0,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(product.title),
                background: Hero(
                  tag: product.id,
                  child: FadeInImage(
                    image: NetworkImage(product.image),
                    placeholder: AssetImage('assets/food.jpg'),
                    fit: BoxFit.cover,
                    height: 300.0,
                  ),
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildListDelegate(
                [
                  Container(
                    padding: EdgeInsets.all(10.0),
                    alignment: Alignment.center,
                    child: TitleDefault(product.title),
                  ),
                  _buildAddressPriceRow(
                      product.locationData.address, product.price),
                  Container(
                    padding: EdgeInsets.all(10.0),
                    child: Text(
                      product.description,
                      textAlign: TextAlign.center,
                    ),
                  )
                ],
              ),
            )
          ],
        ),
        floatingActionButton: ProductFab(product),
      ),
    );
  }
}
