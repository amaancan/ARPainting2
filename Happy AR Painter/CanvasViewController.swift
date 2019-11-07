import UIKit
import ARKit

class CanvasViewController: UIViewController {

  // A view that enables you to display an AR experience with SceneKit.
  @IBOutlet weak var sceneView: ARSCNView!
  @IBOutlet weak var paintButton: UIButton!

  internal var brushSettings: BrushSettings!

  // When we start the augmented reality (AR) session, we need to specify an AR configuration to use.
  // ARWorldTrackingConfiguration is the full-fidelity configuration
  // that uses the rear camera and does the following:
  //
  // - Tracks the device’s position + orientation (its tilt around the 3 axises + real-world flat surfaces
  let configuration = ARWorldTrackingConfiguration()

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    setupSceneView()

    let customTabBarController = self.tabBarController as! CustomTabBarController
    brushSettings = customTabBarController.brushSettings
  }

  // MARK: - Node creation methods
  func eraseNodes(named nameToErase: String) {
    self.sceneView.scene.rootNode.enumerateChildNodes { (node, _) in
      if node.name == nameToErase {
        node.removeFromParentNode()
      }
    }
  }

  // Create a node based on the current brush settings
  // and the camera’s current position.
  func createBrush(brushShape: BrushSettings.Shape,
                   brushSize: CGFloat,
                   position: SCNVector3) -> SCNNode {
    let minSize: CGFloat = 0.02
    let maxSize: CGFloat = 0.5
    let shapeSize = minSize + brushSize * (minSize + maxSize)

    let brush: SCNNode!

    switch brushShape {
    case .box:
      brush = SCNNode(geometry: SCNBox(width: shapeSize,
                                       height: shapeSize,
                                       length: shapeSize,
                                       chamferRadius: 0))
    case .capsule:
      brush = SCNNode(geometry: SCNCapsule(capRadius: shapeSize / 8,
                                           height: shapeSize))
      brush.eulerAngles = SCNVector3(0, 0, Double.pi / 2)
    case .cone:
      brush = SCNNode(geometry: SCNCone(topRadius: 0,
                                        bottomRadius: shapeSize / 8,
                                        height: shapeSize))
      brush.eulerAngles = SCNVector3(0, 0, Double.pi / 2)
    case .cylinder:
      brush = SCNNode(geometry: SCNCylinder(radius: shapeSize / 8,
                                            height: shapeSize))
      brush.eulerAngles = SCNVector3(0, 0, Double.pi / 2)
    case .pyramid:
      brush = SCNNode(geometry: SCNPyramid(width: shapeSize,
                                           height: shapeSize,
                                           length: shapeSize))
    case .sphere:
      brush = SCNNode(geometry: SCNSphere(radius: shapeSize / 2))
    case .torus:
      brush = SCNNode(geometry: SCNTorus(ringRadius: shapeSize / 2,
                                         pipeRadius: shapeSize / 8))
      brush.eulerAngles = SCNVector3(Double.pi / 2, 0, 0)
    case .tube:
      brush = SCNNode(geometry: SCNTube(innerRadius: shapeSize / 10,
                                        outerRadius: shapeSize / 8,
                                        height: shapeSize))
      brush.eulerAngles = SCNVector3(0, 0, Double.pi / 2)
    }

    brush.position = position
    return brush
  }

  // MARK: - Helpers
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

  // Called every time the augmented reality scene is about to be rendered (ideally, at least 60 times a second).
  func renderer(_ renderer: SCNSceneRenderer, willRenderScene scene: SCNScene, atTime time: TimeInterval) {
    guard let cameraNode = sceneView.pointOfView else { return }

    let transform = cameraNode.transform

    // The orientation is in the 3rd column of the transform matrix.
    let orientation = SCNVector3(-transform.m31,
                                 -transform.m32,
                                 -transform.m33)

    // The location is in the 4th column of the transform matrix.
    let location = SCNVector3(transform.m41,
                              transform.m42,
                              transform.m43)
    let position = orientation + location
    print("location: \(location)\norientation: \(orientation)")

    // removing nodes from the scene
    // and checking the state of the “Paint” button
    DispatchQueue.main.async {

      if self.paintButton.isHighlighted {

        if self.brushSettings.isSpinning {

        }
      } else {

      }

    }
  }
}

func +(left: SCNVector3, right: SCNVector3) -> SCNVector3 {
  return SCNVector3(left.x + right.x,
                    left.y + right.y,
                    left.z + right.z)
}
