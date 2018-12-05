import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:map_view/map_view.dart';
import 'package:scoped_model/scoped_model.dart';

import './pages/auth.dart';
import './pages/products_admin.dart';
import './pages/products.dart';
import './pages/product.dart';
import './scoped-models/main.dart';
import './models/product.dart';
import './widgets/helpers/custom_routes.dart';
import './shared/global_config.dart';
import './shared/adaptive_theme.dart';

void main() {
  //debugPaintSizeEnabled = true;
  //debugPaintBaselinesEnabled=true;
  //debugPaintPointersEnabled=true;
  MapView.setApiKey(apiey);
  runApp(new MyApp());
}

class MyApp extends StatefulWidget {
  //List<Map<String, dynamic>> _products = [];
  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return new _MyAppState();
  }
}

class _MyAppState extends State<MyApp> {
  final MainModel _model = new MainModel();
  final _platformChannel = MethodChannel('flutter-course.com/battery');
  bool _isAuthenticated = false;
  Future<Null> _getBatteryLevel() async {
    String batteryLevel;
    try {
      final int result = await _platformChannel.invokeMethod('getBatteryLevel');
      batteryLevel = 'battery level is $result';
    } catch (e) {
      batteryLevel = 'failed to get battery levle';
    }
    print(batteryLevel);
  }

  @override
  void initState() {
    _model.autoAuthenticate();
    _model.userSubject.listen((bool isAuthenticated) {
      setState(() {
        _isAuthenticated = isAuthenticated;
      });
    });
    _getBatteryLevel();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ScopedModel(
      model: _model,
      child: MaterialApp(
        title: 'EasyList',
        // debugShowMaterialGrid: true,
        theme: getAdaptiveThemeData(context),
        // home:new AuthPage(),
        routes: {
          '/': (BuildContext context) =>
              !_isAuthenticated ? AuthPage() : ProductsPage(_model),
          '/admin': (BuildContext context) =>
              !_isAuthenticated ? AuthPage() : new ProductsAdminPage(_model)
        },
        onGenerateRoute: (RouteSettings settings) {
          if (!_isAuthenticated) {
            return MaterialPageRoute<bool>(
              builder: (BuildContext context) => new AuthPage(),
            );
          }
          final List<String> pathElements = settings.name.split('/');
          if (pathElements[0] != '') {
            return null;
          }
          if (pathElements[1] == 'product') {
            final String productId = pathElements[2];
            final Product product =
                _model.allProducts.firstWhere((Product product) {
              return product.id == productId;
            });

            return CustomRoute<bool>(
                builder: (BuildContext context) =>
                    !_isAuthenticated ? AuthPage() : new ProductPage(product));
          }
          return null;
        },
        onUnknownRoute: (RouteSettings settings) {
          return MaterialPageRoute(
              builder: (BuildContext context) =>
                  !_isAuthenticated ? AuthPage() : new ProductsPage(_model));
        },
      ),
    );
  }
}
