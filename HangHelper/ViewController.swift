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
    
    let bubbleDepth: Float = 0.01
    
    var textNode = SCNNode()
    
    var middleNode = SCNNode()
    var lineBetweenNode = SCNNode()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        sceneView.autoenablesDefaultLighting = true

        
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
        configuration.planeDetection = .vertical
        
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            
            let touchLocation = touch.location(in: sceneView)
            
            //            let results = sceneView.hitTest(touchLocation, types: .existingPlane)
            
            let rayResults = sceneView.raycastQuery(from: touchLocation, allowing: .existingPlaneInfinite, alignment: .vertical)!
            
            let results = sceneView.session.raycast(rayResults)
            
            if !results.isEmpty {
                print("touched plane")
//                print(results.first?.worldTransform.columns.3.x, results.first?.worldTransform.columns.3.y, results.first?.worldTransform.columns.3.z)
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
            middleNode.removeFromParentNode()
            lineBetweenNode.removeFromParentNode()
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
        let start2 = nodes[0].clone()
        let end2 = nodes[1].clone()
        
        let start = nodes[0]
        let end = nodes[1]
        
        let distanceInMeters = distanceBetweenNodes(start: start, end: end)
        let meters = MeterToInches(meter: distanceInMeters)
        textNode = createTextNode(meters.toFeetAndInches())
        textNode.position = middlePosition(first: start.position, second: end.position)
        sceneView.scene.rootNode.addChildNode(textNode)
        
        let node = lineBetweenNodes(positionA: start.position, positionB: end.position, inScene: sceneView.scene)
            sceneView.scene.rootNode.addChildNode(node)
        
        
//        let lineBetweenNode = getLineBetweenNode(node1: start, node2: end)
//        sceneView.scene.rootNode.addChildNode(lineBetweenNode)
        
        print("Start position", start.position.x, start.position.y, start.position.z)
        print("End Positino", end.position.x, end.position.y, end.position.z)

        
        let line = SCNGeometry.line(from: start.position, to: end.position)
        
//        let newVectorStart = SCNVector3Make(start.position.x, start.position.y + 5, start.position.z)
//        let newVectorEnd = SCNVector3Make(end.position.x, end.position.y + 5, end.position.z)

        let lineNode = SCNNode(geometry: line)
        lineNode.position = SCNVector3Zero
        sceneView.scene.rootNode.addChildNode(lineNode)

        
//        for _ in 1...10 {
//            start.position.x -= 0.04
//            start.position.z += 0.008
//            end.position.x += 0.04
//            end.position.z -= 0.008
//
//        }
        
//        start.eulerAngles.x = -.pi/2
//        end.eulerAngles.x = -.pi/2

    
//        for _ in 1...20 {
//            start.position.y += 0.03
//            end.position.y += 0.03
//
//            let line = SCNGeometry.line(from: start.position, to: end.position)
//
//            let lineNode = SCNNode(geometry: line)
//            lineNode.position = SCNVector3Zero
//            sceneView.scene.rootNode.addChildNode(lineNode)
//
//        }
//
//        for _ in 1...20 {
//            start2.position.y -= 0.03
//            end2.position.y -= 0.03
//
//            let line = SCNGeometry.line(from: start2.position, to: end2.position)
//
//            let lineNode = SCNNode(geometry: line)
//            lineNode.position = SCNVector3Zero
//            sceneView.scene.rootNode.addChildNode(lineNode)
//
//        }
        
        
//        drawMiddleNode(middlePosition: middlePosition(first: start.position, second: end.position))
        
        
    }
//
//    func drawMiddleNode(middlePosition: SCNVector3) {
//        let dotGeo = SCNSphere(radius: 0.005)
//        let material = SCNMaterial()
//        material.diffuse.contents = UIColor.green
//
//        dotGeo.materials = [material]
//
//        middleNode = SCNNode(geometry: dotGeo)
//
//        middleNode.position = middlePosition
//
//        sceneView.scene.rootNode.addChildNode(middleNode)
//
//        nodes.append(middleNode)
//
//    }
    
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
        bubbleNode.pivot = SCNMatrix4MakeTranslation( (maxBound.x - minBound.x)/2, minBound.y, bubbleDepth/2)
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
    
    func distanceBetweenNodes(start: SCNNode, end: SCNNode) -> Float {
//        let start = nodes[0]
//        let end = nodes[1]
        
        let a = end.position.x - start.position.x
        let b = end.position.y - start.position.y
        let c = end.position.z - start.position.z
        
        return abs(sqrt(pow(a, 2) + pow(b, 2) + pow(c, 2)))
    }
    
    func addText(text: String, hitResult: SCNNode) {
        let textGeometry = SCNText(string: text, extrusionDepth: 1.0)
        
        textGeometry.firstMaterial?.diffuse.contents = UIColor.blue
        
        textNode = SCNNode(geometry: textGeometry)
        
        textNode.position =  SCNVector3(x: hitResult.position.x, y: hitResult.position.y + 0.1, z: hitResult.position.z)
        textNode.scale = SCNVector3(0.01, 0.01, 0.0)
        
        sceneView.scene.rootNode.addChildNode(textNode)
    }
    
