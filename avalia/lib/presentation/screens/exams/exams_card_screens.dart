import 'package:flutter/material.dart';
class CardExamsScreens extends StatelessWidget {
  const CardExamsScreens({Key? key, required this.title, required this.status, required this.colorBorder, required this.colorBackground ,required this.icon}) : super(key: key);

  final String title;
  final String status;
  final Color colorBorder;
  final IconData icon;
  final Color colorBackground;


  @override
  Widget build(BuildContext context) {
    return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border(left: BorderSide(color: colorBorder, width: 5)),
                color: Colors.white,
              ),
              child:  Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(children: [
                             Container(
                              height: 30,
                              width: 30,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                color: colorBackground,
                              ),
                              child: Icon(icon, color:colorBorder, size: 20,),
                             ),
                          SizedBox(width: 8.0),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          
                            Text(title),
                            Text(status, style: TextStyle(color:colorBorder),),
                          ],),
                          ]),
                         
                         
                          
                          
                        ],
                         
                        )
                  
                )
                );
            
  }
}


