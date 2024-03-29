import UIKit
import ARKit

class CanvasViewController: UIViewController {

  // A view that enables you to display an AR experience with SceneKit.
  @IBOutlet weak var sceneView: ARSCNView!
  @IBOutlet weak var paintButton: UIButton!

  var brushSettings: BrushSettings!

  // When we start the augmented reality (AR) session, we need to specify an AR configuration to use.
  // ARWorldTrackingConfiguration is the full-fidelity configuration
  // that uses the rear camera to:
  // - tracks the device’s position + orientation (its tilt around the 3 axises + real-world flat surfaces
  private let configuration = ARWorldTrackingConfiguration()
  private let paintNodeCursorState: (name: String , colour: UIColor) = ("cursor", .lightGray)

  private var userIsPressingPaintButton: Bool {
    return paintButton.isHighlighted
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }

  // MARK: - View Lifecycle
  override func viewDidLoad() {
    super.viewDidLoad()
    setupSceneView()

    let customTabBarController = self.tabBarController as! CustomTabBarController
    brushSettings = customTabBarController.brushSettings
  }

  // MARK: - Private Helpers
  private func eraseNodes(named nameToErase: String) {
    self.sceneView.scene.rootNode.enumerateChildNodes { (node, _) in
      if node.name == nameToErase {
        node.removeFromParentNode()
      }
    }
  }

  // Create a node based on the current brush settings
  // and the camera’s current position.
  private func makePaintNode(brushShape: BrushSettings.Shape,
                             brushSize: CGFloat,
                             position: SCNVector3) -> SCNNode {
    let minSize: CGFloat = 0.02
    let maxSize: CGFloat = 0.5
    let shapeSize = minSize + brushSize * (minSize + maxSize)

    let paintNode: SCNNode!

    switch brushShape {
    case .box:
      paintNode = SCNNode(geometry: SCNBox(width: shapeSize,
                                           height: shapeSize,
                                           length: shapeSize,
                                           chamferRadius: 0))
    case .capsule:
      paintNode = SCNNode(geometry: SCNCapsule(capRadius: shapeSize / 8,
                                               height: shapeSize))
      paintNode.eulerAngles = SCNVector3(0, 0, Double.pi / 2)
    case .cone:
      paintNode = SCNNode(geometry: SCNCone(topRadius: 0,
                                            bottomRadius: shapeSize / 8,
                                            height: shapeSize))
      paintNode.eulerAngles = SCNVector3(0, 0, Double.pi / 2)
    case .cylinder:
      paintNode = SCNNode(geometry: SCNCylinder(radius: shapeSize / 8,
                                                height: shapeSize))
      paintNode.eulerAngles = SCNVector3(0, 0, Double.pi / 2)
    case .pyramid:
      paintNode = SCNNode(geometry: SCNPyramid(width: shapeSize,
                                               height: shapeSize,
                                               length: shapeSize))
    case .sphere:
      paintNode = SCNNode(geometry: SCNSphere(radius: shapeSize / 2))
    case .torus:
      paintNode = SCNNode(geometry: SCNTorus(ringRadius: shapeSize / 2,
                                             pipeRadius: shapeSize / 8))
      paintNode.eulerAngles = SCNVector3(Double.pi / 2, 0, 0)
    case .tube:
      paintNode = SCNNode(geometry: SCNTube(innerRadius: shapeSize / 10,
                                            outerRadius: shapeSize / 8,
                                            height: shapeSize))
      paintNode.eulerAngles = SCNVector3(0, 0, Double.pi / 2)
    }

    paintNode.position = position

    return paintNode
  }

  private func paintNode(at position: SCNVector3) {
    let paintNode = makePaintNode(brushShape: brushSettings.shape,
                                       brushSize: brushSettings.size,
                                       position: position)

    if userIsPressingPaintButton {
      paintNode.geometry?.firstMaterial?.diffuse.contents = brushSettings.color
      paintNode.geometry?.firstMaterial?.specular.contents = UIColor.white

      if brushSettings.isSpinning {
        spin(node: paintNode)
      }

    } else {
      paintNode.geometry?.firstMaterial?.diffuse.contents = paintNodeCursorState.colour
      paintNode.name = paintNodeCursorState.name
    }

    sceneView.scene.rootNode.addChildNode(paintNode)
  }

  private func spin(node: SCNNode) {
    let rotateAction = SCNAction.rotate(by: 2 * .pi,
                                        around: SCNVector3(0, 1, 0),
                                        duration: 3)
    let rotateForeverAction = SCNAction.repeatForever(rotateAction)
    node.runAction(rotateForeverAction)
  }
  
  // Node's position = Sum of (a) where it is and (b) which way it is facing
  private func getNodePosition(fromTransform transform: SCNMatrix4) -> SCNVector3 {

    // The location is in the 4th column of the transform matrix.
    let nodeLocation = SCNVector3(transform.m41,
                                  transform.m42,
                                  transform.m43)

    // The orientation is in the 3rd column of the transform matrix.
    let nodeOrientation = SCNVector3(-transform.m31,
                                       -transform.m32,
                                       -transform.m33)

    let nodePosition = nodeOrientation + nodeLocation
    return nodePosition
  }

  private func setupSceneView() {
    sceneView.delegate = self
    sceneView.debugOptions = [ARSCNDebugOptions.showWorldOrigin,
                              ARSCNDebugOptions.showFeaturePoints]
    sceneView.showsStatistics = true

    // Turns on a virtual omnidirectional light source located
    // at the same location as the device.
    sceneView.autoenablesDefaultLighting = true

    // Starts the AR session.
    sceneView.session.run(configuration)
  }
}

// MARK: - ARSCNViewDelegate methods
extension CanvasViewController: ARSCNViewDelegate {

  // Called just before the ARSCNView is about to draw the next frame (ideally, at least 60 times a second).
  func renderer(_ renderer: SCNSceneRenderer, willRenderScene scene: SCNScene, atTime time: TimeInterval) {
    guard let cameraNode = sceneView.pointOfView else { return }

    let cameraPosition = self.getNodePosition(fromTransform: cameraNode.transform)

    DispatchQueue.main.async {
      // reset: erase old cursor nodes
      self.eraseNodes(named: self.paintNodeCursorState.name)
      self.paintNode(at: cameraPosition)
    }
  }
}

func +(left: SCNVector3, right: SCNVector3) -> SCNVector3 {
  return SCNVector3(left.x + right.x,
                    left.y + right.y,
                    left.z + right.z)
}
