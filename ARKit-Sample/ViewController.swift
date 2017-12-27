//
//  ViewController.swift
//  ARKit-Sample
//
//  Created by Kuriyama Toru on 2017/12/25.
//  Copyright © 2017年 Kuriyama Toru. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController {
    
    @IBOutlet var sceneView: ARSCNView!
    private let context = CIContext()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        sceneView.session.delegate = self
        
        // Show statistics such as fps and timing information
//        sceneView.showsStatistics = true
        
//        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        
        // Create a new scene
        let scene = SCNScene()
        
        // Set the scene to the view
        sceneView.scene = scene
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        configuration.isLightEstimationEnabled = true
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
}

// MARK: - ARSCNViewDelegate

extension ViewController: ARSCNViewDelegate {
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else {
            print("Error: This anchor is not ARPlaneAnchor. [\(#function)]")
            return
        }
        
        // Builtinジオメトリ(平面)
        let planeGeometory = SCNPlane(width: CGFloat(planeAnchor.extent.x),
                                      height: CGFloat(planeAnchor.extent.z))
        
        // 色
        planeGeometory.materials.first?.diffuse.contents = UIColor.blue
        
        // ジオメトリ情報を持ったノード情報
        let geometryPlaneNode = SCNNode(geometry: planeGeometory)
        
        // 平面の中心座標を設定する
        geometryPlaneNode.simdPosition = float3(planeAnchor.center.x, 0, planeAnchor.center.z)
        
        // 座標変換
        geometryPlaneNode.eulerAngles.x = -.pi / 2
        
        // 不透明度設定
        geometryPlaneNode.opacity = 0.33
        
        // アンカーに紐付いた情報に対してジオメトリ情報を持ったノードを追加する
        // (Appleのサンプルだと下記だが、それ以外のサンプルだとメインスレッド上で実行しており、ひょっとすると下記だとエラーが発生するかもしれない)
        node.addChildNode(geometryPlaneNode)

        if let paperModelNode = paperModelNode() {
            paperModelNode.simdPosition = float3(planeAnchor.center.x, 0, planeAnchor.center.z)
            // 「平面の上に載っている」感を出すため、平面より少しだけy座標を移動する
            paperModelNode.position.y += 0.0001
            node.addChildNode(paperModelNode)
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else {
            print("Error: This anchor is not ARPlaneAnchor. [\(#function)]")
            return
        }
        
        guard let geometryPlaneNode = node.childNodes.first,
            let planeGeometory = geometryPlaneNode.geometry as? SCNPlane else {
                print("Error: SCNPlane node is not found. [\(#function)]")
                return
        }
        
        // 平面の中心座標を設定する
        geometryPlaneNode.simdPosition = float3(planeAnchor.center.x, 0, planeAnchor.center.z)
        
        // サイズを更新する
        planeGeometory.width = CGFloat(planeAnchor.extent.x)
        planeGeometory.height = CGFloat(planeAnchor.extent.z)
    }
}

// MARK: - ARSessionDelegate

extension ViewController: ARSessionDelegate {
}

// MARK: - Private

private extension ViewController {
    func paperModelNode() -> SCNNode? {
        guard let textureImage = UIImage(named: "texture_image") else {
            print("Error: Texture image not found. [\(#function)]")
            return nil
        }
        
        let scale: CGFloat = 0.2
        let boxGeometory = SCNBox(width: textureImage.size.width * scale / textureImage.size.height,
                                  height: 0.00000001,
                                  length: scale,
                                  chamferRadius: 0)
        boxGeometory.firstMaterial?.diffuse.contents = textureImage
        return SCNNode(geometry: boxGeometory)
    }
}
