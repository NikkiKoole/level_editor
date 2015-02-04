{getLengthAndRotation, findIntersection, orderIntersections, getOther} = require './math'



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

    updateWall:(wall, p1, p2) ->
        diffs = []
        diffs.push {operation:'remove', type:'wall', obj:wall.ref}
        a = p1
        b = getOther(p2, [wall.ref.a, wall.ref.b])
        diffs.push  {operation:'add', type:'wall', obj:{a:a,b:b}}
        diffs

    addMultipleWalls: (walls) ->
        # this function is very similar to the single wall addWall version.
        # the difference is the possibility of more then one of the walls you are adding subdividing the same already thefre wall.
        #
        #  ...........
        #  .         .1
        #  .     .........
        #  .     .   .2  .
        #  .     .   .   .
        #  .     .........
        #  .         .3
        #  . .........
        #
       
        diff = []
        # at its basis this function just does 4 walls as opposed to 1
        intersections = []
        for wall,i in walls
            for w,j in @walls
                intersection = findIntersection(wall.a, wall.b, w.a, w.b)
                if intersection isnt undefined and (not anyIsEqual([wall.a, wall.b, w.a, w.b], intersection))
                    intersections.push {intersection:intersection, newWallIndex:i, oldWallIndex:j}

        # now can I just run through all existing walls and see what I should do?
        for existing,index in @walls
            console.log 'index: ',index,(i for i in intersections when i.oldWallIndex is index)
            # todo make a better subdivideExistingWall that handles these cases

        # now can I just run through all 4 walls and see what I should do with them?
        for newer,index in walls
            data = (i for i in intersections when i.newWallIndex is index)
            if data.length is 0 # this new wall doesnt have any intersections, so it's the simnplest   
                addWallSimply(newer, diff, @walls)
            else
                # this code is very duplicate from the addWall
                inters = []
                for inter in data
                    inters.push inter.intersection
                orderIntersections(newer, inters)
                inters.unshift(newer.a)
                inters.push(newer.b)
                subdivideNewWall(inters, diff, @walls)
                                
        #console.log intersections
        return diff

                

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
