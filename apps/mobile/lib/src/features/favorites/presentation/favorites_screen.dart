import 'package:flutter/material.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Saved')),
    body: const Center(child: Text('Favorites + saved searches (MVP stub — backed by /api/v1/favorites).')),
  );
}
