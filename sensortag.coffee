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
        setInterval( =>
          env.logger.debug "launching request for device #{@name} after #{@interval}"
          @requestSensorTagData(@uuid)
        , @interval
        )
      , @timeout
      )

    requestSensorTagData: (uuid) =>
      SensorTag.discover (sensorTag, uuid) =>
        if sensorTag.uuid != @uuid
          env.logger.debug "uuid discovered does not match for device #{@name} retrying"
          @requestSensorTagData(@uuid)
        else
          env.logger.debug "uuid discovered matches for device #{@name} connecting"
          sensorTag.connect =>
            env.logger.debug "device #{@name} connected"
            sensorTag.discoverServicesAndCharacteristics =>
              sensorTag.enableBarometricPressure =>
                sensorTag.enableHumidity =>
                  sensorTag.readHumidity (temperature, humidity) =>
                    @emit "temperature", Number temperature.toFixed(1)
                    @emit "humidity", Number humidity.toFixed(1)
                    sensorTag.disableHumidity =>
                      sensorTag.readBarometricPressure (pressure) =>
                        @emit "pressure", Number pressure.toFixed(1)
                        sensorTag.disconnect =>
                          env.logger.debug "device #{@name} disconnected"

    getTemperature: -> Promise.resolve @temperature
    getHumidity: -> Promise.resolve @humidity
    getPressure: -> Promise.resolve @pressure

  plugin = new SensorTagPlugin
  return plugin
