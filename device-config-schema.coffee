module.exports ={
  title: "pimatic-sensortag device config schemas"
  SensorTagDevice: {
    title: "SensorTagTemperature config options"
    type: "object"
    extensions: ["xLink", "xAttributeOptions"]
    properties:
      uuid:
        description: "uuid of the sensortag to connect"
        type: "string"
      type:
        description: "type of the sensortag CC2540 | CC2650"
        type: "string"
        default: "CC2540"
      interval:
        description: "Interval between requests"
        format: "number"
        default: 60000
  }
}
