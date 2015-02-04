module.exports.getLengthAndRotation = getLengthAndRotation = (sp, ep) ->
    middle: {x:(sp.x+ep.x) / 2, y:(sp.y+ep.y) / 2} # middle not needed anymore
    length: Math.sqrt((sp.x-ep.x) * (sp.x-ep.x) + (sp.y-ep.y) * (sp.y-ep.y))
    rotation: Math.atan2(ep.y-sp.y, ep.x-sp.x)

module.exports.getOther = (test, pair) ->
    for v in pair
        if v.x isnt test.x or v.y isnt test.y
            return v

module.exports.orderIntersections = (line, intersections) ->
    # I will order the intersections using distance from line.a
    distanceTo = (a,b) ->
        getLengthAndRotation(a, b).length

    compare = (a, b) ->
        if distanceTo(a, line.a) < distanceTo(b,line.a)
            return -1
        if distanceTo(a, line.a) > distanceTo(b, line.a)
            return 1
        return 0
    intersections.sort(compare)

module.exports.findIntersection = (a, b, a1, b1) ->
    dx = b.x - a.x
    dy = b.y - a.y
    dx1 = b1.x - a1.x
    dy1 = b1.y - a1.y
    denom = dx * dy1 - dx1 * dy

    if denom is 0
        return undefined

    denomPositive = denom > 0

    dxa = a.x - a1.x
    dya = a.y - a1.y

    s = dx * dya - dy * dxa

    if (s < 0) is denomPositive
        return undefined

    t = dx1 * dya - dy1 * dxa

    if (t < 0) is denomPositive
        return undefined

    if (s > denom) is denomPositive or (t > denom) is denomPositive
        return undefined

    t = t / denom
    intersection = x:a.x + (t * dx), y:a.y + (t * dy)
