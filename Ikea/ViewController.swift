//
//  ViewController.swift
//  Ikea
//
//  Created by Livia Vasconcelos on 02/01/20.
//  Copyright © 2020 Livia Vasconcelos. All rights reserved.
//

import UIKit
import ARKit

class ViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, ARSCNViewDelegate {

    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var itemsCollectionView: UICollectionView!
    @IBOutlet weak var planeDetectedLabel: UILabel!
    
    let configuration = ARWorldTrackingConfiguration()
    
    let itemsArray: [String] = ["Cup", "Vase", "Boxing", "Table"]
    var selectedItem: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.debugOptions = [SCNDebugOptions.showWorldOrigin,
                                  SCNDebugOptions.showFeaturePoints]
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration)
        sceneView.delegate = self
        
        self.itemsCollectionView.dataSource = self
        self.itemsCollectionView.delegate   = self
        
        self.registerGestureRecognizer()
        self.sceneView.autoenablesDefaultLighting = true
    }
    
    func registerGestureRecognizer() {
        let tap       = UITapGestureRecognizer(target: self, action: #selector(tapped))
        let pinch     = UIPinchGestureRecognizer(target: self, action: #selector(pinched))
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(rotate))
        
        longPress.minimumPressDuration = 0.1
        sceneView.addGestureRecognizer(tap)
        sceneView.addGestureRecognizer(pinch)
        sceneView.addGestureRecognizer(longPress)
    }
    
    @objc func tapped(sender: UITapGestureRecognizer) {
        let sceneView   = sender.view as? ARSCNView
        let tapLocation = sender.location(in: sceneView)
        let hitTest     = sceneView?.hitTest(tapLocation, types: .existingPlaneUsingExtent)
        
        if !(hitTest?.isEmpty ?? true){
            self.addItem(hitTestResult: (hitTest?.first!)!)
        }
    }
    
    @objc func pinched(sender: UIPinchGestureRecognizer) {
        let sceneView     = sender.view as? ARSCNView
        let pinchLocation = sender.location(in: sceneView)
        let hitTest       = sceneView?.hitTest(pinchLocation)
        
        if !(hitTest?.isEmpty ?? true) {
            let results     = hitTest?.first!
            let node        = results?.node
            let pinchAction = SCNAction.scale(by: sender.scale, duration: 0)
            
            node?.runAction(pinchAction)
            sender.scale = 1.0
        }
    }
    
    @objc func rotate(sender: UILongPressGestureRecognizer) {
        let sceneView         = sender.view as? ARSCNView
        let longPressLocation = sender.location(in: sceneView)
        let hitTest           = sceneView?.hitTest(longPressLocation)
        
        if !(hitTest?.isEmpty ?? true) {
            let results = hitTest?.first
            
            if sender.state == .began {
                let action  = SCNAction.rotateBy(x: 0, y: CGFloat(360.degreesToRadians), z: 0, duration: 1)
                let forever = SCNAction.repeatForever(action)
                
                results?.node.runAction(forever)
            } else if sender.state == .ended {
                results?.node.removeAllActions()
            }
        }
    
    }
    
    func addItem(hitTestResult: ARHitTestResult) {
        if let selectedItem = self.selectedItem {
            let scene       = SCNScene(named: "Models.scnassets/\(selectedItem).scn")
            let node        = scene?.rootNode.childNode(withName: selectedItem, recursively: false)
            let transform   = hitTestResult.worldTransform
            let thirdColumn = transform.columns.3
            
            node?.position = SCNVector3(thirdColumn.x, thirdColumn.y, thirdColumn.z)
            
            if let node = node {
                if selectedItem == "Table" {
                    self.centerPivot(for: node)
                }
                
                self.sceneView.scene.rootNode.addChildNode(node)
            }

        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return itemsArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "item", for: indexPath) as? ItemCell
        cell?.itemLabel.text = self.itemsArray[indexPath.row]
        return cell ?? UICollectionViewCell()
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        cell?.backgroundColor = .green
        
        self.selectedItem = itemsArray[indexPath.row]
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        cell?.backgroundColor = .yellow
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard anchor is ARPlaneAnchor else { return }
        
        DispatchQueue.main.async {
            self.planeDetectedLabel.isHidden = false
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.planeDetectedLabel.isHidden = true
            }
        }
    
    }
    
    func centerPivot(for node: SCNNode) {
        let min = node.boundingBox.min
        let max = node.boundingBox.max
        node.pivot = SCNMatrix4MakeTranslation(
            min.x + (max.x - min.x)/2,
            min.y + (max.y - min.y)/2,
            min.z + (max.z - min.z)/2
        )
    }
}

extension Int {
    var degreesToRadians: Double { return Double(self) * .pi/180}
}

