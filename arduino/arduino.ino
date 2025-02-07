#include <Servo.h>
int servoPins[]={3,5,6,9,10,11};
int sensorPins[6][2]={{2,4},{7,8},{12,13},{16,17},{14,15},{18,19}};
float distance[6]={0};
bool parkState[6];
int data[6];
int parts[6];
Servo servos[6];
int servoStateAngel[2][6]={{90,90,0,90,0,0},{0,0,90,0,90,90}};
void setup() {
  // put your setup code here, to run once:
  Serial.begin(9600);
  for(int i=0;i<6;i++){
    data[i]=0;
    parts[i]=0;
    parkState[i]=true;
    pinMode(sensorPins[i][0],OUTPUT);
    pinMode(sensorPins[i][1],INPUT);
    servos[i].attach(servoPins[i]);
    servos[i].write(servoStateAngel[0][i]);
  }
}
long sure[6];
void getDistance(){
  for(int i=0;i<6;i++){
    digitalWrite(sensorPins[i][0],LOW);
    delayMicroseconds(5);
    digitalWrite(sensorPins[i][0],HIGH);
    delayMicroseconds(10);
    sure[i]=pulseIn(sensorPins[i][1],HIGH);
    distance[i]=sure[i]*0.03432/2;
  }
 
 
}
void getParts(){
   for(int i=0;i<6;i++){
       if(distance[i]<10 && parkState[i]==true){
          data[i]=2;
       }else if(parkState[i]==false){
          data[i]=1;
       }else if(distance[i]>=10){
          data[i]=0;
       }
   }
   //Serial.println("");
}
void printParts(){
  bool state=false;
  getParts();
  for(int i=0;i<6;i++){
      if(data[i]!=parts[i]){
        parts[i]=data[i];
        state = true;
      }
   }
   if(state){
        for(int i=0;i<6;i++){
          Serial.print(parts[i]);
          Serial.print(",");
       }
       Serial.println("");
    }
}
void getData(){
    String rData;
    if(Serial.available()>0){
      rData = Serial.readStringUntil("\n");
      //Serial.println(rData);
      int konum=rData.indexOf(":");
      int partsNumber = rData.substring(0,konum).toInt();
      int pstate = rData.substring(konum+1).toInt();
      parkState[partsNumber]=pstate==1 ? false:true;
      servos[partsNumber].write(servoStateAngel[pstate][partsNumber]);
    }
}
void loop() {
  // put your main code here, to run repeatedly:
  getDistance();
  printParts();
  getData();
  delay(50);
}
