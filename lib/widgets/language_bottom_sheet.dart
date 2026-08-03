import 'package:flutter/material.dart';
import '../models/language.dart';

class LanguageBottomSheet {
  static void show(BuildContext context, AppLanguage currentLang, Function(AppLanguage) onSelected) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (ctx, scrollController) {
            return Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Select Language / زبان منتخب کریں',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: languages.length,
                    itemBuilder: (context, index) {
                      final lang = languages[index];
                      final isSelected = lang.code == currentLang.code;
                      return ListTile(
                        leading: Text(lang.flag, style: const TextStyle(fontSize: 28)),
                        title: Text(lang.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(lang.nativeName, style: TextStyle(color: Colors.grey.shade600)),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle, color: Colors.green, size: 28)
                            : const Icon(Icons.circle_outlined, color: Colors.grey, size: 28),
                        selected: isSelected,
                        onTap: () {
                          onSelected(lang);
                          Navigator.pop(ctx);
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}