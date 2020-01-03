//
//  ViewController.swift
//  Ikea
//
//  Created by Livia Vasconcelos on 02/01/20.
//  Copyright © 2020 Livia Vasconcelos. All rights reserved.
//

import UIKit
import ARKit

class ViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {

    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var itemsCollectionView: UICollectionView!
    
    let configuration = ARWorldTrackingConfiguration()
    
    let itemsArray: [String] = ["Cup", "Vase", "Boxing", "Table"]
    var selectedItem: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.debugOptions = [SCNDebugOptions.showWorldOrigin,
                                  SCNDebugOptions.showFeaturePoints]
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration)
        
        self.itemsCollectionView.dataSource = self
        self.itemsCollectionView.delegate   = self
        
        self.registerGestureRecognizer()
    }
    
    func registerGestureRecognizer() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapped))
        sceneView.addGestureRecognizer(tap)
    }
    
    @objc func tapped(sender: UITapGestureRecognizer) {
        let sceneView   = sender.view as? ARSCNView
        let tapLocation = sender.location(in: sceneView)
        let hitTest     = sceneView?.hitTest(tapLocation, types: .existingPlaneUsingExtent)
        
        if !(hitTest?.isEmpty ?? true){
            self.addItem(hitTestResult: (hitTest?.first!)!)
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

}

