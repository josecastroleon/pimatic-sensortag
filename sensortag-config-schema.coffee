module.exports = {
  title: "Weather"
  type: "object"
  properties:
    interval:
      description: "Interval between requests"
      format: Number
      default: 60000
}
