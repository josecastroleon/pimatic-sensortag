module.exports ={
  title: "pimatic-sensortag device config schemas"
  SensorTagDevice: {
    title: "SensorTagTemperature config options"
    type: "object"
    properties:
      uuid:
        description: "uuid of the sensortag to connect"
        type: "string"
      interval:
        description: "Interval between requests"
        format: "number"
        default: 60000
  }
}
