module.exports = (env) ->
  Promise = env.require 'bluebird'
  convict = env.require "convict"
  assert = env.require 'cassert'
  
  SensorTag = require "sensortag"
  noble = require "noble"
  events = require "events"

  class SensorTagPlugin extends env.plugins.Plugin
    init: (app, @framework, @config) =>
      deviceConfigDef = require("./device-config-schema")
      @devices = []

      @framework.deviceManager.registerDeviceClass("SensorTagDevice", {
        configDef: deviceConfigDef.SensorTagDevice,
        createCallback: (config) =>
          @addOnScan config.uuid
          new SensorTagDevice(config)
      })

      @noble = require "noble"
      setInterval( =>
        if @devices?.length > 0
          env.logger.debug "Scan for devices"
          env.logger.debug @devices
          @noble.startScanning([],true)
      , 10000)

      @noble.on 'discover', (peripheral) =>
        if (peripheral.advertisement.localName == 'SensorTag' or peripheral.advertisement.localName == 'TI BLE Sensor Tag')
          @noble.stopScanning()
          @emit "discover-"+peripheral.uuid, peripheral

      @noble.on 'stateChange', (state) =>
        if state == 'poweredOn'
          @noble.startScanning([],true)

    addOnScan: (uuid) =>
      env.logger.debug "Adding device "+uuid
      @devices.push uuid

    removeFromScan: (uuid) =>
      env.logger.debug "Removing device "+uuid
      @devices.splice @devices.indexOf(uuid), 1

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
      sensorTag = new SensorTag(peripheral)
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
