;(function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);throw new Error("Cannot find module '"+o+"'")}var f=n[o]={exports:{}};t[o][0].call(f.exports,function(e){var n=t[o][1][e];return s(n?n:e)},f,f.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){
var Floorplan, addWallSimply, anyIsEqual, anyWallEqual, findIntersection, getLengthAndRotation, orderIntersections, pointsAreEqual, subdivideExistingWall, subdivideNewWall, wallsAreEqual, _ref;

_ref = require('./math'), getLengthAndRotation = _ref.getLengthAndRotation, findIntersection = _ref.findIntersection, orderIntersections = _ref.orderIntersections;

wallsAreEqual = function(wall1, wall2) {
  if (wall1.a.x === wall2.a.x && wall1.a.y === wall2.a.y) {
    if (wall1.b.x === wall2.b.x && wall1.b.y === wall2.b.y) {
      return true;
    }
  }
  if (wall1.a.x === wall2.b.x && wall1.a.y === wall2.b.y) {
    if (wall1.b.x === wall2.a.x && wall1.b.y === wall2.a.y) {
      return true;
    }
  }
  return false;
};

anyWallEqual = function(collection, w) {
  var wall, _i, _len;
  for (_i = 0, _len = collection.length; _i < _len; _i++) {
    wall = collection[_i];
    if (wallsAreEqual(wall, w)) {
      return true;
    }
  }
  return false;
};

pointsAreEqual = function(p1, p2) {
  return p1.x === p2.x && p1.y === p2.y;
};

anyIsEqual = function(collection, p) {
  var c, _i, _len;
  for (_i = 0, _len = collection.length; _i < _len; _i++) {
    c = collection[_i];
    if (pointsAreEqual(c, p)) {
      return true;
    }
  }
  return false;
};

module.exports = Floorplan = (function() {
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
        subdivideExistingWall(intersection, w, diff, this.walls);
      }
    }
    if (intersections.length === 0) {
      addWallSimply(wall, diff, this.walls);
    } else {
      orderIntersections(wall, intersections);
      intersections.unshift(wall.a);
      intersections.push(wall.b);
      subdivideNewWall(intersections, diff, this.walls);
    }
    return diff;
  };

  return Floorplan;

})();

addWallSimply = function(wall, diff, walls) {
  console.log('simple');
  return diff.push({
    operation: 'add',
    type: 'wall',
    obj: wall
  });
};

