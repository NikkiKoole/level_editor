Floorplan = require './floorplan'
{getLengthAndRotation} = require './math'

UndoRedo = require './undoredo'
stage = null
renderer = null          

removeItemFrom = (array, item) ->
    index = array.indexOf item
    if index > -1
        array.splice(index, 1)

roundAllValues = (p) ->
    p.a.x = parseInt p.a.x
    p.a.y = parseInt p.a.y
    p.b.x = parseInt p.b.x
    p.b.y = parseInt p.b.y

class CornerDict
    constructor: ->
        @data = {}

    createCorner: (x,y) ->
        console.log x,y
        corner = @data["#{x}_#{y}"]
        if corner isnt undefined
            return corner

        newlyMade = new Corner(x, y)
        @data["#{x}_#{y}"] = newlyMade
        newlyMade
    all: ->
        for own k of @data
            @data[k]

        
class Corner extends PIXI.DisplayObjectContainer
    constructor: (x, y)->
        super()
        graphics = new PIXI.Graphics()
        graphics.beginFill(0xffffff, 0.9)
        graphics.drawCircle(0,0,10,10)
        @addChild graphics
        @pivot = x:0, y:0
        @position = x:x, y:y
        @interactive = true
        @walls = []
        @visible = false

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
        @wallLayer = new PIXI.DisplayObjectContainer()
        @addChild @wallLayer
        @cornerLayer = new PIXI.DisplayObjectContainer()
        @addChild @cornerLayer
        
        @undoRedo = new UndoRedo()
        @drawMode = undefined
        @corners = new CornerDict()

    setDrawMode: (mode) ->
        @drawMode = mode
        if mode is 'move'
            for c in @corners.all()
                c.visible = true
            renderer.render stage
                
        else if mode is 'draw'
            for c in @corners.all()
                console.log c.visible
                c.visible = false
            renderer.render stage
            
    addUnderlayEvents: (underlay) ->
        underlay.mousedown = (e) =>
            if @drawMode is 'draw'
                @dragging = true
                @sp = {x:e.global.x, y:e.global.y}

        underlay.mousemove = (e) =>
            if @drawMode is 'draw'
                if @dragging
                    @ep = {x:e.global.x, y:e.global.y}
                    @tempGraphics.clear()
                    @tempGraphics.lineStyle(10,0xaa00aa)
                    @tempGraphics.moveTo(@sp.x, @sp.y)
                    @tempGraphics.lineTo(@ep.x, @ep.y)
                    renderer.render stage
                
        underlay.mouseup = (e) =>
            if @drawMode is 'draw'
                @dragging = false
                @tempGraphics.clear()
                @applyDiffs(@floorplan.addWall({a:@sp, b:@ep}))
                renderer.render stage

    addCornerEvents: (corner) ->
        @draggingCorner = false

        corner.click = =>
            console.log @draggingCorner
            console.log 'asdadsasd'
            @draggingCorner = true


    
    applyDiffs: (diffs, putInUndoStack = true) ->
        if putInUndoStack
            @undoRedo.clearRedoFuture() # kill 'back to the future alternate timeline'
            @undoRedo.constructUndoable diffs

        for diff in diffs
            if diff.type is 'wall'
                if diff.operation is 'add'
                    wall = new PIXI.Graphics()
                    wall.beginFill(0xffffff * Math.random())
                    #roundAllValues(diff.obj)
                    {length, rotation} = getLengthAndRotation(diff.obj.a, diff.obj.b)
                    
                    wall.drawRect(0, -4, length, 8)
                    wall.position = diff.obj.a
                    wall.rotation = rotation
                    wall.ref = diff.obj
                   
                    @walls.push wall
                    
                    corner1 = @corners.createCorner(diff.obj.a.x, diff.obj.a.y)
                    @cornerLayer.addChild corner1
                    @addCornerEvents corner1
                    corner1.walls.push wall
                    
                    corner2 = @corners.createCorner(diff.obj.b.x, diff.obj.b.y) 
                    @cornerLayer.addChild corner2
                    @addCornerEvents corner2
                    corner2.walls.push wall
                    
                    @wallLayer.addChild wall
                    @floorplan.walls.push diff.obj

                if diff.operation is 'remove'
                    wallToDelete = undefined
                    for w in @walls
                        if w.ref is diff.obj
                            wallToDelete = w
                            continue
                    if wallToDelete isnt undefined
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

window.setDrawMode = (mode) ->
    editor.setDrawMode(mode.id)
    