//    https://gist.github.com/GrantMeStrength/62364f8a5d7ea26e2b97b37207459a10
    func lineBetweenNodes(positionA: SCNVector3, positionB: SCNVector3, inScene: SCNScene) -> SCNNode {
            let vector = SCNVector3(positionA.x - positionB.x, positionA.y - positionB.y, positionA.z - positionB.z)
            let distance = sqrt(vector.x * vector.x + vector.y * vector.y + vector.z * vector.z)
            let midPosition = SCNVector3 (x:(positionA.x + positionB.x) / 2, y:(positionA.y + positionB.y) / 2, z:(positionA.z + positionB.z) / 2)

            let lineGeometry = SCNCylinder()
            lineGeometry.radius = 0.002
            lineGeometry.height = CGFloat(distance)
            lineGeometry.radialSegmentCount = 5
            lineGeometry.firstMaterial!.diffuse.contents = UIColor.green

            let lineNode = SCNNode(geometry: lineGeometry)
            lineNode.position = midPosition
            lineNode.look(at: positionB, up: inScene.rootNode.worldUp, localFront: lineNode.worldUp)
            return lineNode
        }
    
    
////    https://stackoverflow.com/questions/35002232/draw-scenekit-object-between-two-points
//    func getLineBetweenNode(node1: SCNNode, node2: SCNNode) -> SCNNode {
//        let line = SCNCylinder(radius: 0.002, height: CGFloat(distanceBetweenNodes(start: node1, end: node2)))
//
//        let material = SCNMaterial()
//        material.diffuse.contents = UIColor.red
//        material.lightingModel = .phong
//        line.materials = [material]
//
//        lineBetweenNode.geometry = line
//        lineBetweenNode.position = middlePosition(first: node1.position, second: node2.position)
//
//        let betweenVector = SCNVector3Make(node2.position.x - node1.position.x, node2.position.y - node1.position.y, node2.position.z - node1.position.z)
//
//        // Get Y rotation in radians
//        let yAngle = atan(betweenVector.y / betweenVector.z)
//
//        // Rotate cylinder node about X axis so cylinder is laying down
//        lineBetweenNode.eulerAngles.x = .pi / 2
//
//        // Rotate cylinder node about Y axis so cylinder is pointing to each node
//        lineBetweenNode.eulerAngles.y = yAngle
//        return lineBetweenNode
//
//    }
    
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
            
//            let gridMaterial = SCNMaterial()
//
//            gridMaterial.diffuse.contents = UIImage(named: "art.scnassets/grid.png")
//
//            plane.materials = [gridMaterial]
//
//            planeNode.geometry = plane
//
//            node.addChildNode(planeNode)
            print("plane!")
            
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


extension SCNGeometry {
    class func line(from vector1: SCNVector3, to vector2: SCNVector3) -> SCNGeometry {
        let indices: [Int32] = [0, 1]
        let source = SCNGeometrySource(vertices: [vector1, vector2])
        let element = SCNGeometryElement(indices: indices, primitiveType: .line)
        return SCNGeometry(sources: [source], elements: [element])
    }
}

///looks like y is the thing that's getting smaller when you go up
//Start position -0.013950694 -0.29768142 -0.8087494
//End Positino 0.10948597 -0.29737473 -0.824081
//touched plane
//touched plane
//Start position -0.0124802925 -0.123720184 -0.80968
//End Positino 0.09759191 -0.12262655 -0.8233552
//touched plane
//touched plane
//Start position -0.015157804 -0.027880251 -0.81265146
//End Positino 0.08202456 -0.025717713 -0.8261197


//Start position -0.045311995 -0.2245927 -0.35887483
//End Positino -0.013480216 -0.21830407 -0.35993907
//touched plane
//touched plane
//Start position -0.11578967 -0.18739304 -0.35763702
//End Positino 0.096940465 -0.1807105 -0.36483467
//touched plane
//touched plane
//Start position -0.13999453 -0.022936732 -0.360219
//End Positino 0.11313399 -0.020511314 -0.3686698


//Start position -0.19611076 -0.04121199 -0.53352785
//End Positino -0.10675386 -0.042285185 -0.55700594
//touched plane
//touched plane
//Start position -0.35618916 -0.0049450807 -0.48500314
//End Positino 0.09505594 0.008563001 -0.6164749
//touched plane
//touched plane
//Start position -0.46825647 0.1032953 -0.46887752
//End Positino 0.11511024 0.13835233 -0.64191765
//touched plane
//touched plane
//Start position -0.5193834 0.23614614 -0.4532935
//End Positino 0.16265216 0.25515363 -0.6586266


//Start position -0.09637158 0.06756115 -0.5898814
//End Positino 0.1622802 0.058914587 -0.6406032
//touched plane
//touched plane
//Start position -0.3652835 0.06285457 -0.525276
//End Positino 0.5385894 0.0720004 -0.68492454


//start: x = -.27, z = +.05
//end: x = .37, z = -.04
