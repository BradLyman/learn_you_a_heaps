import h2d.Scene.ScaleMode;
import h2d.Scene.ScaleModeAlign;

class Main extends hxd.App {
  /**
    Graphics is used for immediate-mode 2d rendering.
  **/
  var graphics:h2d.Graphics;

  /**
    The number of line segments used for approximate the circle.
  **/
  var circleSegments:Int = 8;

  /**
    The circle's radius.
  **/
  var radius:Float = 400.0;

  override function init() {
    graphics = new h2d.Graphics(s2d);
    hxd.Window.getInstance().addEventTarget(onEvent);
    new support.h2d.FullscreenButton(s2d);
  }

  /**
    Move the updating logic into the event handler.
  **/
  function onEvent(event:hxd.Event) {
    switch (event.kind) {
      case EPush:
        graphics.clear();
      case EMove:
        updateCircleValues(event.relX, event.relY);
        drawCircle();
      default:
        // do nothing, we don't care about other events
    }
  }

  private function updateCircleValues(x:Float, y:Float) {
    // normalize mouse coordinates
    final normalized = {
      x: x / s2d.width,
      y: y / s2d.height
    };

    // center the y coordinate so it's 0 at the middle of the screen and
    // 1.0 at the far left or right edge
    final centered = Math.abs((normalized.y - 0.5) * 2.0);

    // update the radius by mapping from the centered y coordinate to the
    // range [10, s2d.height/2]
    final scale = (s2d.height / 2) - 10.0;
    radius = 10.0 + centered * scale;

    // update the number of circle segments by mapping from the normalized
    // X coordinate to the range [3, 15]
    circleSegments = 3 + Math.floor(normalized.x * 12);
  }

  private function drawCircle() {
    final segments = [
      for (i in 0...circleSegments) {
        final normalized_index = i / circleSegments;
        final angle = normalized_index * (Math.PI * 2.0);

        final next_normalized_index = (i + 1) / circleSegments;
        final next_angle = next_normalized_index * (Math.PI * 2.0);

        {
          start: {
            x: Math.cos(angle) * radius,
            y: Math.sin(angle) * radius
          },
          end: {
            x: Math.cos(next_angle) * radius,
            y: Math.sin(next_angle) * radius
          }
        }
      }
    ];

    final center = {
      x: s2d.width / 2,
      y: s2d.height / 2
    };

    graphics.lineStyle(1.0, colorFor(Math.PI), 0.4);
    for (segment in segments) {
      graphics.moveTo(segment.start.x + center.x, segment.start.y + center.y);
      graphics.lineTo(segment.end.x + center.x, segment.end.y + center.y);
    }
  }

  private function colorFor(
    hue:Float,
    saturation:Float = 0.8,
    lightness:Float = 0.5
  ):Int {
    final vec = new h3d.Vector();
    vec.makeColor(hue, saturation, lightness);
    return vec.toColor();
  }

  static function main() {
    new Main();
  }
}
