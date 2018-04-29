import 'dart:html';
import 'dart:math' as math;

import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

import 'common.dart';
import 'jump_gate.dart';
import 'planet.dart';
import 'sector.dart';

part 'star.g.dart';

@JsonSerializable()
class Star extends FirebaseObject with GameObject, _$StarSerializerMixin {
  @override
  final String name;

  @override
  double x = 0.0;

  @override
  double y = 0.0;

  @override
  final double height;

  @override
  final double width;

  @override
  bool isLocked = false;

  @JsonKey(ignore: true)
  final List<Planet> planets;

  @JsonKey(ignore: true)
  final List<Sector> sectors;

  @JsonKey(ignore: true)
  final List<JumpGate> jumpGates;

  Iterable<Selectable> get selectables =>
      <Selectable>[].followedBy(planets).followedBy(jumpGates);

  @JsonKey(ignore: true)
  final selected = <Selectable>[];

  Star._(
      {@required this.height,
      @required this.width,
      @required int numLayers,
      @required String firebaseId,
      @required this.name})
      : jumpGates = <JumpGate>[],
        planets = <Planet>[],
        sectors = <Sector>[],
        super(firebaseId) {
    const letters = const ['a', 'b', 'c', 'd', 'e', 'f', 'g'];
    for (var q = -numLayers + 1; q < numLayers; q++) {
      for (var r = -numLayers + 1; r < numLayers; r++) {
        if (q + r < -(numLayers - 1)) continue;
        if (q + r > (numLayers - 1)) continue;

        var x = Sector.SIZE * 3 / 2 * q;
        var y = Sector.SIZE * math.sqrt(3) * (r + q / 2);
        var col = q + (numLayers / 2).floor() + 1;
        var row = col < numLayers ? r + col + 1 : r + numLayers;
        var sector = new Sector(
            x: x + centerX, y: y + centerY, name: '${letters[col]}$row');
        sectors.add(sector);
      }
    }
  }

  Star(
      {List<JumpGate> jumpGates,
      List<Planet> planets,
      List<Sector> sectors,
      bool isLocked,
      @required this.height,
      @required this.width,
      @required String firebaseId,
      @required this.name})
      : planets = planets ?? <Planet>[],
        sectors = sectors ?? <Sector>[],
        jumpGates = jumpGates ?? <JumpGate>[],
        isLocked = isLocked ?? false,
        super(firebaseId);

  // Create a star with [numLayers] layers of hexes making up the overall hex.
  factory Star.withLayers(int numLayers, String firebaseId, String name) {
    var totalHeight = (Sector.HEIGHT * ((numLayers - 1) * 2 + 1));
    var totalWidth = (Sector.WIDTH * ((((numLayers - 1) ~/ 2) * 2) + 1) +
        Sector.WIDTH * 0.5 * (numLayers ~/ 2) * 2);
    if (totalWidth.floor() % 2 == 0) {
      totalWidth += (2 * Sector.WIDTH * .25).floor();
    }

    return new Star._(
        numLayers: numLayers,
        height: totalHeight,
        width: totalWidth,
        firebaseId: firebaseId,
        name: name);
  }

  factory Star.fromJson(Map<String, dynamic> json) => _$StarFromJson(json);

  @override
  void draw(CanvasRenderingContext2D renderCtx, GameContext gameCtx) {
    for (var sector in sectors) {
      sector.draw(renderCtx, gameCtx);
    }
    for (var planet in planets) {
      planet.draw(renderCtx, gameCtx);
    }
    for (var jumpGate in jumpGates) {
      jumpGate.draw(renderCtx, gameCtx);
    }
    renderCtx.setStrokeColorRgb(0, 255, 0);
    renderCtx.font = '40px sans-serif';
    renderCtx.setFillColorRgb(255, 255, 255);
    var selectedObjects = selected.toList();
    if (selectedObjects.length == 1) {
      var toObjects = <GameObject>[]..addAll(planets)..addAll(jumpGates);
      for (var object in selectedObjects) {
        toObjects.remove(object);
        _drawDistances(object, toObjects, renderCtx);
      }
    } else if (selectedObjects.length > 1) {
      GameObject a = selectedObjects.removeAt(0);
      GameObject b;
      while (selectedObjects.isNotEmpty) {
        b = selectedObjects.removeAt(0);
        _drawDistance(a, b, renderCtx);
        a = b;
      }
    }
  }

  void _drawDistances(GameObject from, Iterable<GameObject> toObjects,
      CanvasRenderingContext2D renderCtx) {
    for (var to in toObjects) {
      _drawDistance(from, to, renderCtx);
    }
  }

  void _drawDistance(GameObject fromObj, GameObject toObj,
      CanvasRenderingContext2D renderCtx) {
    var from = fromObj is DockingPoint ? fromObj.dockingPoint : fromObj;
    var to = toObj is DockingPoint ? toObj.dockingPoint : toObj;
    var oldWidth = renderCtx.lineWidth;
    renderCtx.lineWidth = 4;
    renderCtx.setLineDash([8, 24]);
    renderCtx.moveTo(from.x, from.y);
    renderCtx.lineTo(to.x, to.y);
    renderCtx.stroke();
    renderCtx.setLineDash([]);
    renderCtx.lineWidth = oldWidth;

    var xDiff = from.x - to.x;
    var yDiff = from.y - to.y;
    var distance =
        math.sqrt(math.pow(xDiff.abs(), 2) + math.pow(yDiff.abs(), 2)).round();
    renderCtx.fillText('${distance}au', from.x - xDiff / 2, from.y - yDiff / 2);
    renderCtx.lineWidth = oldWidth;
  }
}
