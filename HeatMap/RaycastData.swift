//
//  RaycastData.swift
//  HeatMap
//
//  Created by Andrew Zimmer on 6/12/18.
//  Copyright © 2018 AndrewZimmer. All rights reserved.
//

import Foundation
import ARKit
import SceneKit

class RaycastData : SCNNode {
    let floatRaycastDistance:Float = 1;
    let leftEye: SCNNode
    let rightEye: SCNNode
    
    let leftEyeEnd : SCNNode
    let rightEyeEnd : SCNNode
    
    init(geometry: ARSCNFaceGeometry) {
        leftEye = SCNNode()
        rightEye = SCNNode()
        
        leftEye.opacity = 0
        rightEye.opacity = 0
        
        leftEyeEnd = SCNNode();
        leftEye.addChildNode(leftEyeEnd)
        leftEyeEnd.simdPosition = simd_float3(0,0, floatRaycastDistance);
        
        rightEyeEnd = SCNNode();
        rightEye.addChildNode(rightEyeEnd)
        rightEyeEnd.simdPosition = simd_float3(0,0, floatRaycastDistance);
        
        super.init()
        
        addChildNode(leftEye)
        addChildNode(rightEye)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("\(#function) has not been implemented")
    }
    
    
    // MARK: ARKit Updates
    func update(withFaceAnchor anchor: ARFaceAnchor) {
        if #available(iOS 12.0, *) {
            leftEye.simdTransform = anchor.leftEyeTransform;
            rightEye.simdTransform = anchor.rightEyeTransform;
        } else {
            
        };
    }
}
