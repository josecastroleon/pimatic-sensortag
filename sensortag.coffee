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
      left:
        description: "State of left button"
        type: "boolean"
        labels: ['on','off']
      right:
        description: "State of right button"
        type: "boolean"
        labels: ['on','off']


    temperature: 0.0
    humidity: 0.0
    pressure: 0.0
    left: false
    right: false

    constructor: (@config) ->
      @id = config.id
      @name = config.name
      @interval = config.interval
      @timeout = config.timeout
      @uuid = config.uuid
      super()
      @discoverAndConnectSensorTag @uuid

    discoverAndConnectSensorTag: (uuid) =>
      setTimeout(=>
        env.logger.debug "launching 1st request for device #{@name} after #{@timeout}"
        SensorTag.discover (sensorTag, uuid) =>
          if sensorTag.uuid != @uuid
            env.logger.debug "uuid discovered does not match for device #{@name} retrying"
            @discoverAndConnectSensorTag @uuid
          else
            env.logger.debug "uuid discovered matches for device #{@name} connecting"
            sensorTag.connect =>
              env.logger.debug "device #{@name} connected"
              sensorTag.discoverServicesAndCharacteristics =>
                env.logger.debug "launching read on device #{@name}"
                @readSensorTagData sensorTag
                setInterval( =>
                  env.logger.debug "launching read for device #{@name} after #{@interval}"
                  @readSensorTagData sensorTag
                , @interval)
      , @timeout) 

     readSensorTagData: (sensorTag) => 
       sensorTag.on "simpleKeyChange", (left, right) =>
         @emit "left", Boolean left
         @emit "right", Boolean right
       sensorTag.notifySimpleKey =>
       sensorTag.enableBarometricPressure =>
         setTimeout(=>
           sensorTag.readBarometricPressure (pressure) =>
             @emit "pressure", Number pressure.toFixed(1)
             sensorTag.disableBarometricPressure
         , 1000)         
       sensorTag.enableHumidity =>
         setTimeout(=>
           sensorTag.readHumidity (temperature, humidity) =>
             @emit "temperature", Number temperature.toFixed(1)
             @emit "humidity", Number humidity.toFixed(1)
             sensorTag.disableHumidity =>
         , 1000)

    getTemperature: -> Promise.resolve @temperature
    getHumidity: -> Promise.resolve @humidity
    getPressure: -> Promise.resolve @pressure
    getLeft: -> Promise.resolve @left
    getRight: -> Promise.resolve @right

  plugin = new SensorTagPlugin
  return plugin
