import 'package:flutter/material.dart';
import '../models/language.dart';

class LanguageBottomSheet {
  static void show(BuildContext context, AppLanguage currentLang,
      Function(AppLanguage) onSelected) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final text = isDark ? Colors.white : Colors.black87;
    final sub = isDark ? Colors.white54 : Colors.grey.shade500;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: bg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          maxChildSize: 0.85,
          minChildSize: 0.35,
          expand: false,
          builder: (ctx, scrollController) {
            return Column(
              children: [
                Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(top: 10),
                    decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(2))),
                const Padding(
                  padding: EdgeInsets.all(14),
                  child: Text('Select Language / زبان منتخب کریں',
                      style:
                          TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: languages.length,
                    itemBuilder: (context, index) {
                      final lang = languages[index];
                      final selected = lang.code == currentLang.code;
                      return ListTile(
                        leading: Text(lang.flag,
                            style: const TextStyle(fontSize: 26)),
                        title: Text(lang.name,
                            style: TextStyle(
                                fontWeight: FontWeight.w600, color: text)),
                        subtitle:
                            Text(lang.nativeName, style: TextStyle(color: sub)),
                        trailing: selected
                            ? const Icon(Icons.check_circle,
                                color: Color(0xFF1ABC9C), size: 26)
                            : Icon(Icons.circle_outlined,
                                color: Colors.grey.shade500, size: 26),
                        selected: selected,
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
