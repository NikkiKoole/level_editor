Floorplan = require './floorplan'
{getLengthAndRotation} = require './math'

UndoRedo = require './undoredo'
stage = null
renderer = null          

removeItemFrom = (array, item) ->
    index = array.indexOf item
    if index > -1
        array.splice(index, 1)

isInArray = (array, item) ->
    (array.indexOf item) isnt -1

getOther = (test, pair) ->
    for v,i in pair
        if v.x isnt test.x or v.y isnt test.y
            return {value:v, index:i}
      
roundAllValues = (p) ->
    p.a.x = parseInt p.a.x
    p.a.y = parseInt p.a.y
    p.b.x = parseInt p.b.x
    p.b.y = parseInt p.b.y
    p

pointAreEqual = (p1, p2) ->
    (p1.x is p2.x and p1.y is p2.y)
        

class CornerDict
    constructor: ->
        @data = {}

    createCorner: (x,y) ->
        corner = @data["#{x}_#{y}"]
        if corner isnt undefined
            return corner
        newlyMade = new Corner(x, y)
        @data["#{x}_#{y}"] = newlyMade
        newlyMade

    remove: (c) ->
        delete @data["#{c.x}_#{c.y}"]

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
        @visible = true

class Editor extends PIXI.DisplayObjectContainer
    constructor: ->
        super()
        @underlay = new PIXI.Graphics()
        @underlay.hitArea = new PIXI.Rectangle(0,0,800,600)
        @underlay.interactive = true
        @addChild @underlay
        @tempGraphics = new PIXI.Graphics()
        
        @addUnderlayEvents(@underlay)
        @floorplan = new Floorplan()
        @walls = []
        @wallLayer = new PIXI.DisplayObjectContainer()
        @addChild @wallLayer
        @cornerLayer = new PIXI.DisplayObjectContainer()
        @addChild @cornerLayer

        @addChild @tempGraphics
        @undoRedo = new UndoRedo()
        @drawMode = undefined
        @corners = new CornerDict()

    setDrawMode: (mode) ->
        @drawMode = mode

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
                if (@sp and @ep) and (not pointAreEqual(@sp, @ep))
                    @dragging = false
                    @tempGraphics.clear()
                    @applyDiffs(@floorplan.addWall({a:@sp, b:@ep}))
                    @sp = undefined
                    @ep = undefined
                    renderer.render stage

    addCornerEvents: (corner) ->
        @usingCorner = undefined
        corner.mousedown = =>
            if @drawMode is 'move'
                @usingCorner = corner
                @usingCorner.alpha = 0.1
                for wall in @usingCorner.walls
                    wall.alpha = 0.1
            
        corner.mouseup = corner.mouseupoutside = (e) =>
            if @drawMode is 'move'
                if @usingCorner and (@usingCorner is corner)
                    @usingCorner.alpha = 1
                    removeDiffs = []
                    addDiffs = []
                    diffs = []
                    for wall in @usingCorner.walls
                        removeDiffs.push {operation:'remove', type:'wall', obj:wall.ref}
                        a = x:e.global.x, y:e.global.y
                        b = getOther(@usingCorner.position, [wall.ref.a, wall.ref.b]).value
                        addDiffs.push {operation:'add', type:'wall', obj:{a:a,b:b}}
                    @usingCorner = undefined
                    @tempGraphics.clear()
                    # todo think of a way of combining these two removeDiffs/d2 succesfully.
                    # maybe I can make a floorplan.updateWall function that returns a diff.

                    @applyDiffs removeDiffs
                    d2 = []
                    for d in addDiffs
                        newer = @floorplan.addWall(d.obj)
                        for b in newer
                            d2.push b
                    @applyDiffs(d2)
                    renderer.render stage

        corner.mousemove = (e) =>
            if @drawMode is 'move'
                if @usingCorner and (@usingCorner is corner)
                    @tempGraphics.clear()
                    @tempGraphics.beginFill(0xff0000)
                    @tempGraphics.drawCircle(e.global.x, e.global.y, 10, 10)
                    for wall in @usingCorner.walls
                        @tempGraphics.lineStyle(10, 0xffff00)
                        @tempGraphics.moveTo(e.global.x, e.global.y)
                        p = getOther(@usingCorner.position, [wall.ref.a, wall.ref.b]).value
                        @tempGraphics.lineTo(p.x, p.y)
                    renderer.render stage


    
    applyDiffs: (diffs, putInUndoStack = true) ->
        if putInUndoStack
            @undoRedo.clearRedoFuture() # kill 'back to the future alternate timeline'
            @undoRedo.constructUndoable diffs
        #console.log '...'
        for diff in diffs
            if diff.type is 'wall'
                #console.log diff.operation, diff.obj.a, diff.obj.b
                if diff.operation is 'add'
                    diff.obj = roundAllValues diff.obj
                    
                    wall = new PIXI.Graphics()
                    wall.beginFill(0xffffff * Math.random())
                    {length, rotation} = getLengthAndRotation(diff.obj.a, diff.obj.b)
                    
                    wall.drawRect(0, -4, length, 8)
                    wall.position = diff.obj.a
                    wall.rotation = rotation
                    wall.ref = diff.obj
                   
                    @walls.push wall
                    
                    corner1 = @corners.createCorner(diff.obj.a.x, diff.obj.a.y)
                    if not (isInArray @cornerLayer.children, corner1) # this IF might be unneeded but I want to be sure
                        @cornerLayer.addChild corner1
                        @addCornerEvents corner1
                    corner1.walls.push wall
                    
                    corner2 = @corners.createCorner(diff.obj.b.x, diff.obj.b.y)
                    if not (isInArray @cornerLayer.children, corner2) # this IF might be unneeded but I want to be sure
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
                        @wallLayer.removeChild wallToDelete
                        removeItemFrom @walls, wallToDelete
                        removeItemFrom @floorplan.walls, wallToDelete.ref

                        for c in @corners.all()
                            removeItemFrom c.walls, wallToDelete
                            if c.walls.length is 0
                                @corners.remove(c)
                                @cornerLayer.removeChild c
                                
        updateUICounter @walls.length, @corners.all().length  

updateUICounter = (amount, amount2) ->
    document.getElementById('counter').innerHTML = '# walls: '+amount+" corners length: "+amount2


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
    
