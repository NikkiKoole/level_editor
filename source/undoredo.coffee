module.exports = class UndoRedo
    constructor: ->
        @undoStack = []
        @redoStack = []

    constructUndoable: (diffArray) ->
        @undoStack.push @_negateAll(diffArray)
        diffArray
        
    constructRedoable: (diffArray) ->
        @redoStack.push @_negateAll(diffArray)
        diffArray
         
    _negateAll: (array) ->
        state = []
        for diff in array
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

    info: ->
        console.log 'undo length: ',@undoStack.length
        console.log 'redo length: ',@redoStack.length
        console.log JSON.stringify(@undoStack)

    clearRedoFuture: ->
        @redoStack = []

    canUndo: ->
        @undoStack.length > 0
    canRedo: ->
        @redoStack.length > 0
    undo: ->
        @constructRedoable @undoStack.pop()
    redo: ->
        @constructUndoable @redoStack.pop()
