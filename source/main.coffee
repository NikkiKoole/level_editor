Graph = require './graph'
                   
# g = new Graph()
#a = g.addNode({x:100,y:100})
#b = g.addNode({x:120,y:120})
# c = g.addNode({x:220,y:220})
# d = g.addNode({x:520,y:520})
# edge = g.addEdge(a, b)
# edge = g.addEdge(b, a)
# edge = g.addEdge(a, c)
# edge = g.addEdge(b, c)
# g.changeNode({x:220,y:220}, {x:520,y:520})
# console.log g.getEdgesAttachedTo(c)

# methods of this dict should return some object I can pass to a diff tool
class WallDict
    constructor:->
        @last_int_key = 0
        @map = {}
    add: (item) ->
        @map[@last_int_key+=1] = item
    remove: (item) ->
    update: (item, value) ->    

class Floorplan
    constructor:->
        @walls = new WallDict() # edge likes

class Editor
    constructor: ->
        
        @walls = [] # displayObjects

    #addWall: (a, b) ->
    #    @floorplan.walls.add {a:a, b:b}

    #moveWall: (wall, dx, dy) ->
    #    @floorplan.walls.update(wall, {dx:dx, dy:dy}) 

    triggerChange:(fn) ->
        
a = {x:100, y:100}
b = {x:200, y:200}    
floorplan = new Floorplan()                
editor = new Editor()
wall = editor.triggerChange(floorplan.walls.add({a:a, b:b}))
#editor.moveWall(wall, -100, 0)
