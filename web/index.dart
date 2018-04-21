import 'dart:html';
import 'dart:math' as math;

main() {
  var sectors = <Sector>[];
  int numLayers = 4;
  for (int q = -numLayers + 1; q < numLayers; q++) {
    for (int r = -numLayers + 1; r < numLayers; r++) {
      if (q + r < -(numLayers - 1)) continue;
      if (q + r > (numLayers - 1)) continue;

      var x = Sector.SIZE * 3 / 2 * q;
      var y = Sector.SIZE * math.sqrt(3) * (r + q / 2);
      sectors.add(new Sector(x: x, y: y));
    }
  }

  var scale = .2;
  var canvas = new CanvasElement();
  var totalHeight = (Sector.HEIGTH * ((numLayers - 1) * 2 + 1)).floor();
  var totalWidth = (Sector.WIDTH * ((((numLayers - 1) ~/ 2) * 2) + 1) +
          Sector.WIDTH * 0.5 * (numLayers ~/ 2) * 2)
      .floor();
  if (totalWidth % 2 == 0) {
    totalWidth += (2 * Sector.WIDTH * .25).floor();
  }
  var centerX = scale * totalWidth ~/ 2;
  var centerY = scale * totalHeight ~/ 2;
  canvas.style
    ..width = '${totalWidth * scale}px'
    ..height = '${totalHeight * scale}px';
  canvas.width = (totalWidth * scale).floor();
  canvas.height = (totalHeight * scale).floor();

  var context = canvas.context2D;
  context.setFillColorRgb(0, 0, 0);
  context.fillRect(0, 0, canvas.width, canvas.height);
  document.body.append(canvas);
  for (var sector in sectors) {
    sector.draw(context, centerX, centerY, scale);
  }
}

class Position {
  double x;
  double y;

  Position({this.x, this.y});
}

class Size {
  double width;
  double height;
}

class Sector extends Object implements Position, Size {
  static final HEIGTH = WIDTH * math.sqrt(3)/2;
  static final WIDTH = SIZE * 2;
  static final SIZE = 300.0;

  @override
  double x;

  @override
  double y;

  @override
  double width = WIDTH;

  @override
  double height = WIDTH * 0.75;

  void draw(CanvasRenderingContext2D ctx, centerX, centerY, scale) {
    Position hexCorner(int i) {
      var deg = 60 * i;
      var rad = math.pi / 180 * deg;
      var position = new Position(
          x: x + SIZE * math.cos(rad), y: y + SIZE * math.sin(rad));
      return new Position(
          x: position.x * scale + centerX, y: position.y * scale + centerY);
    }

    ctx.setStrokeColorRgb(255, 255, 255);
    ctx.beginPath();
    var start = hexCorner(5);
    ctx.moveTo(start.x, start.y);
    for (var point = 0; point < 6; point++) {
      var position = hexCorner(point);
      ctx.lineTo(position.x, position.y);
    }
    ctx.stroke();
  }

  Sector({
    double x,
    double y,
  }) {
    this.x = x;
    this.y = y;
    this.width = width;
    this.height = height;
  }
}
