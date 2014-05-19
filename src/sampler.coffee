# Point with temporal information
#
# x,y = spatial coordinates
class Point
  @ZERO = new Point(0,0)
  @UNIT = new Point(Math.SQRT1_2, Math.SQRT1_2)

  # construct a Point from polar cooridnates
  #
  # angle in radians (degree * Math.PI/180)
  @polar = (length, angle)->
    x = Math.cos(angle)*length
    y = Math.sin(angle)*length
    new Point x, y

  constructor: (@x, @y)->

  # spatial (euklidean) distance
  ds: (other)->
    dx = Math.pow @x-other.x, 2
    dy = Math.pow @y-other.y, 2

    Math.sqrt dx+dy

  add: (other)->
    return this if other.x == 0 && other.y == 0
    new Point @x+other.x, @y+other.y

  mul: (scalar)->
    return this if scalar == 1
    new Point @x*scalar, @y*scalar

  sub: (other)->
    @add other.mul(-1)

  length: ->
    @ds Point.ZERO

  unit: ->
    l = @length()
    new Point @x/l, @y/l

  normalize: (length=1)->
    @unit().mul(length)

  equals: (other)->
    @x == other.x && @y = other.y

  toString: ->
    "(#{@x},#{@y})"

class Sampler
  constructor: (@offsetX, @offsetY)->
    @list = []

  capture: (e)->
    @list.push new Point(Math.round(e.clientX - @offsetX), Math.round(e.clientY - @offsetY))