subdivideExistingWall = function(intersection, wall, diff, walls) {
  var part1, part2;
  console.log('subdivide old');
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

subdivideNewWall = function(intersections, diff, walls) {
  var i, part, s, _i, _len, _results;
  console.log('subdivide new');
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


},{"./math":3}],2:[function(require,module,exports){
var Corner, CornerDict, Editor, Floorplan, UndoRedo, editor, getLengthAndRotation, getOther, isInArray, pointAreEqual, removeItemFrom, renderer, roundAllValues, stage, updateUICounter,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

Floorplan = require('./floorplan');

getLengthAndRotation = require('./math').getLengthAndRotation;

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

isInArray = function(array, item) {
  return (array.indexOf(item)) !== -1;
};

getOther = function(test, pair) {
  var i, v, _i, _len;
  for (i = _i = 0, _len = pair.length; _i < _len; i = ++_i) {
    v = pair[i];
    if (v.x !== test.x || v.y !== test.y) {
      return {
        value: v,
        index: i
      };
    }
  }
};

roundAllValues = function(p) {
  p.a.x = parseInt(p.a.x);
  p.a.y = parseInt(p.a.y);
  p.b.x = parseInt(p.b.x);
  p.b.y = parseInt(p.b.y);
  return p;
};

pointAreEqual = function(p1, p2) {
  return p1.x === p2.x && p1.y === p2.y;
};

CornerDict = (function() {
  function CornerDict() {
    this.data = {};
  }

  CornerDict.prototype.createCorner = function(x, y) {
    var corner, newlyMade;
    corner = this.data["" + x + "_" + y];
    if (corner !== void 0) {
      return corner;
    }
    newlyMade = new Corner(x, y);
    this.data["" + x + "_" + y] = newlyMade;
    return newlyMade;
  };

  CornerDict.prototype.remove = function(c) {
    return delete this.data["" + c.x + "_" + c.y];
  };

  CornerDict.prototype.all = function() {
    var k, _ref, _results;
    _ref = this.data;
    _results = [];
    for (k in _ref) {
      if (!__hasProp.call(_ref, k)) continue;
      _results.push(this.data[k]);
    }
    return _results;
  };

  return CornerDict;

})();

Corner = (function(_super) {
  __extends(Corner, _super);

  function Corner(x, y) {
    var graphics;
    Corner.__super__.constructor.call(this);
    graphics = new PIXI.Graphics();
    graphics.beginFill(0xffffff, 0.9);
    graphics.drawCircle(0, 0, 10, 10);
    this.addChild(graphics);
    this.pivot = {
      x: 0,
      y: 0
    };
    this.position = {
      x: x,
      y: y
    };
    this.interactive = true;
    this.walls = [];
    this.visible = true;
  }

  return Corner;

})(PIXI.DisplayObjectContainer);

Editor = (function(_super) {
  __extends(Editor, _super);

  function Editor() {
    Editor.__super__.constructor.call(this);
    this.underlay = new PIXI.Graphics();
    this.underlay.hitArea = new PIXI.Rectangle(0, 0, 800, 600);
    this.underlay.interactive = true;
    this.addChild(this.underlay);
    this.tempGraphics = new PIXI.Graphics();
    this.addUnderlayEvents(this.underlay);
    this.floorplan = new Floorplan();
    this.walls = [];
    this.wallLayer = new PIXI.DisplayObjectContainer();
    this.addChild(this.wallLayer);
    this.cornerLayer = new PIXI.DisplayObjectContainer();
    this.addChild(this.cornerLayer);
    this.addChild(this.tempGraphics);
    this.undoRedo = new UndoRedo();
    this.drawMode = void 0;
    this.corners = new CornerDict();
  }

  Editor.prototype.setDrawMode = function(mode) {
    return this.drawMode = mode;
  };

  Editor.prototype.addUnderlayEvents = function(underlay) {
    underlay.mousedown = (function(_this) {
      return function(e) {
        if (_this.drawMode === 'draw') {
          _this.dragging = true;
          return _this.sp = {
            x: e.global.x,
            y: e.global.y
          };
        }
      };
    })(this);
    underlay.mousemove = (function(_this) {
      return function(e) {
        if (_this.drawMode === 'draw') {
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
        }
      };
    })(this);
    return underlay.mouseup = (function(_this) {
      return function(e) {
        if (_this.drawMode === 'draw') {
          if ((_this.sp && _this.ep) && (!pointAreEqual(_this.sp, _this.ep))) {
            _this.dragging = false;
            _this.tempGraphics.clear();
            _this.applyDiffs(_this.floorplan.addWall({
              a: _this.sp,
              b: _this.ep
            }));
            _this.sp = void 0;
            _this.ep = void 0;
            return renderer.render(stage);
          }
        }
      };
    })(this);
  };

  Editor.prototype.addCornerEvents = function(corner) {
    this.usingCorner = void 0;
    corner.mousedown = (function(_this) {
      return function() {
        var wall, _i, _len, _ref, _results;
        if (_this.drawMode === 'move') {
          _this.usingCorner = corner;
          _this.usingCorner.alpha = 0.1;
          _ref = _this.usingCorner.walls;
          _results = [];
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            wall = _ref[_i];
            _results.push(wall.alpha = 0.1);
          }
          return _results;
        }
      };
    })(this);
    corner.mouseup = corner.mouseupoutside = (function(_this) {
      return function(e) {
        var a, b, diffs, wall, _i, _len, _ref;
        if (_this.drawMode === 'move') {
          if (_this.usingCorner && (_this.usingCorner === corner)) {
            _this.usingCorner.alpha = 1;
            diffs = [];
            _ref = _this.usingCorner.walls;
            for (_i = 0, _len = _ref.length; _i < _len; _i++) {
              wall = _ref[_i];
              diffs.push({
                operation: 'remove',
                type: 'wall',
                obj: wall.ref
              });
              a = {
                x: e.global.x,
                y: e.global.y
              };
              b = getOther(_this.usingCorner.position, [wall.ref.a, wall.ref.b]).value;
              diffs.push({
                operation: 'add',
                type: 'wall',
                obj: {
                  a: a,
                  b: b
                }
              });
            }
            _this.usingCorner = void 0;
            _this.tempGraphics.clear();
            _this.applyDiffs(diffs);
            return renderer.render(stage);
          }
        }
      };
    })(this);
    return corner.mousemove = (function(_this) {
      return function(e) {
        var p, wall, _i, _len, _ref;
        if (_this.drawMode === 'move') {
          if (_this.usingCorner && (_this.usingCorner === corner)) {
            _this.tempGraphics.clear();
            _this.tempGraphics.beginFill(0xff0000);
            _this.tempGraphics.drawCircle(e.global.x, e.global.y, 10, 10);
            _ref = _this.usingCorner.walls;
            for (_i = 0, _len = _ref.length; _i < _len; _i++) {
              wall = _ref[_i];
              _this.tempGraphics.lineStyle(10, 0xffff00);
              _this.tempGraphics.moveTo(e.global.x, e.global.y);
              p = getOther(_this.usingCorner.position, [wall.ref.a, wall.ref.b]).value;
              _this.tempGraphics.lineTo(p.x, p.y);
            }
            return renderer.render(stage);
          }
        }
      };
    })(this);
  };

  Editor.prototype.applyDiffs = function(diffs, putInUndoStack) {
    var c, corner1, corner2, diff, length, rotation, w, wall, wallToDelete, _i, _j, _k, _len, _len1, _len2, _ref, _ref1, _ref2;
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
          diff.obj = roundAllValues(diff.obj);
          wall = new PIXI.Graphics();
          wall.beginFill(0xffffff * Math.random());
          _ref = getLengthAndRotation(diff.obj.a, diff.obj.b), length = _ref.length, rotation = _ref.rotation;
          wall.drawRect(0, -4, length, 8);
          wall.position = diff.obj.a;
          wall.rotation = rotation;
          wall.ref = diff.obj;
          this.walls.push(wall);
          corner1 = this.corners.createCorner(diff.obj.a.x, diff.obj.a.y);
          this.cornerLayer.addChild(corner1);
          this.addCornerEvents(corner1);
          corner1.walls.push(wall);
          corner2 = this.corners.createCorner(diff.obj.b.x, diff.obj.b.y);
          this.cornerLayer.addChild(corner2);
          this.addCornerEvents(corner2);
          corner2.walls.push(wall);
          this.wallLayer.addChild(wall);
          this.floorplan.walls.push(diff.obj);
        }
        if (diff.operation === 'remove') {
          wallToDelete = void 0;
          _ref1 = this.walls;
          for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
            w = _ref1[_j];
            if (w.ref === diff.obj) {
              wallToDelete = w;
              continue;
            }
          }
          if (wallToDelete !== void 0) {
            this.wallLayer.removeChild(wallToDelete);
            removeItemFrom(this.walls, wallToDelete);
            removeItemFrom(this.floorplan.walls, wallToDelete.ref);
            _ref2 = this.corners.all();
            for (_k = 0, _len2 = _ref2.length; _k < _len2; _k++) {
              c = _ref2[_k];
              removeItemFrom(c.walls, wallToDelete);
              if (c.walls.length === 0) {
                this.corners.remove(c);
                this.cornerLayer.removeChild(c);
              }
            }
          }
        }
      }
    }
    return updateUICounter(this.walls.length, this.corners.all().length);
  };

  return Editor;

})(PIXI.DisplayObjectContainer);

updateUICounter = function(amount, amount2) {
  return document.getElementById('counter').innerHTML = '# walls: ' + amount + " corners length: " + amount2;
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

window.setDrawMode = function(mode) {
  return editor.setDrawMode(mode.id);
};


},{"./floorplan":1,"./math":3,"./undoredo":4}],3:[function(require,module,exports){
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


},{}],4:[function(require,module,exports){
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


},{}]},{},[2])
;