import 'package:flutter/material.dart';

import './product_edit.dart';
import './product_list.dart';

import '../scoped-models/main.dart';
import '../widgets/ui_elements/logout_list_tile.dart';

class ProductsAdminPage extends StatelessWidget {
  final MainModel model;
  ProductsAdminPage(this.model);

  Widget _buildAddressDrawer(BuildContext context) {
    return Drawer(
      child: Column(
        children: <Widget>[
          AppBar(
            automaticallyImplyLeading: false,
            title: Text('Choose'),
            elevation:
              Theme.of(context).platform == TargetPlatform.iOS ? 0.0 : 4.0,
          ),
          ListTile(
            leading: Icon(Icons.list),
            title: Text('All Products'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
          Divider(),
          LogoutListTile(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        drawer: _buildAddressDrawer(context),
        appBar: AppBar(
          title: Text('Manage Products'),
          elevation:
              Theme.of(context).platform == TargetPlatform.iOS ? 0.0 : 4.0,
          bottom: TabBar(
            tabs: <Widget>[
              Tab(
                text: 'Create Product',
                icon: Icon(Icons.create),
              ),
              Tab(
                text: 'My Products',
                icon: Icon(Icons.list),
              )
            ],
          ),
        ),
        body: TabBarView(
          children: <Widget>[new ProductEditPage(), new ProductListPage(model)],
        ),
      ),
    );
  }
}
