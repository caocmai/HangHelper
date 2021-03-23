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
    
    let planeDetectLabel = UILabel()
    var rulerNodes = [SCNNode]()
    let bubbleDepth: Float = 0.01
    
    let planeNode = SCNNode()
    var isPlaneDetected = false

    var gridNodes = [SCNNode]()
    var gridMode = false
    var dotCount = 0
    
    @IBOutlet weak var clearButton: UIButton!
    @IBOutlet weak var gridButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.addPlaneDetectedLabel(text: "Please Wait, Detecting Plane...")
        
        self.sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        sceneView.autoenablesDefaultLighting = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        
        // Detecting vertical plane
        configuration.planeDetection = .vertical
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    
    @IBAction func clearButton(_ sender: UIButton) {
        // IF WANT TO REDO
        //        if rulerNodes.count > 0 {
        //            let poppedNode = rulerNodes.popLast()
        //            poppedNode?.removeFromParentNode()
        //        }
        if rulerNodes.count > 0 {
            for node in rulerNodes {
                node.removeFromParentNode()
            }
        }
        // Delete all the nodes from grid, not enabled for now
        //        if gridNodes.count > 0 {
        //            for node in gridNodes {
        //                node.removeFromParentNode()
        //            }
        //        }
    }
    
    @IBAction func gridButtonTapped(_ sender: Any) {
        if !gridMode {
            gridButton.setTitle("Grid: On", for: .normal)
            gridMode = true
        } else {
            gridButton.setTitle("Ruler: On", for: .normal)
            gridMode = false
        }
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            
            let touchLocation = touch.location(in: sceneView)
            
            //            let results = sceneView.hitTest(touchLocation, types: .existingPlane)
            
            let rayResults = sceneView.raycastQuery(from: touchLocation, allowing: .existingPlaneInfinite, alignment: .vertical)!
            let results = sceneView.session.raycast(rayResults)
            
            if !results.isEmpty {
                if let hitResult = results.first {
                    if !gridMode {
                        addDotForRuler(at: hitResult)
                    } else {
                        addDotForGrid(at: hitResult)
                    }
                    planeNode.removeFromParentNode()
                }
            } else {
                print("touched somewhere else")
            }
        }
    }
    
    func resetRuler() {
        if rulerNodes.count >= 2 {
            for node in rulerNodes {
                node.removeFromParentNode()
            }
            rulerNodes = []
        }
    }
    
    func createDot(position: ARRaycastResult) -> SCNNode {
        let dotGeo = SCNSphere(radius: 0.005)
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.red
        
        dotGeo.materials = [material]
        
        let dotNode = SCNNode(geometry: dotGeo)
        dotNode.position = SCNVector3(x: position.worldTransform.columns.3.x, y: position.worldTransform.columns.3.y, z: position.worldTransform.columns.3.z)
        return dotNode
    }
    
    func addDotForRuler(at hitResult: ARRaycastResult) {
        
        dotCount += 1
        let dot = createDot(position: hitResult)
        sceneView.scene.rootNode.addChildNode(dot)
        rulerNodes.append(dot)
        
        if rulerNodes.count >= 2 && dotCount == 2{
            calculateDistance(start: rulerNodes[rulerNodes.count-1], end: rulerNodes[rulerNodes.count-2])
            dotCount = 0
        }
    }
    
    func addDotForGrid(at position: ARRaycastResult) {
        if gridNodes.count >= 3 {
            resetGrid()
        }
        let dot = createDot(position: position)
        sceneView.scene.rootNode.addChildNode(dot)
        gridNodes.append(dot)
        
        if gridNodes.count == 2 {
            generateGrid(start: gridNodes[0], end: gridNodes[1])
        }
    }
    
    func resetGrid() {
        for node in gridNodes {
            node.removeFromParentNode()
        }
        gridNodes = []
    }
    
    func generateGrid(start: SCNNode, end: SCNNode) {
        let startVerticle = start.clone()
        let endVerticle = end.clone()
        startVerticle.position.x = end.position.y
        startVerticle.position.y = start.position.x
        endVerticle.position.x = start.position.y
        endVerticle.position.y = end.position.x
        
        let node = lineBetweenNodes(positionA: start.position, positionB: end.position, inScene: sceneView.scene, lengthMultiple: 10)
        gridNodes.append(node)
        sceneView.scene.rootNode.addChildNode(node)
        
        // Horizontal lines from position to the top
        for _ in 1...20 {
            start.position.y += 0.03
            end.position.y += 0.03
            
            let node = lineBetweenNodes(positionA: start.position, positionB: end.position, inScene: sceneView.scene, lengthMultiple: 10)
            gridNodes.append(node)
            sceneView.scene.rootNode.addChildNode(node)
            
        }
        
        // Resetting the node's position back to original
        start.position.y -= (0.03 * 19)
        end.position.y -= (0.03 * 19)
        
        // Horizontal lines from position to the bottom
        for _ in 1...20 {
            start.position.y -= 0.03
            end.position.y -= 0.03
            
            let node = lineBetweenNodes(positionA: start.position, positionB: end.position, inScene: sceneView.scene, lengthMultiple: 10)
            gridNodes.append(node)
            sceneView.scene.rootNode.addChildNode(node)
            
        }
        
        // Vertical lines from position to the right
        for _ in 1...30 {
            startVerticle.position.x += 0.03
            endVerticle.position.x += 0.03

            let node = lineBetweenNodes(positionA: startVerticle.position, positionB: endVerticle.position, inScene: sceneView.scene, lengthMultiple: 10)
            gridNodes.append(node)
            sceneView.scene.rootNode.addChildNode(node)

        }
        
        // Reset nodes' positions to original positions
        startVerticle.position.x -= (0.03 * 29)
        endVerticle.position.x -= (0.03 * 29)
        
        // Vertical lines from position to the left
        for _ in 1...20 {
            startVerticle.position.x -= 0.03
            endVerticle.position.x -= 0.03

            let node = lineBetweenNodes(positionA: startVerticle.position, positionB: endVerticle.position, inScene: sceneView.scene, lengthMultiple: 10)
            gridNodes.append(node)
            sceneView.scene.rootNode.addChildNode(node)

        }
        
    }
    
    func calculateDistance(start: SCNNode, end: SCNNode) {
        print("Start position", start.position.x, start.position.y, start.position.z)
        print("End Positiionn", end.position.x, end.position.y, end.position.z)
        
        let distanceInMeters = distanceBetweenNodes(startPosition: start.position, endPosition: end.position)
        let meters = MeterToInches(meter: distanceInMeters)
        let textNode = createTextNode(meters.toFeetAndInches())
        textNode.position = middlePosition(first: start.position, second: end.position)
        rulerNodes.append(textNode)
        sceneView.scene.rootNode.addChildNode(textNode)
        
        let lineBetweenNode = lineBetweenNodes(positionA: start.position, positionB: end.position, inScene: sceneView.scene)
        rulerNodes.append(lineBetweenNode)
        sceneView.scene.rootNode.addChildNode(lineBetweenNode)
    }
    
    
    func createTextNode(_ text : String) -> SCNNode {
        let billboardConstraint = SCNBillboardConstraint()
        billboardConstraint.freeAxes = SCNBillboardAxis.Y
        
        // Bubble text
        let bubble = SCNText(string: text, extrusionDepth: CGFloat(bubbleDepth))
        let font = UIFont(name: "Futura", size: 0.15)
        //        font = font?.withTraits(traits: .traitBold)
        bubble.font = font
        bubble.alignmentMode = CATextLayerAlignmentMode.center.rawValue
        bubble.firstMaterial?.diffuse.contents = UIColor.orange
        //        bubble.firstMaterial?.specular.contents = UIColor.white
        bubble.firstMaterial?.isDoubleSided = true
        bubble.chamferRadius = CGFloat(bubbleDepth)
        
        // Bubble node
        let (minBound, maxBound) = bubble.boundingBox
        let bubbleNode = SCNNode(geometry: bubble)
        // Centre Node - to Centre-Bottom point
        bubbleNode.pivot = SCNMatrix4MakeTranslation( (maxBound.x - minBound.x)/2, minBound.y - 0.05, bubbleDepth/2)
        // Reduce default text size
        bubbleNode.scale = SCNVector3Make(0.2, 0.2, 0.2)
        
        // Center point node
        let sphere = SCNSphere(radius: 0.005)
        sphere.firstMaterial?.diffuse.contents = UIColor.cyan
        let sphereNode = SCNNode(geometry: sphere)
        
        // Bubble parent node
        let bubbleNodeParent = SCNNode()
        bubbleNodeParent.addChildNode(bubbleNode)
        bubbleNodeParent.addChildNode(sphereNode)
        bubbleNodeParent.constraints = [billboardConstraint]
        
        return bubbleNodeParent
    }
    
    func distanceBetweenNodes(startPosition: SCNVector3, endPosition: SCNVector3) -> Float {
        
        let a = endPosition.x - startPosition.x
        let b = endPosition.y - startPosition.y
        let c = endPosition.z - startPosition.z
        
        return abs(sqrt(pow(a, 2) + pow(b, 2) + pow(c, 2)))
    }
    
   
    //    https://gist.github.com/GrantMeStrength/62364f8a5d7ea26e2b97b37207459a10
    func lineBetweenNodes(positionA: SCNVector3, positionB: SCNVector3, inScene: SCNScene, lengthMultiple: Float=1.00) -> SCNNode {
//        let vector = SCNVector3(positionA.x - positionB.x, positionA.y - positionB.y, positionA.z - positionB.z)
//        let distance = sqrt(vector.x * vector.x + vector.y * vector.y + vector.z * vector.z)
        let distance = distanceBetweenNodes(startPosition: positionA, endPosition: positionB)
//        let midPosition = SCNVector3 (x:(positionA.x + positionB.x) / 2, y:(positionA.y + positionB.y) / 2, z:(positionA.z + positionB.z) / 2)
        let midPosition = middlePosition(first: positionA, second: positionB)
        
        let lineGeometry = SCNCylinder()
        
        if gridMode {
            lineGeometry.radius = 0.0005
            lineGeometry.firstMaterial!.diffuse.contents = UIColor.red
        } else {
            lineGeometry.radius = 0.002
            lineGeometry.firstMaterial!.diffuse.contents = UIColor.green
        }
        
        lineGeometry.height = CGFloat(distance*lengthMultiple)
        lineGeometry.radialSegmentCount = 5
        
        let lineNode = SCNNode(geometry: lineGeometry)
        lineNode.position = midPosition
        lineNode.look(at: positionB, up: inScene.rootNode.worldUp, localFront: lineNode.worldUp)
        return lineNode
    }
   
    
    func middlePosition(first: SCNVector3, second: SCNVector3) -> SCNVector3 {
        return SCNVector3Make((first.x + second.x) / 2, (first.y + second.y) / 2, (first.z + second.z) / 2)
    }
    
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if anchor is ARPlaneAnchor && !isPlaneDetected{
            
            let planeAnchor = anchor as! ARPlaneAnchor
            
            let plane = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
            
            planeNode.position = SCNVector3(x: planeAnchor.center.x, y: 0, z: planeAnchor.center.z)
            planeNode.transform = SCNMatrix4MakeRotation(-Float.pi/2, 1, 0, 0)
            
            let gridMaterial = SCNMaterial()
            gridMaterial.diffuse.contents = UIImage(named: "art.scnassets/grid.png")
            plane.materials = [gridMaterial]
            planeNode.geometry = plane

            node.addChildNode(planeNode)
            isPlaneDetected = true // to restrict detecting plane only once
            DispatchQueue.main.async {
                self.planeDetectLabel.text = "Plane Detected!"
                self.planeDetectLabel.textColor = .green
            }
        } else {
            return
        }
    }
    
    func addPlaneDetectedLabel(text: String) {
        self.view.addSubview(planeDetectLabel)
        planeDetectLabel.translatesAutoresizingMaskIntoConstraints = false
        planeDetectLabel.text = text
        
        NSLayoutConstraint.activate([
            planeDetectLabel.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 10),
            planeDetectLabel.centerXAnchor.constraint(equalTo: self.view.centerXAnchor)
        ])
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
