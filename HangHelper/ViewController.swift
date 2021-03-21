//
//  ViewController.swift
//  HangHelper
//
//  Created by Cao Mai on 3/15/21.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {
    
    @IBOutlet var sceneView: ARSCNView!
    
    var nodes = [SCNNode]()
    
    var textNode = SCNNode()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        //        // Create a new scene
        //        let scene = SCNScene(named: "art.scnassets/ship.scn")!
        //
        //        // Set the scene to the view
        //        sceneView.scene = scene
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        
        // Probably don't need this
        configuration.planeDetection = .horizontal
        
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            
            let touchLocation = touch.location(in: sceneView)
            
            //            let results = sceneView.hitTest(touchLocation, types: .existingPlane)
            
            let rayResults = sceneView.raycastQuery(from: touchLocation, allowing: .existingPlaneInfinite, alignment: .horizontal)!
            
            let results = sceneView.session.raycast(rayResults)
            
            if !results.isEmpty {
                print("touched plane")
                let hitResult = (results.first!)
                addDot(at: hitResult)
            } else {
                print("touched somewhere else")
            }
        }
        
        
    }
    
    func resetRuler() {
        if nodes.count >= 2 {
            for node in nodes {
                node.removeFromParentNode()
            }
            nodes = []
            textNode.removeFromParentNode()
        }
    }
    
    func addDot(at hitResult: ARRaycastResult) {
        
        resetRuler()
        
        let dotGeo = SCNSphere(radius: 0.005)
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.red
        
        dotGeo.materials = [material]
        
        let dotNode = SCNNode(geometry: dotGeo)
        
        dotNode.position = SCNVector3(x: hitResult.worldTransform.columns.3.x, y: hitResult.worldTransform.columns.3.y, z: hitResult.worldTransform.columns.3.z)
        
        sceneView.scene.rootNode.addChildNode(dotNode)
        
        nodes.append(dotNode)
        
        if nodes.count >= 2 {
            calculate()
        }
        
    }
    
    func calculate() {
        let start = nodes[0]
        let end = nodes[1]
        
        let a = end.position.x - start.position.x
        let b = end.position.y - start.position.y
        let c = end.position.z - start.position.z
        
        let distance = sqrt(pow(a, 2) + pow(b, 2) + pow(c, 2))
        
        let stringDistance = abs(distance)
        let inches = MeterToInches(meter: stringDistance)
        addText(text: "\(inches.toFeetAndInches())", hitResult: end)
        
        let lineBetweenNode = getLineBetweenNode(node1: start, node2: end)
        
        sceneView.scene.rootNode.addChildNode(lineBetweenNode)
        
        
        let dotGeo = SCNSphere(radius: 0.005)
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.green
        
        dotGeo.materials = [material]
        
        let dotNode = SCNNode(geometry: dotGeo)
        
        dotNode.position = middlePosition(first: start.position, second: end.position)
        
        sceneView.scene.rootNode.addChildNode(dotNode)
        
        nodes.append(dotNode)
    }
    
    func getDistance() -> Float {
        let start = nodes[0]
        let end = nodes[1]
        
        let a = end.position.x - start.position.x
        let b = end.position.y - start.position.y
        let c = end.position.z - start.position.z
        
        return sqrt(pow(a, 2) + pow(b, 2) + pow(c, 2))
    }
    
    func addText(text: String, hitResult: SCNNode) {
        let textGeometry = SCNText(string: text, extrusionDepth: 1.0)
        
        textGeometry.firstMaterial?.diffuse.contents = UIColor.blue
        
        textNode = SCNNode(geometry: textGeometry)
        
        textNode.position =  SCNVector3(x: hitResult.position.x, y: hitResult.position.y + 0.1, z: hitResult.position.z)
        textNode.scale = SCNVector3(0.01, 0.01, 0.0)
        
        sceneView.scene.rootNode.addChildNode(textNode)
    }
    
//    https://stackoverflow.com/questions/35002232/draw-scenekit-object-between-two-points
    func getLineBetweenNode(node1: SCNNode, node2: SCNNode) -> SCNNode {
        let line = SCNCylinder(radius: 0.002, height: CGFloat(getDistance()))
        
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.red
        material.lightingModel = .phong
        line.materials = [material]
        
        let newLineNode = SCNNode()
        newLineNode.geometry = line
        newLineNode.position = middlePosition(first: node1.position, second: node2.position)
        
        let betweenVector = SCNVector3Make(node2.position.x - node1.position.x, node2.position.y - node1.position.y, node2.position.z - node1.position.z)
        
        // Get Y rotation in radians
        let yAngle = atan(betweenVector.x / betweenVector.z)
        
        // Rotate cylinder node about X axis so cylinder is laying down
        newLineNode.eulerAngles.x = .pi / 2
        
        // Rotate cylinder node about Y axis so cylinder is pointing to each node
        newLineNode.eulerAngles.y = yAngle
        return newLineNode
        
    }
    
    func middlePosition(first: SCNVector3, second: SCNVector3) -> SCNVector3 {
        return SCNVector3Make((first.x + second.x) / 2, (first.y + second.y) / 2, (first.z + second.z) / 2)
    }
    
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if anchor is ARPlaneAnchor {
            let planeAnchor = anchor as! ARPlaneAnchor
            
            let plane = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
            let planeNode = SCNNode()
            
            planeNode.position = SCNVector3(x: planeAnchor.center.x, y: 0, z: planeAnchor.center.z)
            planeNode.transform = SCNMatrix4MakeRotation(-Float.pi/2, 1, 0, 0)
            
            let gridMaterial = SCNMaterial()
            
            gridMaterial.diffuse.contents = UIImage(named: "art.scnassets/grid.png")
            
            plane.materials = [gridMaterial]
            
            planeNode.geometry = plane
            
            node.addChildNode(planeNode)
            
            
        } else {
            return
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    // MARK: - ARSCNViewDelegate
    
    /*
     // Override to create and configure nodes for anchors added to the view's session.
     func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
     let node = SCNNode()
     
     return node
     }
     */
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}
