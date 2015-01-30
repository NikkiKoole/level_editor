;(function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);throw new Error("Cannot find module '"+o+"'")}var f=n[o]={exports:{}};t[o][0].call(f.exports,function(e){var n=t[o][1][e];return s(n?n:e)},f,f.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){
var Editor, Floorplan, UndoRedo, addWallSimply, editor, findIntersection, getLengthAndRotation, orderIntersections, removeItemFrom, renderer, stage, subdivideExistingWall, subdivideNewWall, updateUICounter, _ref,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

_ref = require('./math'), getLengthAndRotation = _ref.getLengthAndRotation, findIntersection = _ref.findIntersection, orderIntersections = _ref.orderIntersections;

UndoRedo = require('./undoredo');

stage = null;

renderer = null;

removeItemFrom = function(array, item) {
  var index;
  index = array.indexOf(item);
  if (index > -1) {
    return array.splice(index, 1);
  }
};

Floorplan = (function() {
  function Floorplan() {
    this.walls = [];
  }

  Floorplan.prototype.addWall = function(wall) {
    var diff, intersection, intersections, w, _i, _len, _ref1;
    diff = [];
    intersections = [];
    _ref1 = this.walls;
    for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
      w = _ref1[_i];
      intersection = findIntersection(wall.a, wall.b, w.a, w.b);
      if (intersection !== void 0) {
        intersections.push(intersection);
        subdivideExistingWall(intersection, w, diff);
      }
    }
    if (intersections.length === 0) {
      addWallSimply(wall, diff);
    } else {
      orderIntersections(wall, intersections);
      intersections.unshift(wall.a);
      intersections.push(wall.b);
      subdivideNewWall(intersections, diff);
    }
    return diff;
  };

  return Floorplan;

})();

addWallSimply = function(wall, diff) {
  return diff.push({
    operation: 'add',
    type: 'wall',
    obj: wall
  });
};

subdivideExistingWall = function(intersection, wall, diff) {
  var part1, part2;
  diff.push({
    operation: 'remove',
    type: 'wall',
    obj: wall
  });
  part1 = {
    a: wall.a,
    b: intersection
  };
  diff.push({
    operation: 'add',
    type: 'wall',
    obj: part1
  });
  part2 = {
    a: wall.b,
    b: intersection
  };
  diff.push({
    operation: 'add',
    type: 'wall',
    obj: part2
  });
  return diff;
};

subdivideNewWall = function(intersections, diff) {
  var i, part, s, _i, _len, _results;
  _results = [];
  for (i = _i = 0, _len = intersections.length; _i < _len; i = ++_i) {
    s = intersections[i];
    if (i >= intersections.length - 1) {
      continue;
    }
    part = {
      a: s,
      b: intersections[i + 1]
    };
    _results.push(diff.push({
      operation: 'add',
      type: 'wall',
      obj: part
    }));
  }
  return _results;
};

Editor = (function(_super) {
  __extends(Editor, _super);

  function Editor() {
    Editor.__super__.constructor.call(this);
    this.underlay = new PIXI.Graphics();
    this.underlay.hitArea = new PIXI.Rectangle(0, 0, 800, 600);
    this.underlay.interactive = true;
    this.addChild(this.underlay);
    this.tempGraphics = new PIXI.Graphics();
    this.addChild(this.tempGraphics);
    this.addUnderlayEvents(this.underlay);
    this.floorplan = new Floorplan();
    this.walls = [];
    this.undoRedo = new UndoRedo();
  }

  Editor.prototype.addUnderlayEvents = function(underlay) {
    underlay.mousedown = (function(_this) {
      return function(e) {
        _this.dragging = true;
        return _this.sp = {
          x: e.global.x,
          y: e.global.y
        };
      };
    })(this);
    underlay.mousemove = (function(_this) {
      return function(e) {
        if (_this.dragging) {
          _this.ep = {
            x: e.global.x,
            y: e.global.y
          };
          _this.tempGraphics.clear();
          _this.tempGraphics.lineStyle(10, 0xaa00aa);
          _this.tempGraphics.moveTo(_this.sp.x, _this.sp.y);
          _this.tempGraphics.lineTo(_this.ep.x, _this.ep.y);
          return renderer.render(stage);
        }
      };
    })(this);
    return underlay.mouseup = (function(_this) {
      return function(e) {
        _this.dragging = false;
        _this.tempGraphics.clear();
        _this.applyDiffs(_this.floorplan.addWall({
          a: _this.sp,
          b: _this.ep
        }));
        return renderer.render(stage);
      };
    })(this);
  };

  Editor.prototype.applyDiffs = function(diffs, putInUndoStack) {
    var diff, length, rotation, w, wall, wallToDelete, _i, _j, _len, _len1, _ref1, _ref2;
    if (putInUndoStack == null) {
      putInUndoStack = true;
    }
    if (putInUndoStack) {
      this.undoRedo.clearRedoFuture();
      this.undoRedo.constructUndoable(diffs);
    }
    for (_i = 0, _len = diffs.length; _i < _len; _i++) {
      diff = diffs[_i];
      if (diff.type === 'wall') {
        if (diff.operation === 'add') {
          wall = new PIXI.Graphics();
          wall.beginFill(0xffffff * Math.random());
          _ref1 = getLengthAndRotation(diff.obj.a, diff.obj.b), length = _ref1.length, rotation = _ref1.rotation;
          wall.drawRect(0, -5, length, 10);
          wall.position.x = diff.obj.a.x;
          wall.position.y = diff.obj.a.y;
          wall.rotation = rotation;
          wall.ref = diff.obj;
          this.addChild(wall);
          this.walls.push(wall);
          this.floorplan.walls.push(diff.obj);
        }
        if (diff.operation === 'remove') {
          wallToDelete = void 0;
          _ref2 = this.walls;
          for (_j = 0, _len1 = _ref2.length; _j < _len1; _j++) {
            w = _ref2[_j];
            if (w.ref === diff.obj) {
              wallToDelete = w;
              continue;
            }
          }
          this.removeChild(wallToDelete);
          removeItemFrom(this.walls, wallToDelete);
          removeItemFrom(this.floorplan.walls, wallToDelete.ref);
        }
      }
    }
    return updateUICounter(this.walls.length);
  };

  return Editor;

})(PIXI.DisplayObjectContainer);

