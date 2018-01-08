//
//  FeaturePointsManager.swift
//  ARKit-Sample
//
//  Created by kotetu on 2018/01/08.
//  Copyright © 2018年 Kuriyama Toru. All rights reserved.
//

import ARKit
import SceneKit

class FeaturePointsManager {
    // 処理性能の関係上、保持する特徴点数に制限を設ける
    let maxPoints = 200
    private(set) var featurePoints: [UInt64:vector_float3] = [:]
    
    func updateAndCleanup(_ newRawFeaturePoints: ARPointCloud) -> [UInt64] {
        let newFeaturePoints = split(from: FeaturePointsManager.convert(from: newRawFeaturePoints))
        let removedIdentifiers = cleanupNodes(featurePoints: newFeaturePoints)
        self.featurePoints = newFeaturePoints
        return removedIdentifiers
    }
    
    func removeAll() {
        self.featurePoints.removeAll()
    }
}

// MARK: - Static

extension FeaturePointsManager {
    static func convert(from rawFeaturePoints: ARPointCloud) -> [UInt64:vector_float3] {
        return zip(rawFeaturePoints.identifiers, rawFeaturePoints.points)
            .reduce(into: [UInt64:vector_float3]()) { $0[$1.0] = $1.1 }
    }
}

// MARK: - Private

private extension FeaturePointsManager {
    func cleanupNodes(featurePoints: [UInt64:vector_float3]) -> [UInt64] {
        let removeKeys = self.featurePoints.filter { (identifier, point) -> Bool in
            !featurePoints.keys.contains(identifier)
        }.keys
        removeKeys.forEach { (identifier) in
            self.featurePoints.removeValue(forKey: identifier)
        }
        return removeKeys.sorted(by: { $0 < $1 }) // ascending order
    }
    
    func split(from featurePoints: [UInt64:vector_float3]) -> [UInt64:vector_float3] {
        guard featurePoints.count >= maxPoints else {
            return featurePoints
        }
        let slicedIdentifiers = featurePoints.keys.sorted(by: { $0 < $1 })[0...maxPoints-1]
        return featurePoints.filter { (identifier, point) -> Bool in
            slicedIdentifiers.contains(identifier)
        }
    }
}
