import 'package:flutter/material.dart';

import '../models/location_data.dart';

class Product {
  final String id;
  final String title;
  final String description;
  final double price;
  final String image;
  final String imagePath;
  final bool isFavorite;
  final String email;
  final LocationData locationData;
  final String userId;
  Product(
      {
        @required this.id,
        @required this.title,
      @required this.description,
      @required this.price,
      @required this.image,
      @required this.imagePath,
      @required this.email,
      @required this.locationData,
      @required this.userId,
      this.isFavorite=false});
}
