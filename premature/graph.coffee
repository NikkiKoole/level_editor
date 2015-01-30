SpatialHash = require './spatial'

class Node
    constructor: (@x, @y) ->
    clone: ->
        new Node(@x, @y)
    isEqual: (other)->
        (@x is other.x and @y is other.y)

class Edge
    constructor: (@a, @b, @thickness=10) ->
    isEqual:(other) ->
        ((@a.isEqual other.a) and (@b.isEqual other.b) or
         (@b.isEqual other.a) and (@a.isEqual other.b))
    isAttachedTo:(node) ->
        (@a.isEqual node) or (@b.isEqual node)
        
module.exports = class Graph
    constructor:->
        @map = new SpatialHash()
        @edges = []

    getEdgesAttachedTo: (node) ->
        edges = []
        for e in @edges
            if e.isAttachedTo node
                edges.push e
        edges
        
    hasEdge: (edge) ->
        (@getEdge edge) isnt undefined
        
    getEdge: (edge) ->
        for e in @edges
            if e.isEqual edge
                return e
        return undefined        

    addEdge: (@a, @b) ->
        edge = @getEdge({@a, @b})
        if edge is undefined
            edge = new Edge(@a, @b)
            @edges.push (edge)
        edge
          
    addNode: (position) ->
        if (@map.get position) is undefined
            @map.set new Node(position.x, position.y)    
        
    changeNode: (old_pos, new_pos) ->
        if (@map.get old_pos) isnt undefined
            @map.change(old_pos, new_pos)