updateUICounter = function(amount) {
  return document.getElementById('counter').innerHTML = '# walls: ' + amount;
};

stage = new PIXI.Stage(0x888888);

renderer = new PIXI.autoDetectRenderer();

editor = new Editor();

stage.addChild(editor);

document.body.appendChild(renderer.view);

window.onload = function() {
  return renderer.render(stage);
};

window.undo = function() {
  var d;
  if (editor.undoRedo.canUndo()) {
    d = editor.undoRedo.undo();
    editor.applyDiffs(d, false);
    return renderer.render(stage);
  }
};

window.redo = function() {
  var d;
  if (editor.undoRedo.canRedo()) {
    d = editor.undoRedo.redo();
    editor.applyDiffs(d, false);
    return renderer.render(stage);
  }
};

window.info = function() {
  return editor.undoRedo.info();
};


},{"./math":2,"./undoredo":3}],2:[function(require,module,exports){
var getLengthAndRotation;

module.exports.getLengthAndRotation = getLengthAndRotation = function(sp, ep) {
  return {
    middle: {
      x: (sp.x + ep.x) / 2,
      y: (sp.y + ep.y) / 2
    },
    length: Math.sqrt((sp.x - ep.x) * (sp.x - ep.x) + (sp.y - ep.y) * (sp.y - ep.y)),
    rotation: Math.atan2(ep.y - sp.y, ep.x - sp.x)
  };
};

module.exports.orderIntersections = function(line, intersections) {
  var compare, distanceTo;
  distanceTo = function(a, b) {
    return getLengthAndRotation(a, b).length;
  };
  compare = function(a, b) {
    if (distanceTo(a, line.a) < distanceTo(b, line.a)) {
      return -1;
    }
    if (distanceTo(a, line.a) > distanceTo(b, line.a)) {
      return 1;
    }
    return 0;
  };
  return intersections.sort(compare);
};

module.exports.findIntersection = function(a, b, a1, b1) {
  var denom, denomPositive, dx, dx1, dxa, dy, dy1, dya, intersection, s, t;
  dx = b.x - a.x;
  dy = b.y - a.y;
  dx1 = b1.x - a1.x;
  dy1 = b1.y - a1.y;
  denom = dx * dy1 - dx1 * dy;
  if (denom === 0) {
    return void 0;
  }
  denomPositive = denom > 0;
  dxa = a.x - a1.x;
  dya = a.y - a1.y;
  s = dx * dya - dy * dxa;
  if ((s < 0) === denomPositive) {
    return void 0;
  }
  t = dx1 * dya - dy1 * dxa;
  if ((t < 0) === denomPositive) {
    return void 0;
  }
  if ((s > denom) === denomPositive || (t > denom) === denomPositive) {
    return void 0;
  }
  t = t / denom;
  return intersection = {
    x: a.x + (t * dx),
    y: a.y + (t * dy)
  };
};


},{}],3:[function(require,module,exports){
var UndoRedo;

module.exports = UndoRedo = (function() {
  function UndoRedo() {
    this.undoStack = [];
    this.redoStack = [];
  }

  UndoRedo.prototype.constructUndoable = function(diffArray) {
    this.undoStack.push(this._negateAll(diffArray));
    return diffArray;
  };

  UndoRedo.prototype.constructRedoable = function(diffArray) {
    this.redoStack.push(this._negateAll(diffArray));
    return diffArray;
  };

  UndoRedo.prototype._negateAll = function(array) {
    var diff, negated, state, _i, _len;
    state = [];
    for (_i = 0, _len = array.length; _i < _len; _i++) {
      diff = array[_i];
      negated = this._negateDiff(diff);
      state.push(negated);
    }
    return state;
  };

  UndoRedo.prototype._negateDiff = function(diff) {
    var negatedDiff;
    negatedDiff = {};
    if (diff.operation === 'add') {
      negatedDiff.operation = 'remove';
    } else if (diff.operation === 'remove') {
      negatedDiff.operation = 'add';
    }
    negatedDiff.type = diff.type;
    negatedDiff.obj = diff.obj;
    return negatedDiff;
  };

  UndoRedo.prototype.info = function() {
    console.log('undo length: ', this.undoStack.length);
    console.log('redo length: ', this.redoStack.length);
    return console.log(JSON.stringify(this.undoStack));
  };

  UndoRedo.prototype.clearRedoFuture = function() {
    return this.redoStack = [];
  };

  UndoRedo.prototype.canUndo = function() {
    return this.undoStack.length > 0;
  };

  UndoRedo.prototype.canRedo = function() {
    return this.redoStack.length > 0;
  };

  UndoRedo.prototype.undo = function() {
    return this.constructRedoable(this.undoStack.pop());
  };

  UndoRedo.prototype.redo = function() {
    return this.constructUndoable(this.redoStack.pop());
  };

  return UndoRedo;

})();


},{}]},{},[1])
;