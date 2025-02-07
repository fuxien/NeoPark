import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_udid/flutter_udid.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:otopark/MqttWrapper.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('OTOPARKÇI'),
        ),
        body: const BoxGrid(),
      ),
    );
  }
}

class BoxGrid extends StatefulWidget {
  const BoxGrid({Key? key}) : super(key: key);

  @override
  _BoxGridState createState() => _BoxGridState();
}

class _BoxGridState extends State<BoxGrid> {
  String _udid = "Unknown";
  late Timer timer;
  int remainingTime = 180;
  int dk=3;
  int sn=0;
  bool cirlularState=true;
  bool rezervationPage=false;
  int rid=-1;
  List<String>? parts;
  List<Color> colors = [Colors.green, Colors.yellow, Colors.red];
  String latestMessage="Henüz Mesaj Yok";
  late MQTTClientWrapper mqttWrapper;

  void _startCountdown() {
    timer = Timer.periodic(Duration(seconds: 1), (timer) {
      dk = remainingTime~/60;
      sn = remainingTime%60;
      setState(() {
        if (remainingTime > 0) {
          remainingTime--;
        } else {
          timer.cancel();
          onCountdownComplete();
        }
      });
    });
  }
  void onCountdownComplete() {
    // Sayaç tamamlandığında tetiklenecek olaylar
    print("Geri sayım tamamlandı!");
    // Örneğin bir Snackbar gösterimi
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Geri sayım tamamlandı!")),
    );

    cancelRezervation(rid);
  }
  Future<void> initPlatformState() async {
    String udid;
    try {
      udid = await FlutterUdid.udid;
    } on PlatformException {
      udid = 'Unknown';
    }

    //if (!mounted) return;

    setState(() {
      _udid = udid;

    });
    mqttWrapper = MQTTClientWrapper();
    mqttWrapper.prepareMqttClient(_updatedMessage,_udid);
  }

   void rezervationAttempt(int parkId) async{
     setState(() {
       cirlularState=true;
     });
    mqttWrapper.publishMessage("otopark/rezervation/"+_udid, parkId.toString());

    //return 0;
  }

  void cancelRezervation(int parkId) {
    setState(() {
      rezervationPage=false;
    });
    mqttWrapper.publishMessage("otopark/cancelRezervation/"+_udid, parkId.toString());
  }

  void _updatedMessage(String topicName,String message){
    setState(() {
      List<String> data = message.split(":");
      if(data[0]=="all") {
            parts = data[1].split(", ");
            if(data.length>2) {
              List<String> devices = data[2].split(", ");
              List<String> parkIds = data[3].split(", ");
              int i = 0;
              for (i = 0; i < devices.length; i++) {
                if (devices[i].toString() == _udid) {
                  rid = int.parse(parkIds[i]);
                  cirlularState = true;
                  rezervationPage = true;
                  print("Gelmesi Lazım");
                  break;
                }
                print(devices[i] + "-" + parkIds[i]);
              }
            }
          }
      else if(data[0]=="rezervation"){
        List<String> d = data[1].split(", ");
        if(d[1]==_udid && d[2]=="OK"){
          remainingTime=180;
          _startCountdown();
          rezervationPage=true;
          rid=int.parse(d[0]);
        }
        else if(d[1]==_udid && d[2]=="DENY"){
          rezervationPage=false;
          Fluttertoast.showToast(
              msg: "Rezervasyon İşlemi Bu Park Alanı İçin Başkası Tarafından Gerçekleştirilmiştir. ",
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
              timeInSecForIosWeb: 1,
              backgroundColor: Colors.red,
              textColor: Colors.white,
              fontSize: 16.0
          );
        }
      }
      cirlularState=false;
    });
  }
  @override
  void initState(){
    super.initState();
    initPlatformState();
  }
  @override
  Widget build(BuildContext context) {
    return cirlularState ? Center(child: CircularProgressIndicator()) : rezervationPage!=true ? Column(
      children: [
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(10),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // Her satırda 2 kutu olacak
              mainAxisSpacing: 10, // Dikey aralık
              crossAxisSpacing: 10, // Yatay aralık
              childAspectRatio: 0.8, // Kutuların en-boy oranı
            ),
            itemCount: 6, // Toplam 6 kutu
            itemBuilder: (context, index) {
              return BoxWidget(id: index, parentState: this,
                color: colors[int.parse(parts![index])], // Her kutuya renk ver
                title: "Park "+(index+1).toString(),
              );
            },
          ),
        ),
      ],
    ):Center(child: RezervationWidget(id:rid , parentState: this, color: Colors.yellow, title: "Park "+(rid+1).toString())) ;
  }
}

class BoxWidget extends StatelessWidget {
  final Color color;
  final String title;
  final _BoxGridState parentState;
  final int id;
  const BoxWidget({
    Key? key,
    required this.id,
    required this.parentState,
    required this.color,
    required this.title,
  }) : super(key: key);
  void rezervationClick(){
    if(parentState._udid=="Unknown") {
      Fluttertoast.showToast(
          msg: "Cihaz kimliği algılanamadı",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0
      );
    }else{
        parentState.rezervationAttempt(id);
    }

  }
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: color, // Durumdaki rengi kullan
              shape: BoxShape.circle, // Yuvarlak kutu
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          ElevatedButton(
              onPressed: color==Colors.green ? rezervationClick :null,child: Text("Rezerve Et"))
        ],
      ),
    );
  }
}

class RezervationWidget extends StatelessWidget {
  final Color color;
  final String title;
  final _BoxGridState parentState;
  final int id;
  const RezervationWidget({
    Key? key,
    required this.id,
    required this.parentState,
    required this.color,
    required this.title,
  }) : super(key: key);
  void rezervationClick(){
      parentState.cancelRezervation(id);
      parentState.timer.cancel();
  }
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
              parentState.dk.toString()+" Dakika "+parentState.sn.toString()+" Saniye",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold,fontStyle: FontStyle.italic,color: Colors.red),
          ),
          SizedBox(height: 50),
          Container(
            //width: 280,
            height: 80,
            decoration: BoxDecoration(
              color: color, // Durumdaki rengi kullan
              shape: BoxShape.circle, // Yuvarlak kutu
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          ElevatedButton(
              onPressed:  rezervationClick,child: Text("Serbest Bırak"))
        ],
      ),
    );
  }
}
