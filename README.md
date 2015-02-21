pimatic-sensortag
=================

Pimatic Plugin that retrieves some sensor data from TI Sensortag

Configuration
-------------
If you don't have the pimatic-ble plugin add it to the plugin section:

    {
      "plugin": "ble"
    }

Then add the plugin to the plugin section:

    {
      "plugin": "sensortag"
    },

Then add the device entry for your device into the devices section:

    {
      "id": "sensortag-room",
      "class": "SensorTagDevice",
      "name": "Bedroom",
      "uuid": "01234567890a",
      "interval": 60000
    }

Then you can add the items into the mobile frontend
