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
    
    typealias FeaturePoint = (identifier: UInt64, point: vector_float3)
    
    @IBOutlet var sceneView: ARSCNView!
    private let context = CIContext()
    private var featurePointNodes:[UInt64:SCNNode] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        sceneView.session.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
//        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
        
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
        removeAllNodes()
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
        geometryPlaneNode.opacity = 0.8
        
        // アンカーに紐付いた情報に対してジオメトリ情報を持ったノードを追加する
        // (Appleのサンプルだと下記だが、それ以外のサンプルだとメインスレッド上で実行しており、ひょっとすると下記だとエラーが発生するかもしれない)
        node.addChildNode(geometryPlaneNode)
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
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        guard let currentFrame = sceneView.session.currentFrame else {
            print("Error: Current frame is nil. [\(#function)]")
            return
        }
        
        // 特徴点をプロット
        if let rawFeaturePoints = currentFrame.rawFeaturePoints {
            print("feature points: \(rawFeaturePoints.__count)")

            let featurePoints = convert(from: rawFeaturePoints)
            cleanupNodes(featurePoints: rawFeaturePoints)
            
            for featurePoint in featurePoints {
                if featurePointNodes[featurePoint.identifier] != nil {
                    featurePointNodes[featurePoint.identifier]!.position = SCNVector3Make(featurePoint.point.x,
                                                                                          featurePoint.point.y,
                                                                                          featurePoint.point.z)
                } else {
                    let geometryBoxNode = createBoxNode()
                    geometryBoxNode.position = SCNVector3Make(featurePoint.point.x,
                                                              featurePoint.point.y,
                                                              featurePoint.point.z)
                    sceneView.scene.rootNode.addChildNode(geometryBoxNode)
                    featurePointNodes[featurePoint.identifier] = geometryBoxNode
                }
            }
        } else {
            removeAllNodes()
        }

        // 表示時には90度回転する
        let ciImage = CIImage(cvPixelBuffer: currentFrame.capturedImage).oriented(.right)
        let imageFilter:CIFilter = CIFilter(name: "CIPhotoEffectProcess")!
        imageFilter.setValue(ciImage, forKey: kCIInputImageKey)

        // background.contentsはCGImageでセットする必要がある
        if let filtImage = imageFilter.outputImage,
            let cgImage = context.createCGImage(filtImage, from: ciImage.extent) {
            sceneView.scene.background.contents = cgImage
        }
    }
}

// MARK: - ARSessionDelegate

extension ViewController: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
    }
}

// MARK: - Private

private extension ViewController {
    func createBoxNode() -> SCNNode {
        let boxGeometory = SCNBox(width: 0.003, height: 0.003, length: 0.003, chamferRadius: 0.004)
        boxGeometory.materials.first?.diffuse.contents = randomColor()
        return SCNNode(geometry: boxGeometory)
    }
    
    func randomColor(alpha:CGFloat = 1.0) -> UIColor {
        let red:CGFloat = CGFloat(drand48())
        let green:CGFloat = CGFloat(drand48())
        let blue:CGFloat = CGFloat(drand48())
        return UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }
    
    func convert(from rawFeaturePoints: ARPointCloud) -> [FeaturePoint] {
        var index = 0
        return rawFeaturePoints.identifiers.flatMap({ (identifier) -> FeaturePoint in
            let featurePoint = FeaturePoint(identifier: identifier, point: rawFeaturePoints.points[index])
            index += 1
            return featurePoint
        })
    }

    func cleanupNodes(featurePoints: ARPointCloud) {
        for drawFeaturePoint in featurePointNodes {
            if !featurePoints.identifiers.contains(drawFeaturePoint.key) {
                featurePointNodes[drawFeaturePoint.key]?.removeFromParentNode()
                featurePointNodes.removeValue(forKey: drawFeaturePoint.key)
            }
        }
    }
    
    func removeAllNodes() {
        for drawFeaturePoint in featurePointNodes {
            featurePointNodes[drawFeaturePoint.key]?.removeFromParentNode()
        }
        featurePointNodes.removeAll()
    }
}
