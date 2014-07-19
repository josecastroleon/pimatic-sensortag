module.exports = (env) ->
  convict = env.require "convict"
  Q = env.require 'q'
  assert = env.require 'cassert'
  
  SensorTag = require "sensortag"

  class SensorTagPlugin extends env.plugins.Plugin
    init: (app, @framework, @config) =>
      @interval = config.interval

      SensorTag.discover (sensorTag) =>
        sensorTag.on "disconnect", =>
          console.log "disconnected!"
        
        sensorTag.connect =>
          sensorTag.discoverServicesAndCharacteristics =>
            setInterval (=>
              sensorTag.enableBarometricPressure =>
                sensorTag.enableHumidity =>
                  sensorTag.readHumidity (temperature, humidity) =>
                    @emit "sensortag-temperature", temperature.toFixed(1)
                    @emit "sensortag-humidity", humidity.toFixed(1)
                    sensorTag.disableHumidity =>
                      sensorTag.readBarometricPressure (pressure) =>
                        @emit "sensortag-pressure", pressure.toFixed(1)
            ), @interval

    createDevice: (config) =>
      switch config.class
        when "SensorTagTemperature"
          @framework.registerDevice(new SensorTagTemperature config)
          return true
        when "SensorTagHumidity"
          @framework.registerDevice(new SensorTagHumidity config)
          return true
        when "SensorTagPressure"
          @framework.registerDevice(new SensorTagPressure config)
          return true
        when "SensorTagBattery"
          @framework.registerDevice(new SensorTagBattery config)
          return true
        else
          return false

  class SensorTagTemperature extends env.devices.TemperatureSensor
    temperature: null

    constructor: (@config) ->
      @id = config.id
      @name = config.name
      super()
      plugin.on "sensortag-temperature", (temperature) =>
        @temperature = temperature
        @emit "temperature", temperature

    getTemperature: -> Q(@temperature)

  class SensorTagHumidity extends env.devices.Sensor
    attributes:
      humidity:
        description: "The actual degree of Humidity"
        type: Number
        unit: '%'
        
    humidity: null
        
    constructor: (@config) ->
      @id = config.id
      @name = config.name
      super()
      plugin.on "sensortag-humidity", (humidity) =>
        @humidity = humidity
        @emit "humidity", humidity
      
    getHumidity: -> Q(@humidity)

  class SensorTagPressure extends env.devices.Sensor
    attributes:
      pressure:
        description: "The actual pressure"
        type: Number
        unit: 'mbar'

    pressure: null

    constructor: (@config) ->
      @id = config.id
      @name = config.name
      super()
      plugin.on "sensortag-pressure", (pressure) =>
        @pressure = pressure
        @emit "pressure", pressure

    getPressure: -> Q(@pressure)

  class SensorTagBattery extends env.devices.Sensor
    attributes:
      battery:
        description: "The actual value of Battery"
        type: Number
        unit: '%'

    battery: null

    constructor: (@config) ->
      @id = config.id
      @name = config.name
      super()
      plugin.on "sensortag-battery", (battery) =>
        @battery = battery
        @emit "battery", battery

    getBattery: -> Q(@battery)

  plugin = new SensorTagPlugin
  return plugin
