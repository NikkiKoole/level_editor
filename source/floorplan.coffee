{getLengthAndRotation, findIntersection, orderIntersections} = require './math'


module.exports = class Floorplan
    constructor: ->
        @walls = []

    addWall: (wall) ->
        diff = []
        intersections = []
        for w in @walls
            intersection = findIntersection(wall.a, wall.b, w.a, w.b)
            if intersection isnt undefined
                intersections.push intersection
                subdivideExistingWall(intersection, w, diff)
        if intersections.length is 0
            addWallSimply(wall, diff)
        else
            orderIntersections(wall, intersections)
            intersections.unshift(wall.a)
            intersections.push(wall.b)
            subdivideNewWall(intersections, diff)
        return diff

addWallSimply = (wall, diff) ->
    diff.push ({operation:'add', type:'wall', obj:wall})
         
subdivideExistingWall = (intersection, wall, diff) ->
    diff.push ({operation:'remove', type:'wall', obj:wall})
    part1 = {a:wall.a, b:intersection}
    diff.push ({operation:'add', type:'wall', obj:part1})
    part2 = {a:wall.b, b:intersection}
    diff.push ({operation:'add', type:'wall', obj:part2})
    diff

subdivideNewWall = (intersections, diff) ->
    for s,i in intersections
        if i >= intersections.length-1
            continue
        part = {a:s, b:intersections[i+1]}
        diff.push ({operation:'add', type:'wall', obj:part}) 
