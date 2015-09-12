module.exports = (env) ->
  Promise = env.require 'bluebird'
  convict = env.require "convict"
  assert = env.require 'cassert'
  
  SensorTag = require "sensortag"
  events = require "events"

  class SensorTagPlugin extends env.plugins.Plugin
    init: (app, @framework, @config) =>
      deviceConfigDef = require("./device-config-schema")
      @devices = []

      @framework.deviceManager.registerDeviceClass("SensorTagDevice", {
        configDef: deviceConfigDef.SensorTagDevice,
        createCallback: (config) =>
          @devices.push config.uuid
          new SensorTagDevice(config)
      })
      
      @framework.on "after init", =>
        @ble = @framework.pluginManager.getPlugin 'ble'
        if @ble?
          @ble.registerName 'SensorTag'
          @ble.registerName 'TI BLE Sensor Tag'
          @ble.registerName 'CC2650 SensorTag'
          @ble.registerName 'SensorTag 2.0'
          (@ble.addOnScan device for device in @devices)
          @ble.on("discover", (peripheral) =>
            @emit "discover-"+peripheral.uuid, peripheral
          )
        else
          env.logger.warn "sensortag could not find ble. It will not be able to discover devices"

    addOnScan: (uuid) =>
      env.logger.debug "Adding device "+uuid
      @ble.addOnScan uuid

    removeFromScan: (uuid) =>
      env.logger.debug "Removing device "+uuid
      @ble.removeFromScan uuid

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
      @uuid = config.uuid
      @type = config.type
      @peripheral = null
      @connected = false
      super()
      plugin.on("discover-#{@uuid}", (peripheral) =>
        env.logger.debug "device #{@name} found"
        if not @connected
          @connected = true
          @connect peripheral
      )

    connect: (peripheral) =>
      @peripheral = peripheral
      sensorTag = switch @type
        when 'CC2540' then new SensorTag.CC2540(peripheral)
        when 'CC2650' then new SensorTag.CC2650(peripheral)
        else null
      sensorTag.on 'disconnect', =>
        env.logger.debug "device #{@name} disconnected"
        plugin.addOnScan @uuid
        @connected = false
      sensorTag.connect =>
        env.logger.debug "device #{@name} connected"
        plugin.removeFromScan peripheral.uuid
        sensorTag.discoverServicesAndCharacteristics =>
          env.logger.debug "launching read on device #{@name}"
          @readSensorTagData sensorTag
          setInterval( =>
            env.logger.debug "launching read for device #{@name} after #{@interval}"
            @readSensorTagData sensorTag
          , @interval)

    readSensorTagData: (sensorTag) => 
      sensorTag.on "simpleKeyChange", (left, right) =>
        @emit "left", Boolean left
        @emit "right", Boolean right
      sensorTag.notifySimpleKey =>
      sensorTag.enableBarometricPressure =>
        setTimeout(=>
          sensorTag.readBarometricPressure (callback, pressure) =>
            @emit "pressure", Number pressure.toFixed(1)
            sensorTag.disableBarometricPressure
        , 1000)         
      sensorTag.enableHumidity =>
        setTimeout(=>
          sensorTag.readHumidity (callback, temperature, humidity) =>
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
