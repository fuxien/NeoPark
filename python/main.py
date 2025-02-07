import time
import threading
import paho.mqtt.client as paho
from paho import mqtt
import serial
from rgbled import RGBLED
# Global değişkenler

rState=False # rezervasyon durumu
rezervationList={}
p=-5
rUser="" #rezervation User
refresh = False
parts = [0, 0, 0, 0, 0, 0]
data = ""
commands ="all"
state = True
lock = threading.Lock()  # Senkronizasyon için bir kilit mekanizması
ser = serial.Serial("/dev/ttyUSB0",9600,timeout=1)
leds = [RGBLED(40,38,36),RGBLED(37,35,33),RGBLED(26,24,22),RGBLED(23,21,19),RGBLED(15,13,11),RGBLED(3,7,5)]
# MQTT Callback fonksiyonları
def on_connect(client, userdata, flags, rc, properties=None):
    print("CONNACK received with code %s." % rc)

def on_publish(client, userdata, mid, properties=None):
    print("mid: " + str(mid))

def on_subscribe(client, userdata, mid, granted_qos, properties=None):
    print("Subscribed: " + str(mid) + " " + str(granted_qos))

def on_message(client, userdata, msg):
    global parts,p, data,rUser, refresh,commands,rState
    print(msg.topic + " " + str(msg.qos) + " " + str(msg.payload))
    topic = msg.topic.split("/")
    with lock:
        if topic[1]=="refresh":
            refresh = True
            commands="all"
        elif topic[1]=="rezervation":
            rUser = topic[2]
            p = int(msg.payload)
            if parts[p]==0:
                parts[p]=1
                rezervationList[rUser]=p
                commands="rezervation"
                rState=True
                sendData(p,1)
            else:
                rState=False
        elif topic[1]=="cancelRezervation":
            rUser = topic[2]
            p = int(msg.payload)
            if parts[p]!=0 and rezervationList[rUser]==p:
                parts[p]=0
                del rezervationList[rUser]
                refresh=True
                sendData(p,0)
    print("Commands: "+commands)
def ledControl():
    for i in range(6):
        if parts[i]==0:
            leds[i].setGreen()
        elif parts[i]==1:
            leds[i].setYellow()
        elif parts[i]==2:
            leds[i].setRed()
def sendData(partsNo,state):
    d=str(partsNo)+":"+str(state)+"\n"
    ser.write(d.encode('utf-8'))

def getData():
    if ser.in_waiting>0:
        d = ser.readline().decode('utf-8').strip()
        d = d.split(",")[:-1];
        for i in range(6):
            parts[i]=int(d[i]);
            refresh=True
        ledControl()
        print(f"Gelen Veri: {d}")
def publishComandsRezervation():
    global p,refresh,parts,commands
    response = str(p) + ", " + rUser + ", "
    print(response)
    if rState:
        response+="OK"
        refresh=True
    else:
        response+="DENY"
    client.publish("otopark/commands", payload="rezervation:" + response, qos=1, retain=True)

def publishComandsAll():
    global data,refresh,parts,rezervationList
    if data != str(parts) or refresh:
        ledControl()
        refresh = False
        print("Data gönderildi.")
        u, a = "", ""
        data = str(parts)
        veri="all:"+data[1:len(data) - 1]
        if len(rezervationList)>0:
            for k, v in rezervationList.items():
                u += k + ", "
                a += str(v) + ", "
            a = a[:-2]
            u = u[:-2]
            veri+=":"+u+":"+a

        client.publish("otopark/commands", payload=veri, qos=1, retain=True)

# Mesaj yayınlama fonksiyonu
def publishData(client):
    global data, refresh, parts,commands
    while True:  # Sürekli çalışacak bir döngü
        getData()
        with lock:  # Kilit mekanizması ile değişkenlere erişim
            if commands=="all":
                publishComandsAll()
            elif commands=="rezervation":
                publishComandsRezervation()
                commands="all"
        time.sleep(1)  # Yayınlama döngüsüne bir bekleme süresi ekle

# MQTT istemcisini ayarla
client = paho.Client(client_id="raspberry-pi", userdata=None, protocol=paho.MQTTv5)
client.on_connect = on_connect
client.on_publish = on_publish
client.on_subscribe = on_subscribe
client.on_message = on_message

connect_properties = paho.Properties(paho.PacketTypes.CONNECT)
connect_properties.SessionExpiryInterval = 0  # Oturum süresi 0, kalıcı oturum

# Güvenli bağlantı ayarları
client.tls_set(tls_version=mqtt.client.ssl.PROTOCOL_TLS)
client.username_pw_set("fuxien", "A1w2d3r4")
client.connect("3251f453d88242d9b41ed8d95f06ca9d.s1.eu.hivemq.cloud", 8883, properties=connect_properties)

# Abone ol
client.subscribe("otopark/#", qos=1)

# Yayınlama işlemini paralel bir thread olarak başlat
publish_thread = threading.Thread(target=publishData, args=(client,))
publish_thread.daemon = True  # Ana program sonlanınca thread de sonlanır
publish_thread.start()

# MQTT istemcisini döngüye başlat
client.loop_forever()
