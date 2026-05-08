import 'package:flutter/material.dart';

import '../../services/localization_service.dart';

class SearchScreen extends StatelessWidget {
  final String currentLang;

  const SearchScreen({super.key, required this.currentLang});

  String t(String key) => LocalizationService.translate(key, currentLang);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(t('search')),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: t('search_hint'),
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Text(t('search_coming')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
