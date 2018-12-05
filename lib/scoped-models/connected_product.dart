import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:scoped_model/scoped_model.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rxdart/subjects.dart';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';

import '../models/product.dart';
import '../models/user.dart';
import '../models/auth.dart';
import '../models/location_data.dart';

class ConnectedProductsModel extends Model {
  List<Product> _products = [];
  User _authenticateUser;
  String _selProductId;
  bool _isLoading = false;
}

class ProductsModel extends ConnectedProductsModel {
  bool showFavorites = false;

  List<Product> get allProducts {
    return List.from(_products);
  }

  List<Product> get displayedProducts {
    if (showFavorites) {
      return _products.where((Product product) => product.isFavorite).toList();
    }
    return List.from(_products);
  }

  bool get displayFavoritesOnly {
    return showFavorites;
  }

  String get selectedProductId {
    return _selProductId;
  }

  Product get selectedProduct {
    if (selectedProductId == null) {
      return null;
    }
    return _products.firstWhere((Product product) {
      return product.id == _selProductId;
    });
  }

  int get selectedProductIndex {
    return _products.indexWhere((Product product) {
      return product.id == _selProductId;
    });
  }

  Future<Map<String, dynamic>> uploadImage(File image,
      {String imagePath}) async {
    final mimeTypeData = lookupMimeType(image.path).split('/');
    final imageUploadRequest = http.MultipartRequest(
        'POST',
        Uri.parse(
            'https://us-central1-flutter-products-2c645.cloudfunctions.net/storeImage'));
    final file = await http.MultipartFile.fromPath('image', image.path,
        contentType: MediaType(mimeTypeData[0], mimeTypeData[1]));
    imageUploadRequest.files.add(file);
    if (imagePath != null) {
      imageUploadRequest.fields['imagePath'] = Uri.encodeComponent(imagePath);
    }
    imageUploadRequest.headers['Authorization'] =
        'Bearer ${_authenticateUser.token}';
    try {
      final streamedResponse = await imageUploadRequest.send();
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode != 200 && response.statusCode != 201) {
        print('something went wrong');
        print(json.decode(response.body));
        return null;
      }
      return json.decode(response.body);
    } catch (e) {
      print(e);
      return null;
    }
  }

  Future<bool> addProduct(String title, String description, File image,
      double price, LocationData locationData) async {
    _isLoading = true;
    notifyListeners();
    final uploadData = await uploadImage(image);
    if (uploadData == null) {
      print('upload failed');
      return false;
    }
    Map<String, dynamic> productData = {
      'title': title,
      'description': description,
      'price': price,
      'imagePath': uploadData['imagePath'],
      'imageUrl': uploadData['imageUrl'],
      'userEmail': _authenticateUser.email,
      'userId': _authenticateUser.id,
      'address': locationData.address,
      'lat': locationData.lattitude,
      'lng': locationData.longitude
    };
    try {
      final http.Response response = await http.post(
          'https://flutter-products-2c645.firebaseio.com/products.json?auth=${_authenticateUser.token}',
          body: json.encode(productData));

      if (response.statusCode != 200 && response.statusCode != 201) {
        _isLoading = false;
        notifyListeners();
        return false;
      }
      final Map<String, dynamic> responseBody = json.decode(response.body);
      final Product newProduct = new Product(
          id: responseBody['name'],
          title: title,
          description: description,
          image: uploadData['imageUrl'],
          imagePath: uploadData['imagePath'],
          price: price,
          locationData: locationData,
          email: _authenticateUser.email,
          userId: _authenticateUser.id);
      _products.add(newProduct);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
    // .catchError((error) {
    //   _isLoading = false;
    //   notifyListeners();
    //   return false;
    // });
  }

  Future<bool> updateProduct(String title, String description, File image,
      double price, LocationData locationData)async {
    _isLoading = true;
    notifyListeners();
    String imageUrl = selectedProduct.image;
    String imagePath = selectedProduct.imagePath;
    if(image!=null){
 final uploadData = await uploadImage(image);
    if (uploadData == null) {
      print('upload failed');
      return false;
    }
    imageUrl=uploadData['imageUrl'];
    imagePath=uploadData['imagePath'];
    }
    Map<String, dynamic> updateData = {
      'title': title,
      'description': description,
      'price': price,
      'imageUrl':imageUrl,
      'imagePath':imagePath,
      'userEmail': selectedProduct.email,
      'userId': selectedProduct.userId,
      'address': locationData.address,
      'lat': locationData.lattitude,
      'lng': locationData.longitude
    };
    try{
    await http
        .put(
            'https://flutter-products-2c645.firebaseio.com/products/${selectedProduct.id}.json?auth=${_authenticateUser.token}',
            body: json.encode(updateData));
      final Product updatedProduct = new Product(
          id: selectedProduct.id,
          title: title,
          description: description,
          image: imageUrl,
          imagePath: imagePath,
          price: price,
          locationData: locationData,
          email: selectedProduct.email,
          userId: selectedProduct.userId);

      _products[selectedProductIndex] = updatedProduct;
      _isLoading = false;
      notifyListeners();
      return true;
    }catch(error) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteProduct() {
    _isLoading = true;
    final deletedProductId = selectedProduct.id;
    _products.removeAt(selectedProductIndex);
    _selProductId = null;
    notifyListeners();

    return http
        .delete(
            'https://flutter-products-2c645.firebaseio.com/products/$deletedProductId.json?auth=${_authenticateUser.token}')
        .then((http.Response response) {
      _isLoading = false;
      notifyListeners();
      return true;
    }).catchError((error) {
      _isLoading = false;
      notifyListeners();
      return false;
    });
  }

  void selectProduct(String productId) {
    _selProductId = productId;
    if (productId != null) {
      notifyListeners();
    }
  }

  Future<Null> fetchProducts({onlyForUser = false, clearExisting=false}) {
    _isLoading = true;
    if(clearExisting){

    _products=[];
    }
    notifyListeners();
    return http
        .get(
            'https://flutter-products-2c645.firebaseio.com/products.json?auth=${_authenticateUser.token}')
        .then<Null>((http.Response response) {
      final List<Product> fetchedProductList = [];
      final Map<String, dynamic> productListData = json.decode(response.body);
      if (productListData == null) {
        _isLoading = false;
        notifyListeners();
        return;
      }
      productListData.forEach((String productId, dynamic productData) {
        final Product product = new Product(
            id: productId,
            title: productData['title'],
            description: productData['description'],
            price: productData['price'],
            image: productData['imageUrl'],
            imagePath: productData['imagePath'],
            email: productData['userEmail'],
            locationData: LocationData(
                address: productData['address'],
                longitude: productData['lat'],
                lattitude: productData['lng']),
            userId: productData['userId'],
            isFavorite: productData['wishListUsers'] == null
                ? false
                : (productData['wishListUsers'] as Map<String, dynamic>)
                    .containsKey(_authenticateUser.id));
        fetchedProductList.add(product);
      });
      _products = onlyForUser
          ? fetchedProductList.where((Product product) {
              return product.userId == _authenticateUser.id;
            }).toList()
          : fetchedProductList;
      _isLoading = false;
      notifyListeners();
      _selProductId = null;
    }).catchError((error) {
      _isLoading = false;
      notifyListeners();
      return;
    });
  }

  void toggleProductFavoriteStatus() async {
    final bool isCurrentlyFavorite = selectedProduct.isFavorite;
    final bool newFavoriteStatus = !isCurrentlyFavorite;
    final Product updatedProduct = new Product(
        id: selectedProduct.id,
        title: selectedProduct.title,
        description: selectedProduct.description,
        price: selectedProduct.price,
        image: selectedProduct.image,
        imagePath: selectedProduct.imagePath,
        email: selectedProduct.email,
        locationData: selectedProduct.locationData,
        userId: selectedProduct.userId,
        isFavorite: newFavoriteStatus);
    _products[selectedProductIndex] = updatedProduct;
    notifyListeners();
    http.Response response;
    if (newFavoriteStatus) {
      response = await http.put(
          'https://flutter-products-2c645.firebaseio.com/products/${selectedProduct.id}/wishListUsers/${_authenticateUser.id}.json?auth=${_authenticateUser.token}',
          body: json.encode(true));
    } else {
      response = await http.delete(
        'https://flutter-products-2c645.firebaseio.com/products/${selectedProduct.id}/wishListUsers/${_authenticateUser.id}.json?auth=${_authenticateUser.token}',
      );
    }
    if (response.statusCode != 200 && response.statusCode != 201) {
      final Product updatedProduct = new Product(
          id: selectedProduct.id,
          title: selectedProduct.title,
          description: selectedProduct.description,
          price: selectedProduct.price,
          image: selectedProduct.image,
          imagePath: selectedProduct.imagePath,
          locationData: selectedProduct.locationData,
          email: selectedProduct.email,
          userId: selectedProduct.userId,
          isFavorite: !newFavoriteStatus);
      _products[selectedProductIndex] = updatedProduct;
      notifyListeners();
    }
    _selProductId=null;
  }

  void toggleDisplayMode() {
    showFavorites = !showFavorites;
    notifyListeners();
  }
}

class UserModel extends ConnectedProductsModel {
  Timer _authTimer;
  PublishSubject<bool> _userSubject = PublishSubject();

  PublishSubject<bool> get userSubject {
    return _userSubject;
  }

  User get user {
    return _authenticateUser;
  }

  Future<Map<String, dynamic>> authenticate(String email, String password,
      [AuthMode authMode = AuthMode.Login]) async {
    _isLoading = true;
    notifyListeners();
    Map<String, dynamic> authData = {
      'email': email,
      'password': password,
      'returnSecureToken': true
    };
    http.Response response;
    if (authMode == AuthMode.Login) {
      response = await http.post(
          'https://www.googleapis.com/identitytoolkit/v3/relyingparty/verifyPassword?key=AIzaSyBM0SLA0VwSXfpM8L9Vbxm0QR2se7dH9xM',
          body: json.encode(authData),
          headers: {'Content-Type': 'application/json'});
    } else {
      response = await http.post(
          'https://www.googleapis.com/identitytoolkit/v3/relyingparty/signupNewUser?key=AIzaSyBM0SLA0VwSXfpM8L9Vbxm0QR2se7dH9xM',
          body: json.encode(authData),
          headers: {'Content-Type': 'application/json'});
    }
    final Map<String, dynamic> responseData = json.decode(response.body);

    bool hasError = true;
    String message = 'Something went wrong!';
    if (responseData.containsKey('idToken')) {
      hasError = false;
      message = 'Authentication succeded';
      _authenticateUser = User(
          id: responseData['localId'],
          email: email,
          token: responseData['idToken']);
      _userSubject.add(true);
      setAuthTimeout(int.parse(responseData['expiresIn']));
      final DateTime now = DateTime.now();
      final DateTime expiryTime =
          now.add(Duration(seconds: int.parse(responseData['expiresIn'])));
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString('token', responseData['idToken']);
      prefs.setString('userEmail', email);
      prefs.setString('userId', responseData['localId']);
      prefs.setString('expiryTime', expiryTime.toIso8601String());
    } else if (responseData['error']['message'] == 'EMAIL_NOT_FOUND') {
      message = 'Email does not exist';
    } else if (responseData['error']['message'] == 'INVALID_PASSWORD') {
      message = 'Invaid Password';
    } else if (responseData['error']['message'] == 'EMAIL_EXISTS') {
      message = 'This email already exists';
    }
    _isLoading = false;
    notifyListeners();
    return {'success': !hasError, 'message': message};
  }

  void autoAuthenticate() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final String token = preferences.getString('token');
    final String expiryTimeString = preferences.getString('expiryTime');
    if (token != null) {
      final DateTime now = DateTime.now();
      final parsedExpiryTime = DateTime.parse(expiryTimeString);
      if (parsedExpiryTime.isBefore(now)) {
        _authenticateUser = null;
        notifyListeners();
        return;
      }
      final String userEmail = preferences.getString('userEmail');
      final String userId = preferences.getString('userId');
      final int tokenLifespan = parsedExpiryTime.difference(now).inSeconds;
      setAuthTimeout(tokenLifespan);
      _authenticateUser = User(id: userId, email: userEmail, token: token);
      _userSubject.add(true);
      notifyListeners();
    }
  }

  void logout() async {
    _authenticateUser = null;
    _authTimer.cancel();
    _selProductId=null;
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    preferences.remove('token');
    preferences.remove('userEmail');
    preferences.remove('userId');
    _userSubject.add(false);
    // notifyListeners();
  }

  void setAuthTimeout(int time) {
    _authTimer = Timer(Duration(seconds: time), logout);
  }
}

class UtilityModel extends ConnectedProductsModel {
  bool get isLoading {
    return _isLoading;
  }
}
