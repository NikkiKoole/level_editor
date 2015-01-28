module.exports = class SpatialHash
    constructor: ->
        @map = {}

    insert: (node) ->
        existing = @get node
        return existing if existing isnt undefined
        @set node
            
    get: (node) ->
        @map["#{node.x}_#{node.y}"]

    set: (node) ->
        @map["#{node.x}_#{node.y}"] = node

    remove: (node) ->
        existing = @get node
        if existing isnt undefined
            delete @map["#{node.x}_#{node.y}"]
        existing
        
    change: (node, new_pos) ->
        existing = @remove node
        existing.x = new_pos.x
        existing.y = new_pos.y
        @insert existing, new_pos
