import 'package:flutter/material.dart';

class CardDashbordScreen extends StatelessWidget {
  const CardDashbordScreen({
    Key? key,
    required this.icon,
    required this.title,
    required this.number,
    required this.colorBackground,
    required this.colorIcon,
    required this.subtitle,
  }) : super(key: key);

  final IconData icon;
  final String title;
  final String number;
  final Color colorBackground;
  final Color colorIcon;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 10.0,
          horizontal: 8.0,
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    color: colorBackground,
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: colorIcon,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 90,
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  number,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(subtitle),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
