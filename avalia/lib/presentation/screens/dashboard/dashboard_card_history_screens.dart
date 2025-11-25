import 'package:flutter/material.dart';
class HistoryScreens extends StatelessWidget {
  const HistoryScreens({Key? key, required this.icon, required this.colorBackground, required this.colorIcon, required this.title, required this.subtitle, required this.datetime}) : super(key: key);  

  final IconData icon;
  final String title;
  final String subtitle;
  final DateTime datetime;
  final Color colorBackground;
  final Color colorIcon;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation:0.5,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 10.0, horizontal:8.0),
        child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Container(height: 30, width: 30,decoration: BoxDecoration(borderRadius: BorderRadius.circular(30), color: colorBackground), child: Icon(icon, color: colorIcon, size: 15,),),
          SizedBox(width: 16.0),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(fontWeight: FontWeight.bold,),), Text(subtitle, style: TextStyle(fontSize: 12),)],),),
          Text(formatDateTime(datetime), style: TextStyle(fontSize: 12),),
        ]
      )
      )
    );
  }
}

String formatDateTime(DateTime date) {
  final now = DateTime.now();
  final difference = now.difference(date);

  if (difference.inMinutes < 1) {
    return 'agora';
  } else if (difference.inHours < 1) {
    return 'há ${difference.inMinutes} minutos';
  } else if (difference.inHours < 24) {
    return 'há ${difference.inHours} horas';
  } else if (difference.inDays == 1) {
    return 'ontem';
  } else if (difference.inDays == 2) {
    return 'antes de ontem';
  } else if (difference.inDays < 7) {
    return 'há ${difference.inDays} dias';
  } else if (difference.inDays < 14) {
    return 'há 1 semana';
  } else if (difference.inDays < 21) {
    return 'há 2 semanas';
  } else if (difference.inDays < 28) {
    return 'há 3 semanas';
  } else if (difference.inDays < 365) {
    final months = (difference.inDays / 30).floor();
    return months > 1 ? 'há $months meses' : 'há 1 mês';
  } else {
    final years = (difference.inDays / 365).floor();
    return years > 1 ? 'há $years anos' : 'há 1 ano';
  }
}
