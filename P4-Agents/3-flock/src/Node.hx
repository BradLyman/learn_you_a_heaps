import support.linAlg2d.Interval;
import support.turtle.Turtle;
import support.linAlg2d.Vec;
import support.color.HSL;

using support.turtle.VecTurtle;

interface NodeIndex {
  public function iterator():Iterator<Node>;
  public function insert(node:Node):Void;
  public function nearestNeighbors(node:Node, distance:Float):Array<Node>;
}

class BruteForce implements NodeIndex {
  private var nodes:Array<Node> = [];

  public function new() {}

  public function iterator():Iterator<Node> {
    return nodes.iterator();
  }

  public function insert(node:Node) {
    nodes.push(node);
    if (nodes.length > 250) {
      nodes.remove(nodes[0]);
    }
  }

  public function nearestNeighbors(node:Node, distance:Float):Array<Node> {
    final sq = distance * distance;
    final result:Array<Node> = [];
    for (other in nodes) {
      if (other == node) {
        continue;
      }

      final d = (node.pos - other.pos).sqrLen();
      if (d <= sq) {
        result.push(other);
      }
    }
    return result;
  };
}

/**
  A Node is a kinematic point mass with a position, velocity, and
  acceleration.
**/
class Node {
  public static var MAX_VEL:Float = 500;
  public static var MAX_ACC:Float = 500;
  public static var X_BOUND:Interval = new Interval(-500, 500);
  public static var Y_BOUND:Interval = new Interval(-500, 500);

  public var pos:Vec = [0, 0];
  public var vel:Vec = [0, 0];
  public var acc:Vec = [0, 0];

  public inline function new() {};

  /**
    Compute the node's position via the velocity and acceleration, assuming
    both are constant for the duration of dt.

    Acceleration resets to zero after each integration.
  **/
  public function integrate(dt:Float) {
    acc.limit(MAX_ACC);
    vel.limit(MAX_VEL);

    vel += acc * dt;
    pos += vel * dt;
    acc *= 0.0;

    pos.x = X_BOUND.clamp(pos.x);
    pos.y = Y_BOUND.clamp(pos.y);
  }

  /**
    Seek away from the screen's boundaries.
  **/
  public function bounds() {
    if (pos.x <= X_BOUND.lerp(0.05)) {
      seek([X_BOUND.end, pos.y], MAX_VEL);
    } else if (pos.x >= X_BOUND.lerp(0.95)) {
      seek([X_BOUND.start, pos.y], MAX_VEL);
    }

    if (pos.y <= Y_BOUND.lerp(0.05)) {
      seek([pos.x, Y_BOUND.end], MAX_VEL);
    } else if (pos.y >= Y_BOUND.lerp(0.95)) {
      seek([pos.x, Y_BOUND.start], MAX_VEL);
    }
  }

  public function align(friends:Array<Node>, rate:Float = 200) {
    var avg:Vec = [0, 0];
    for (friend in friends) {
      avg += friend.vel;
    }
    if (friends.length > 0) {
      avg.scale(1.0 / friends.length);
    }
    acc += avg.norm().scale(rate);
  }

  public function avoid(
    friends:Array<Node>,
    rate:Float = 200,
    dist:Float = 50
  ) {
    for (friend in friends) {
      final diff = (friend.pos - pos);
      final sqrdist = diff.sqrLen();
      if (sqrdist > dist * dist) {
        continue;
      }

      final len = Math.sqrt(sqrdist);

      final desired = diff * (-1 / len) * (dist / len) * rate;
      final steerForce = desired - vel;
      acc += steerForce;
    }
  }

  /**
    Add to the node's acceleration vector to cause the node to move towards
    the provided point.
  **/
  public function seek(p:Vec, rate:Float = 200, slowRadius:Float = 200) {
    var idealVel = p - pos;
    final ratio = idealVel.len() / slowRadius;
    idealVel.norm();
    if (ratio < 1.0) {
      idealVel.scale(ratio * rate);
    } else {
      idealVel.scale(rate);
    }
    final steerForce = (idealVel - vel);
    acc += steerForce;
  }

  /* Use the provided turtle to render the node as triangle. */
  public function draw(turtle:Turtle, width:Float = 1) {
    final look:Vec = (vel.sqrLen() < 0.01) ? [0, 1] : vel.clone().norm();
    final lookRight = look.clone().rot90();

    final right = pos + lookRight * width * 0.5;
    final left = pos - lookRight * width * 0.5;
    final center = pos + look * width * 2;

    turtle.moveToVec(left)
      .lineToVec(right)
      .lineToVec(center)
      .lineToVec(left)
      .lineToVec(right);
  }

  public function drawDebug(turtle:Turtle, scale:Float = 1) {
    final ogColor = turtle.color;

    turtle.color = new HSL(240, 1, 0.5, 1);
    turtle.lineWidth = 4;
    turtle.moveToVec(pos).lineToVec(pos + vel);

    turtle.color = new HSL(0, 1, 0.5, 1);
    turtle.lineWidth = 2;
    turtle.moveToVec(pos).lineToVec(pos + acc);

    turtle.color = ogColor;
  }
}
