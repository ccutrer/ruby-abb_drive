# ABB Drive Gem

This gem is a Ruby library for interacting directly with ABB Drive systems,
such as the ACS550. It likely supports many other models that support
the same ABB Limited Drive Profile.

## Getting Started on a Raspberry Pi

Don't care for the nitty gritty details? Here's the easy path! You'll need a
Raspberry Pi (tested on a Pi Zero W and a Pi 4), a
[USB RS-485 adapter](https://www.amazon.com/gp/product/B07B416CPK),
and some wire. Any adapter based on the MAX485 chip is _not_ supported.
Follow drive's installation manual to connect RS485 + and -
to the appropriate terminals on the USB RS485 adapter.

### Software

[Set up your Pi](https://projects.raspberrypi.org/en/projects/raspberry-pi-setting-up)
using the latest Raspberry Pi OS, connect it to the network, and then open a
terminal window (either SSH to it or launch the terminal app with a local
keyboard). Then install the software:

```sh
sudo apt install ruby ruby-dev
sudo gem install rake abb_drive --no-doc
sudo apt install mosquitto
sudo curl https://github.com/ccutrer/ruby-abb_drive/raw/main/contrib/abb_drive_mqtt_bridge.service -L -o /etc/systemd/system/abb_drive_mqtt_bridge.service
sudo systemctl enable abb_drive_mqtt_bridge
sudo systemctl start abb_drive_mqtt_bridge
```

Congratulations, you should now be seeing data published to MQTT! You can
confirm this by using [MQTT Explorer](http://mqtt-explorer.com) and
connecting to raspberrypi.local.

### Integrating With Home Automation

#### OpenHAB

For OpenHAB, install the [MQTT Binding](https://www.openhab.org/addons/bindings/mqtt/),
and manually add an MQTT Broker thing connecting to raspberrypi.local. After
that, the ABB device will show up automatically in your inbox.

Now all the channels will be automatically created, and you just need to link them to
items.

You may or may not want to ignore the Home Assistant copy of discovered things.

## Installation

Install ruby 2.5, 2.6, or 2.7. Ruby 3.0 has not been tested. If talking
directly to the serial port, Linux is required. Mac may or may not work.
Windows probably won't work. If you want to run on Windows, you'll need to run
a network serial port (like with `ser2net`), and connect remotely from the
Windows machine. Then:

```sh
gem install abb_drive 
```

On Debian and Ubuntu, the following dependencies are needed to install the gem:

```sh
sudo apt install ruby ruby-dev
```

## MQTT/Homie Bridge

An MQTT bridge is provided to allow easy integration into other systems. You
will need a separate MQTT server running ([Mosquitto](https://mosquitto.org) is
a relatively easy and robust one). The MQTT topics follow the [Homie
convention](https://homieiot.github.io), making them self-describing. If you're
using a systemd Linux distribution, an example unit file is provided in
`contrib/abb_drive_mqtt_bridge.service`. So a full example would be (once you have
Ruby installed):

```sh
sudo curl https://github.com/ccutrer/ruby-abb_drive/raw/main/contrib/abb_drive_mqtt_bridge.service -L -o /etc/systemd/system/abb_drive_mqtt_bridge.service
sudo systemctl enable abb_drive_mqtt_bridge
sudo systemctl start abb_drive_mqtt_bridge
```

Be sure modify the file to pass the correct URI to your MQTT server and path
to RS-485 device. Also to change the "User" parameter to fit your environnment.

If you use MQTT authentication you can use the following format to provide
login information: mqtt://username:password@mqtt.domain.tld. If you use SSL/TLS
on your MQTT server, change the URI to be mqtts://. Be sure to URI-escape
special characters, and %'s must be doubled in the .service file. You may also
need to surround your MQTT URI in single quotes.

### Non-local Serial Ports

Serial ports over the network are also supported. Just give a URI like
tcp://192.168.1.10:2000/ instead of a local device. Be sure to set up your
server (like ser2net) to use 9600 baud, 2 stop bits, NONE parity. You can also
use RFC2217 serial ports (allowing the serial connection parameters to be set
automatically) with a URI like telnet://192.168.1.10:2217/.
