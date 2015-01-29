Graph = require './graph'

stage = null
renderer = null          

getLengthAndRotation = (sp, ep) ->
    middle: {x:(sp.x+ep.x) / 2, y:(sp.y+ep.y) / 2} # middle not needed anymore
    length: Math.sqrt((sp.x-ep.x) * (sp.x-ep.x) + (sp.y-ep.y) * (sp.y-ep.y))
    rotation: Math.atan2(ep.y-sp.y, ep.x-sp.x)

findIntersection = (a, b, a1, b1) ->
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


removeItemFrom = (array, item) ->
    index = array.indexOf item
    if index > -1
        array.splice(index, 1)
      

class Floorplan
    constructor: ->
        @walls = []

    addWall: (wall) ->
        diff = []
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


class UndoStack
    constructor: ->
        # will keep two containers.
        @stack = []
        @redoStack = []
        
    constructUndoable: (diffArray) ->
        # given an array of diffs, this baby should create a way of undoing that.
        # in a sense it's just a matter of negating each diff.
        state = []
        for diff in diffArray
            negated = @_negateDiff(diff)
            state.push negated
        @stack.push state
        
    constructRedoable: (diffArray) ->
        state = []
        for diff in diffArray
            negated = @_negateDiff(diff)
            state.push negated
        @redoStack.push state  
    _negateAll: (array) ->
        state = []
        for diff in diffArray
            negated = @_negateDiff(diff)
            state.push negated
        state
    _negateDiff: (diff) ->
        negatedDiff = {}
        if diff.operation is 'add'
            negatedDiff.operation = 'remove'
        else if diff.operation is 'remove'
            negatedDiff.operation = 'add'
        negatedDiff.type = diff.type
        negatedDiff.obj = diff.obj
        negatedDiff

    undo: ->
        u = @stack.pop()
        @constructRedoable u
        console.log 'undo length: ',@stack.length
        console.log 'redo length: ',@redoStack.length
        u
        
    redo: ->
        u = @redoStack.pop()
        @constructUndoable u
        console.log 'undo length: ',@stack.length
        console.log 'redo length: ',@redoStack.length                
        u
                              
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
        @undoStack = new UndoStack()
        
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
            @applyDiff(@floorplan.addWall({a:@sp, b:@ep}))
            renderer.render stage

    applyDiff: (diffs, putInUndoStack = true) ->
        if putInUndoStack
            @undoStack.constructUndoable diffs
        for diff in diffs
            if diff.operation is 'add'
                if diff.type is 'wall'
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
                if diff.type is 'wall'
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




#floorplan.addWall({a:a, b:b})

window.onload = ->
    renderer.render stage
window.undo = ->
    #console.log 'stack length: ', editor.undoStack.stack.length
    #d = editor.undoStack.stack.pop()
    d = editor.undoStack.undo()
    editor.applyDiff d, false
    renderer.render stage

window.redo = ->
    d = editor.undoStack.redo()
    editor.applyDiff d, false
    renderer.render stage
