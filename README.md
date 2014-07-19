pimatic-sensortag
=================

Pimatic Plugin that retrieves some sensor data from TI Sensortag

Configuration
-------------
Add the plugin to the plugin section:

    {
      "plugin": "sensortag",
      "interval": 60000
    },

Then add several sensors for your device to the devices section:

    {
      "id": "sensortag-temperature",
      "class": "SensorTagTemperature",
      "name": "Temperature"
    },
    {
      "id": "sensortag-humidity",
      "class": "SensorTagHumidity",
      "name": "Humidity"
    },
    {
      "id": "sensortag-pressure",
      "class": "SensorTagPressure",
      "name": "Pressure"
    },

Then you can add the items into the mobile frontend
