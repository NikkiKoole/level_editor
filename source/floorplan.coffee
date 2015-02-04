{getLengthAndRotation, findIntersection, orderIntersections} = require './math'

wallsAreEqual = (wall1, wall2) ->
    if wall1.a.x is wall2.a.x and wall1.a.y is wall2.a.y
        if wall1.b.x is wall2.b.x and wall1.b.y is wall2.b.y
            return true
    if wall1.a.x is wall2.b.x and wall1.a.y is wall2.b.y
        if wall1.b.x is wall2.a.x and wall1.b.y is wall2.a.y
            return true
    return false

anyWallEqual = (collection, w) ->
    for wall in collection
        if wallsAreEqual wall, w
            return true
    return false

pointsAreEqual = (p1, p2) ->
    (p1.x is p2.x and p1.y is p2.y)

anyIsEqual = (collection, p) ->
    for c in collection
        if pointsAreEqual c,p
            return true
    return false
    
module.exports = class Floorplan
    constructor: ->
        @walls = []

    addWall: (wall) ->
        diff = []
        intersections = []
        
        for w in @walls
            intersection = findIntersection(wall.a, wall.b, w.a, w.b)
            if intersection isnt undefined
                if (anyIsEqual([wall.a, wall.b, w.a, w.b], intersection))
                    continue
                intersections.push intersection
                subdivideExistingWall(intersection, w, diff, @walls)
                
        if intersections.length is 0
            addWallSimply(wall, diff, @walls)
        else
            orderIntersections(wall, intersections)
            intersections.unshift(wall.a)
            intersections.push(wall.b)
            subdivideNewWall(intersections, diff, @walls)
        return diff

addWallSimply = (wall, diff, walls) ->
    diff.push ({operation:'add', type:'wall', obj:wall})
         
subdivideExistingWall = (intersection, wall, diff, walls) ->
    diff.push ({operation:'remove', type:'wall', obj:wall})
    part1 = {a:wall.a, b:intersection}
    diff.push ({operation:'add', type:'wall', obj:part1})
    part2 = {a:wall.b, b:intersection}
    diff.push ({operation:'add', type:'wall', obj:part2})
    diff

subdivideNewWall = (intersections, diff, walls) ->
    for s,i in intersections
        if i >= intersections.length-1
            continue
        part = {a:s, b:intersections[i+1]}
        diff.push ({operation:'add', type:'wall', obj:part}) 
