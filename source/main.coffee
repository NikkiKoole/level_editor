{getLengthAndRotation, findIntersection, orderIntersections} = require './math'
UndoRedo = require './undoredo'
stage = null
renderer = null          

removeItemFrom = (array, item) ->
    index = array.indexOf item
    if index > -1
        array.splice(index, 1)
                                
class Floorplan
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
                                                                                      
class Editor extends PIXI.DisplayObjectContainer
    constructor: ->
        super()
        @underlay = new PIXI.Graphics()
        @underlay.hitArea = new PIXI.Rectangle(0,0,800,600)
        @underlay.interactive = true
        @addChild @underlay
        @tempGraphics = new PIXI.Graphics()
        @addChild @tempGraphics
        @addUnderlayEvents(@underlay)
        @floorplan = new Floorplan()
        @walls = []
        @undoRedo = new UndoRedo()
        
    addUnderlayEvents: (underlay) ->
        underlay.mousedown = (e) =>
            @dragging = true
            @sp = {x:e.global.x, y:e.global.y}

        underlay.mousemove = (e) =>
            if @dragging
                @ep = {x:e.global.x, y:e.global.y}
                @tempGraphics.clear()
                @tempGraphics.lineStyle(10,0xaa00aa)
                @tempGraphics.moveTo(@sp.x, @sp.y)
                @tempGraphics.lineTo(@ep.x, @ep.y)
                renderer.render stage
                
        underlay.mouseup = (e) =>
            @dragging = false
            @tempGraphics.clear()
            @applyDiffs(@floorplan.addWall({a:@sp, b:@ep}))
            renderer.render stage

    applyDiffs: (diffs, putInUndoStack = true) ->
        if putInUndoStack
            @undoRedo.clearRedoFuture() # kill 'back to the future alternate timeline'
            @undoRedo.constructUndoable diffs

        for diff in diffs
            if diff.type is 'wall'
                if diff.operation is 'add'
                    wall = new PIXI.Graphics()
                    wall.beginFill(0xffffff * Math.random())
                    {length, rotation} = getLengthAndRotation(diff.obj.a, diff.obj.b)
                    wall.drawRect(0, -5, length, 10)
                    wall.position.x = diff.obj.a.x
                    wall.position.y = diff.obj.a.y
                    wall.rotation = rotation
                    wall.ref = diff.obj
                    @addChild wall
                    @walls.push wall
                    @floorplan.walls.push diff.obj
                if diff.operation is 'remove'
                    wallToDelete = undefined
                    for w in @walls
                        if w.ref is diff.obj
                            wallToDelete = w
                            continue
                    @removeChild wallToDelete
                    removeItemFrom @walls, wallToDelete
                    removeItemFrom @floorplan.walls, wallToDelete.ref
        updateUICounter @walls.length       

updateUICounter = (amount) ->
    document.getElementById('counter').innerHTML = '# walls: '+amount


stage = new PIXI.Stage(0x888888)
renderer = new PIXI.autoDetectRenderer()
editor = new Editor()
stage.addChild editor
document.body.appendChild renderer.view


window.onload = ->
    renderer.render stage
    
window.undo = ->
    if editor.undoRedo.canUndo()
        d = editor.undoRedo.undo()
        editor.applyDiffs d, false
        renderer.render stage

window.redo = ->
    if editor.undoRedo.canRedo()
        d = editor.undoRedo.redo()
        editor.applyDiffs d, false
        renderer.render stage

window.info = ->
    editor.undoRedo.info()
