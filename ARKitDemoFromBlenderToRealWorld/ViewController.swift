//
//  ViewController.swift
//  ARKitDemoPlacing3DModel
//
//  Created by Florian on 27/07/2018.
//  Copyright © 2018 Florian. All rights reserved.
//

import UIKit
import ARKit

class ViewController: UIViewController {
    
    @IBOutlet weak var sceneView: ARSCNView!
    
    var i = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addTapGestureToSceneView()
        
        configureLighting()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setUpSceneView()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    func setUpSceneView() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        
        sceneView.session.run(configuration)
        
        sceneView.delegate = self
        //sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
    }
    
    func configureLighting() {
        sceneView.autoenablesDefaultLighting = true
        //sceneView.automaticallyUpdatesLighting = true
    }
    
    @objc func addShipToSceneView(withGestureRecognizer recognizer: UIGestureRecognizer) {
        let tapLocation = recognizer.location(in: sceneView)
        
        // Using automatically detected planes
        let hitTestResults = sceneView.hitTest(tapLocation, types: .existingPlaneUsingExtent)
        // Using automatically detected feature points
        //let hitTestResults = sceneView.hitTest(tapLocation, types: .featurePoint)
        
        
        guard let hitTestResult = hitTestResults.first else { return }
        let translation = hitTestResult.worldTransform.translation
        let x = translation.x
        let y = translation.y + 0.1
        let z = translation.z
        
        func random(_ range:Range<Int>) -> Int
        {
            return range.lowerBound + Int(arc4random_uniform(UInt32(range.upperBound - range.lowerBound)))
        }
        

        var modelString = ""
        
        switch random(0..<3) {
        case 1:
            modelString = "stairs"
        case 2:
            modelString = "tube"
        case 3:
            modelString = "spiral"
        default:
            modelString = "spiral"
        }
        
        guard let shipScene = SCNScene(named: "models.scn"),
            let shipNode = shipScene.rootNode.childNode(withName: modelString, recursively: false)
            else { return }
        
        i = !i
        
        var actionRotate = SCNAction.rotateBy(x: 1.25, y: 0, z: 1.5, duration: 8)
            actionRotate = SCNAction.repeatForever(actionRotate)
        
        var actionMoveUp = SCNAction.moveBy(x: 0, y: 0, z: 0, duration: 8)
            actionMoveUp = SCNAction.repeatForever(actionMoveUp)
        
        let action = SCNAction.group([actionRotate, actionMoveUp])
        
            shipNode.runAction(action)
        
        func generateRandomColor() -> UIColor {
            
            // use 256 to get full range from 0.0 to 1.0
            let hue : CGFloat = CGFloat(arc4random() % 256) / 256
            // from 0.5 to 1.0 to stay away from white
            let saturation : CGFloat = CGFloat(arc4random() % 128) / 256 + 0
            // from 0.5 to 1.0 to stay away from black
            let brightness : CGFloat = CGFloat(arc4random() % 128) / 256 + 0.5
            
            return UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: 1)
        }
        
        shipNode.geometry?.materials.first?.lightingModel = .blinn
        shipNode.geometry?.materials.first?.shininess = 0.5
        //shipNode.geometry?.materials.first?.reflective.contents = generateRandomColor()
        shipNode.geometry?.materials.first?.diffuse.contents = generateRandomColor()
        shipNode.geometry?.materials.first?.selfIllumination.contents = UIColor.white
        
        shipNode.position = SCNVector3(x,y,z)
        sceneView.scene.rootNode.addChildNode(shipNode)
    }
    
    func addTapGestureToSceneView() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ViewController.addShipToSceneView(withGestureRecognizer:)))
        sceneView.addGestureRecognizer(tapGestureRecognizer)
    }
}

extension float4x4 {
    var translation: float3 {
        let translation = self.columns.3
        return float3(translation.x, translation.y, translation.z)
    }
}

extension UIColor {
    open class var transparentLightBlue: UIColor {
        return UIColor(red: 90/255, green: 200/255, blue: 250/255, alpha: 0.50)
    }
}

extension ViewController: ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        // 1
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        // 2
        let width = CGFloat(planeAnchor.extent.x)
        let height = CGFloat(planeAnchor.extent.z)
        let plane = SCNPlane(width: width, height: height)
        
        // 3
        plane.materials.first?.diffuse.contents = UIColor.transparentLightBlue.withAlphaComponent(0)
        
        // 4
        let planeNode = SCNNode(geometry: plane)
        
        // 5
        let x = CGFloat(planeAnchor.center.x)
        let y = CGFloat(planeAnchor.center.y)
        let z = CGFloat(planeAnchor.center.z)
        planeNode.position = SCNVector3(x,y,z)
        planeNode.eulerAngles.x = -.pi / 2
        
        // 6
        node.addChildNode(planeNode)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        // 1
        guard let planeAnchor = anchor as?  ARPlaneAnchor,
            let planeNode = node.childNodes.first,
            let plane = planeNode.geometry as? SCNPlane
            else { return }
        
        // 2
        let width = CGFloat(planeAnchor.extent.x)
        let height = CGFloat(planeAnchor.extent.z)
        plane.width = width
        plane.height = height
        
        // 3
        let x = CGFloat(planeAnchor.center.x)
        let y = CGFloat(planeAnchor.center.y)
        let z = CGFloat(planeAnchor.center.z)
        planeNode.position = SCNVector3(x, y, z)
    }
}
