import RPi.GPIO as GPIO
class RGBLED:
    def __init__(self,redPin,greenPin,bluePin,warnings=False,ledMode=False):
        GPIO.setmode(GPIO.BOARD)
        GPIO.setwarnings(warnings)
        self.redPin=redPin
        self.greenPin=greenPin
        self.bluePin=bluePin
        self.ledMode=ledMode
        GPIO.setup(self.redPin,GPIO.OUT)
        GPIO.setup(self.greenPin,GPIO.OUT)
        GPIO.setup(self.bluePin,GPIO.OUT)
    
    def setRed(self):
        GPIO.output(self.redPin,GPIO.HIGH if self.ledMode else GPIO.LOW)
        GPIO.output(self.greenPin,GPIO.LOW if self.ledMode else GPIO.HIGH)
        GPIO.output(self.bluePin,GPIO.LOW if self.ledMode else GPIO.HIGH)
    def setBlue(self):
        GPIO.output(self.bluePin,GPIO.HIGH if self.ledMode else GPIO.LOW)
        GPIO.output(self.greenPin,GPIO.LOW if self.ledMode else GPIO.HIGH)
        GPIO.output(self.redPin,GPIO.LOW if self.ledMode else GPIO.HIGH)
    def setGreen(self):
        GPIO.output(self.greenPin,GPIO.HIGH if self.ledMode else GPIO.LOW)
        GPIO.output(self.redPin,GPIO.LOW if self.ledMode else GPIO.HIGH)
        GPIO.output(self.bluePin,GPIO.LOW if self.ledMode else GPIO.HIGH)
    def setYellow(self):
        GPIO.output(self.redPin,GPIO.HIGH if self.ledMode else GPIO.LOW)
        GPIO.output(self.greenPin,GPIO.HIGH if self.ledMode else GPIO.LOW)
        GPIO.output(self.bluePin,GPIO.LOW if self.ledMode else GPIO.HIGH)

