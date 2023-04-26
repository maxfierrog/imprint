import java.util.Random;
import java.util.concurrent.TimeUnit;
import com.vividsolutions.jts.geom.Coordinate;
import com.vividsolutions.jts.geom.GeometryFactory;
import com.vividsolutions.jts.triangulate.DelaunayTriangulationBuilder;
import com.vividsolutions.jts.triangulate.quadedge.QuadEdge;
import com.vividsolutions.jts.triangulate.quadedge.QuadEdgeSubdivision;

/** Portrait filename (in /data directory). */
final String portraitfile = "max.jpg";
final int imageWidth = 1000;
final int imageHeight = 1000;

/** Array containing the valid points. */ 
boolean[] nodes;

/** Array of brightness values of each of the pixels in the original image. */
float[] originalPixels;

/** Called once when the program starts. */
void setup () {
  size(1000, 1000);
  image(loadImage(portraitfile), 0, 0);
  loadPixels();
  originalPixels = new float[imageWidth * imageHeight];
  for (int i = 0; i < pixels.length; i++) {
    originalPixels[i] = brightness(pixels[i]);
  }
  noLoop();
}

/** Called directy after setup(). Loops by default. */
void draw() {
  loadPixels();
  
  float[] boundaries =       { 20.0,    80.0,  120.0,  160.0,  220.0, 256.0 };
  float[] probabilities =    { 0.0001,  0.001, 0.01,   0.1,    0.2,   0.6   };
  
  stratify(boundaries, probabilities);
  colorByEdge(30.0, 7, 0.3);
  
  Point[] nodes = whitePixelsIntoPoints(0.07);
  Edge[] edges = compute(nodes);
  
  Point p1, p2;
  for (int i = 0; i < edges.length; i++) {
    p1 = edges[i].getP1();
    p2 = edges[i].getP2();
    System.out.println(p1);
    line((float) p1.getX(), (float) p1.getY(), (float) p2.getX(), (float) p2.getY());
  }
  
  updatePixels();
}

/* FROM PIXELS TO GRAPH */

Point[] whitePixelsIntoPoints(float withProbability) {
  ArrayList<Point> points = new ArrayList();
  Random r = new Random();
  for (int i = 0; i < pixels.length; i++) {
    if ((brightness(pixels[i]) > 254) && (r.nextFloat() < withProbability)) {
      points.add(new Point(i % imageWidth, i / imageWidth));
    }
  }
  Point[] result = new Point[points.size()];
  for (int j = 0; j < points.size(); j++) {
    result[j] = points.get(j);
  }
  return result;
}

public class Point {
    private double x;
    private double y;

    public Point(double x, double y) {
        this.x = x;
        this.y = y;
    }

    public double getX() {
        return x;
    }

    public double getY() {
        return y;
    }
}

class Edge {
    private Point p1;
    private Point p2;

    public Edge(Point p1, Point p2) {
        this.p1 = p1;
        this.p2 = p2;
    }

    public Point getP1() {
        return p1;
    }

    public Point getP2() {
        return p2;
    }
}

/* I really disliked having to do this. */
Edge[] compute(Point[] points) {
    // convert the Point array to a Coordinate array
    Coordinate[] coords = new Coordinate[points.length];
    for (int i = 0; i < points.length; i++) {
        coords[i] = new Coordinate(points[i].getX(), points[i].getY());
    }

    // create a JTS DelaunayTriangulationBuilder
    GeometryFactory geomFactory = new GeometryFactory();
    DelaunayTriangulationBuilder builder = new DelaunayTriangulationBuilder();
    builder.setSites(geomFactory.createMultiPoint(coords));
    QuadEdgeSubdivision subdiv = builder.getSubdivision();

    // get the QuadEdge array representing the edges of the triangulation
    ArrayList<QuadEdge> quadEdges = new ArrayList<>(subdiv.getEdges());
    // convert the QuadEdge array to an Edge array
    int numEdges = quadEdges.size() / 2;
    Edge[] edges = new Edge[numEdges];
    for (int i = 0; i < numEdges; i++) {
        Coordinate p1 = quadEdges.get(i * 2).orig().getCoordinate();
        Coordinate p2 = quadEdges.get(i * 2).dest().getCoordinate();
        edges[i] = new Edge(new Point(p1.x, p1.y), new Point(p2.x, p2.y));
    }
    return edges;
}

/* FROM IMAGE TO PIXELS */

void stratify(float[] boundaries, float[] probabilities) {
  float previous = 0.0;
  for (int i = 0; i < boundaries.length; i ++) {
    colorByStrata(previous, boundaries[i], probabilities[i]);
    previous = boundaries[i];
  }
}

/** Activates for pixels with brightnesses in the range of FROM to TO, and colors them
WITHPROBABILITY chance. */
void colorByStrata(float from, float to, float withProbability) {
  float current;
  Random r = new Random();
  for (int i = 0; i < originalPixels.length; i++) {
    current = originalPixels[i];
    if (current >= from && current < to) {
      if (r.nextFloat() < withProbability) {
        
        pixels[i] = color(255, 255, 255);
        
      }
    }
  }
}

/** Activates if any of the pixels DETECTIONTHRESHOLD away in all four cardinal directions
are more than DETECTIONDISTANCE different than the pixel in question. */
void colorByEdge(float detectionThreshold, int detectionDistance, float withProbability) {
  float current;
  boolean up, down, left, right;
  Random r = new Random();
  for (int i = 0; i < originalPixels.length; i++) {
    current = originalPixels[i];
    
    // Check left
    if ((i % imageWidth) > detectionDistance) {
      left = abs(originalPixels[i - detectionDistance] - current) > detectionThreshold;
    } else {
      left = false;
    }
    
    // Check right
    if (i < (originalPixels.length - detectionDistance)) {
      right = abs(originalPixels[i + detectionDistance] - current) > detectionThreshold;
    } else {
      right = false;
    }
    
    // Check top
    if (i > (detectionDistance * imageWidth)) {
      up = abs(originalPixels[i - (detectionDistance * imageWidth)] - current) > detectionThreshold;
    } else {
      up = false;
    }
    
    // Check bottom
    if (((imageWidth * detectionDistance) + i) < originalPixels.length) {
      down = abs(originalPixels[i + (detectionDistance * imageWidth)] - current) > detectionThreshold;
    } else {
      down = false;
    }
    
    // If any of them check out, perform the change
    if ((up || right) && (r.nextFloat() < withProbability)) {
      
      pixels[i] = color(255, 255, 255);
      
    }
  }
}
