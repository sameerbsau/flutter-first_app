import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import '../models/product.dart';
import 'package:scoped_model/scoped_model.dart';
import '../scoped-models/main.dart';
import '../widgets/form_inputs/location.dart';
import '../models/location_data.dart';
import '../widgets/form_inputs/image.dart';
import '../widgets/ui_elements/adaptive_progess_indicator.dart';

class ProductEditPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return new _ProductEditPageState();
  }
}

class _ProductEditPageState extends State<ProductEditPage> {
  final Map<String, dynamic> _formData = {
    'title': null,
    'description': null,
    'price': null,
    'image': null,
    'locationData': null
  };
  final GlobalKey<FormState> _formKey = new GlobalKey<FormState>();
  final _titleTextController = TextEditingController();
  final _descTextController = TextEditingController();
  final _priceTextController = TextEditingController();

  Widget _buildTitleTextField(Product product) {
    if (product == null && _titleTextController.text.trim() == '') {
      _titleTextController.text = '';
    } else if (product != null && _titleTextController.text.trim() == '') {
      _titleTextController.text = product.title;
    } else if (product != null && _titleTextController.text.trim() != '') {
      _titleTextController.text = _titleTextController.text;
    } else if (product == null && _titleTextController.text.trim() != '') {
      _titleTextController.text = _titleTextController.text;
    } else {
      _titleTextController.text = '';
    }
    return TextFormField(
        decoration: InputDecoration(labelText: 'Product Title'),
        controller: _titleTextController,
        //initialValue: product == null ? '' : product.title,
        validator: (String value) {
          if (value.isEmpty || value.length < 5) {
            return 'Title is required and should be 5+ characters';
          }
        },
        onSaved: (String value) {
          _formData['title'] = value;
        });
  }

  Widget _buildDescriptionTextField(Product product) {
    if (product == null && _descTextController.text.trim() == '') {
      _descTextController.text = '';
    } else if (product != null && _descTextController.text.trim() == '') {
      _descTextController.text = product.description;
    }
    return TextFormField(
        maxLines: 4,
        decoration: InputDecoration(labelText: 'Product Description'),
        controller: _descTextController,
        // initialValue: product == null ? '' : product.description,
        validator: (String value) {
          if (value.isEmpty || value.length < 10) {
            return 'Description is required and should be 10+ characters';
          }
        },
        onSaved: (String value) {
          _formData['description'] = value;
        });
  }

  Widget _buildPriceTextField(Product product) {
    if (product == null && _priceTextController.text.trim() == '') {
      _priceTextController.text = '';
    } else if (product != null && _priceTextController.text.trim() == '') {
      _priceTextController.text = product.price.toString();
    }
    return TextFormField(
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: 'Product Price'),
      controller: _priceTextController,
      // initialValue: product == null ? '' : product.price.toString(),
      validator: (String value) {
        if (value.isEmpty ||
            !RegExp(r'^(?:[1-9]\d*|0)?(?:[.,]\d+)?$').hasMatch(value)) {
          return 'Price is required and should be valid';
        }
      },
    );
  }

  void _submitForm(
      Function addProduct, Function updateProduct, Function setSelectProduct,
      [int selectedProductIndedx=1]) {
    if (!_formKey.currentState.validate() ||
        (_formData['image'] == null && selectedProductIndedx == -1)) {
      return;
    }
    _formKey.currentState.save();
    if (selectedProductIndedx == -1) {
      addProduct(
              _titleTextController.text,
              _descTextController.text,
              _formData['image'],
              double.parse(
                  _priceTextController.text.replaceAll(RegExp(r','), '.')),
              _formData['locationData'])
          .then((bool success) {
        if (success) {
          Navigator.pushReplacementNamed(context, '/products')
              .then((_) => setSelectProduct(null));
        } else {
          showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text('Something went wrong!'),
                  content: Text('PLease try again.'),
                  actions: <Widget>[
                    RaisedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('Ok'),
                    )
                  ],
                );
              });
        }
      });
    } else {
      updateProduct(
              _titleTextController.text,
              _descTextController.text,
              _formData['image'],
              double.parse(
                  _priceTextController.text.replaceAll(RegExp(r','), '.')),
              _formData['locationData'])
          .then((_) => Navigator.pushReplacementNamed(context, '/products')
              .then((_) => setSelectProduct(null)));
    }
    // final Map<String, dynamic> product = {
    //   'title': titleValue,
    //   'description': description,
    //   'price': price,
    //   'image': 'assets/Death_Valley_-_Dunes.jpg'
    // };
    // widget.addProduct(product);
  }

  Widget _builSubmitButton() {
    return ScopedModelDescendant<MainModel>(
      builder: (BuildContext context, Widget child, MainModel model) {
        return model.isLoading
            ? Center(child: AdaptiveProgressIndicator())
            : RaisedButton(
                child: Text('Save'),
                //color: Theme.of(context).accentColor,
                textColor: Colors.amberAccent,
                onPressed: () => _submitForm(
                    model.addProduct,
                    model.updateProduct,
                    model.selectProduct,
                    model.selectedProductIndex));
      },
    );
  }

  void setLocation(LocationData locdata) {
    _formData['locationData'] = locdata;
  }

  void setImage(File image) {
    _formData['image'] = image;
  }

  Widget _buildPageContent(BuildContext context, Product product) {
    final double deviceWidth = MediaQuery.of(context).size.width;
    final double targetWidth = deviceWidth > 550.0 ? 500.0 : deviceWidth * 0.95;
    final double targetPadding = deviceWidth - targetWidth;
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).requestFocus(FocusNode());
      },
      child: Container(
        margin: EdgeInsets.all(10.0),
        child: Form(
          // autovalidate: true,
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.symmetric(horizontal: targetPadding / 2),
            children: <Widget>[
              _buildTitleTextField(product),
              _buildDescriptionTextField(product),
              _buildPriceTextField(product),
              SizedBox(
                height: 10.0,
              ),
              SizedBox(
                height: 10.0,
              ),
              LocationInput(setLocation, product),
              SizedBox(
                height: 10.0,
              ),
              ImageInput(setImage, product),
              SizedBox(
                height: 10.0,
              ),
              _builSubmitButton(),

              // GestureDetector(
              //   onTap: _submitForm,
              //   child: Container(
              //     color: Colors.green,
              //     padding: EdgeInsets.all(10.0),
              //     child: Text('My Button'),
              //   ),
              // )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext conext) {
    return ScopedModelDescendant<MainModel>(
      builder: (BuildContext context, Widget child, MainModel model) {
        final Widget pageContent =
            _buildPageContent(context, model.selectedProduct);
        return model.selectedProductIndex == -1
            ? pageContent
            : Scaffold(
                appBar: AppBar(
                  title: Text('Edit Product'),
                  elevation: Theme.of(context).platform == TargetPlatform.iOS
                      ? 0.0
                      : 4.0,
                ),
                body: pageContent,
              );
      },
    );
  }
}
