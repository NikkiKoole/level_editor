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
    for v in pair
        if v.x isnt test.x or v.y isnt test.y
            return v

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
        @mode = undefined
        @corners = new CornerDict()

    setMode: (mode) ->
        @mode = mode
        
# drawing Lines
    startDrawingLine: (startPosition) ->
        @drawingLine = true
        @sp = startPosition
        @ep = undefined # paranoia

    updateDrawingLine: (tempPosition) ->
        @ep = tempPosition
        @tempGraphics.clear()
        @tempGraphics.lineStyle(10,0xaa00aa)
        @tempGraphics.moveTo(@sp.x, @sp.y)
        @tempGraphics.lineTo(@ep.x, @ep.y)
        
    endDrawingLine: (endPosition = @ep) ->
        @ep = endPosition
        @drawingLine = false
        @tempGraphics.clear()
        @applyDiffs(@floorplan.addWall({a:@sp, b:@ep}))
        @sp = undefined
        @ep = undefined

# drawing Rects
    startDrawingRect: (startPosition) ->
        @drawingRect = true
        @sp = startPosition
        @ep = undefined

    updateDrawingRect: (tempPosition) ->
        @ep = tempPosition
        @tempGraphics.clear()
        @tempGraphics.lineStyle(10,0xaa00aa)
        @tempGraphics.moveTo(@sp.x, @sp.y)
        @tempGraphics.lineTo(@ep.x, @sp.y)
        @tempGraphics.lineTo(@ep.x, @ep.y)
        @tempGraphics.lineTo(@sp.x, @ep.y)
        @tempGraphics.lineTo(@sp.x, @sp.y)

    endDrawingRect: (endPosition = @ep) ->
        @drawingRect = false
        @ep = endPosition
        @tempGraphics.clear()
        diffs = []
        diffs = diffs.concat(@floorplan.addWall({a:{x:@sp.x, y:@sp.y}, b:{x:@ep.x, y:@sp.y}}))
        diffs = diffs.concat(@floorplan.addWall({a:{x:@ep.x, y:@sp.y}, b:{x:@ep.x, y:@ep.y}}))
        diffs = diffs.concat(@floorplan.addWall({a:{x:@ep.x, y:@ep.y}, b:{x:@sp.x, y:@ep.y}}))
        diffs = diffs.concat(@floorplan.addWall({a:{x:@sp.x, y:@ep.y}, b:{x:@sp.x, y:@sp.y}}))
        @applyDiffs(diffs)
        @sp = undefined
        @ep = undefined


# dragging Corners
    startDraggingCorner: (corner) ->
        @draggingCorner = corner
        @draggingCorner.alpha = 0.1
        for wall in @draggingCorner.walls
            wall.alpha = 0.1
            
    updateDraggingCorner: (position) ->
        @tempGraphics.clear()
        @tempGraphics.beginFill(0xff0000)
        @tempGraphics.drawCircle(position.x, position.y, 10, 10)
        for wall in @draggingCorner.walls
            @tempGraphics.lineStyle(10, 0xffff00)
            @tempGraphics.moveTo(position.x, position.y)
            p = getOther(@draggingCorner.position, [wall.ref.a, wall.ref.b])
            @tempGraphics.lineTo(p.x, p.y)

    endDraggingCorner: (position)->
        @draggingCorner.alpha = 1
        diffs = []
        for wall in @draggingCorner.walls
            diffs.push {operation:'remove', type:'wall', obj:wall.ref}
            a = position
            b = getOther(@draggingCorner.position, [wall.ref.a, wall.ref.b])
            diffs.push  {operation:'add', type:'wall', obj:{a:a,b:b}}
        @draggingCorner = undefined
        @tempGraphics.clear()
        @applyDiffs diffs
        

    addUnderlayEvents: (underlay) ->
        underlay.mousedown = (e) =>
            if @mode is 'draw'
                @startDrawingLine({x:e.global.x, y:e.global.y})
            if @mode is 'rect'
                @startDrawingRect({x:e.global.x, y:e.global.y})

        underlay.mousemove = (e) =>
            if @mode is 'draw' and @drawingLine
                @updateDrawingLine({x:e.global.x, y:e.global.y})
            if @mode is 'rect' and @drawingRect
                @updateDrawingRect({x:e.global.x, y:e.global.y})
               
        underlay.mouseup = (e) =>
            if @sp and @ep
                if @mode is 'draw' and (not pointAreEqual(@sp, @ep))
                    @endDrawingLine()
                if @mode is 'rect' and (not pointAreEqual(@sp, @ep))
                    @endDrawingRect()

    addCornerEvents: (corner) ->
        corner.mouseover = (e) =>
            @lastOverCorner = corner
            corner.scale = x:1.5, y:1.5

        corner.mouseout = (e) =>
            corner.scale = x:1, y:1
            @lastOverCorner = undefined
            
        corner.mousedown = =>
            if @mode is 'move'
                @startDraggingCorner(corner)

            if @mode is 'draw' and (@sp is undefined)
                @startDrawingLine({x:corner.position.x, y:corner.position.y})

        corner.mousemove = (e) =>
            if @mode is 'move' and (@draggingCorner is corner)
                @updateDraggingCorner({x:e.global.x, y:e.global.y})
                    
        corner.mouseup = corner.mouseupoutside = (e) =>
            if @mode is 'move' and (@draggingCorner is corner)
                @endDraggingCorner({x:e.global.x, y:e.global.y})

            if @mode is 'draw' and @drawingLine and (@lastOverCorner is corner)
                @endDrawingLine( {x:corner.position.x, y:corner.position.y})
                           
    applyDiffs: (diffs, putInUndoStack = true) ->
        if putInUndoStack
            @undoRedo.clearRedoFuture() # kill 'back to the future alternate timeline'
            @undoRedo.constructUndoable diffs
        for diff in diffs
            if diff.type is 'wall'
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

update = ->
    requestAnimFrame update
    renderer.render stage

window.onload = ->
    update()

window.undo = ->
    if editor.undoRedo.canUndo()
        d = editor.undoRedo.undo()
        editor.applyDiffs d, false

window.redo = ->
    if editor.undoRedo.canRedo()
        d = editor.undoRedo.redo()
        editor.applyDiffs d, false

window.info = ->
    editor.undoRedo.info()

window.setDrawMode = (mode) ->
    editor.setMode(mode.id)
    
