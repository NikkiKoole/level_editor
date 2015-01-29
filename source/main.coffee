#Graph = require './graph'
{getLengthAndRotation, findIntersection} = require './math'
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
        # this function now only checks all OTHER walls to see if they should be divided.
        # I also think the original wall thats being added should be divided if it intersects others
        for w in @walls
            intersection = findIntersection(wall.a, wall.b, w.a, w.b)
            if intersection isnt undefined
                diff.push ({operation:'remove', type:'wall', obj:w})
                part1 = {a:w.a, b:intersection}
                diff.push ({operation:'add', type:'wall', obj:part1})
                part2 = {a:w.b, b:intersection}
                diff.push ({operation:'add', type:'wall', obj:part2})
        diff.push ({operation:'add', type:'wall', obj:wall})    
        diff


                              
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
                    
        console.log 'amount of editor  walls: ',@walls.length
        console.log 'amount of FP  walls: ', @floorplan.walls.length

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
