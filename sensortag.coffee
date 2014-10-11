module.exports = (env) ->
  Promise = env.require 'bluebird'
  convict = env.require "convict"
  assert = env.require 'cassert'
  
  SensorTag = require "sensortag"

  class SensorTagPlugin extends env.plugins.Plugin
    init: (app, @framework, @config) =>
      deviceConfigDef = require("./device-config-schema")

      @framework.deviceManager.registerDeviceClass("SensorTagDevice", {
        configDef: deviceConfigDef.SensorTagDevice,
        createCallback: (config) => new SensorTagDevice(config)
      })

  class SensorTagDevice extends env.devices.Sensor
    attributes:
      temperature:
        description: "the messured temperature"
        type: "number"
        unit: '°C'
      humidity:
        description: "The actual degree of Humidity"
        type: "number"
        unit: '%'
      pressure:
        description: "The actual pressure"
        type: "number"
        unit: 'mbar'

    temperature: 0.0
    humidity: 0.0
    pressure: 0.0

    constructor: (@config) ->
      @id = config.id
      @name = config.name
      @interval = config.interval
      @timeout = config.timeout
      @uuid = config.uuid
      super()
      setTimeout(=>
        env.logger.debug "launching 1st request for device #{@name} after #{@timeout}"
        @requestSensorTagData(@uuid)
      , @timeout)

    discoverAndConnectSensorTag: (uuid) =>
      SensorTag.discover (sensorTag, uuid) =>
        if sensorTag.uuid != @uuid
          env.logger.debug "uuid discovered does not match for device #{@name} retrying"
          @discoverAndConnectSensorTagData @uuid
        else
          env.logger.debug "uuid discovered matches for device #{@name} connecting"
          sensorTag.connect =>
            env.logger.debug "device #{@name} connected"
            sensorTag.discoverServicesAndCharacteristics =>
              env.logger.debug "launching read on device #{@name}¨
              @readSensorTagData
              setInterval( =>
                env.logger.debug "launching read for device #{@name} after #{@interval}"
              , @interval)

     readSensorTagData: => 
       sensorTag.enableBarometricPressure =>
         sensorTag.enableHumidity =>
           sensorTag.readHumidity (temperature, humidity) =>
             @emit "temperature", Number temperature.toFixed(1)
             @emit "humidity", Number humidity.toFixed(1)
             sensorTag.disableHumidity =>
               sensorTag.readBarometricPressure (pressure) =>
                 @emit "pressure", Number pressure.toFixed(1)

    getTemperature: -> Promise.resolve @temperature
    getHumidity: -> Promise.resolve @humidity
    getPressure: -> Promise.resolve @pressure

  plugin = new SensorTagPlugin
  return plugin
