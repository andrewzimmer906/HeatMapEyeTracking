//
//  ViewController.swift
//  HeatMap
//
//  Created by Andrew Zimmer on 6/11/18.
//  Copyright © 2018 AndrewZimmer. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    let phoneWidth = 375 * 3;
    let phoneHeight = 812 * 3;
    
    var m_data : [UInt8] = [UInt8](repeating: 0, count: 375*3 * 812*3)
    
    var positions: Array<simd_float2> = Array()
    let numPositions = 10;
    
    var eyeLasers : EyeLasers?
    var eyeRaycastData : RaycastData?
    var virtualPhoneNode: SCNNode = SCNNode()
    
    var virtualScreenNode: SCNNode = {
        
        let screenGeometry = SCNPlane(width: 1, height: 1)
        screenGeometry.firstMaterial?.isDoubleSided = true
        screenGeometry.firstMaterial?.diffuse.contents = UIColor.green
        
        return SCNNode(geometry: screenGeometry)
    }()
    
    var testSphereStart : SCNNode = {
        let node = SCNNode(geometry: SCNSphere(radius: 0.01))
        node.geometry?.firstMaterial?.diffuse.contents = UIColor.purple
        return node
    }()
    
    var testSphereEnd : SCNNode = {
        let node = SCNNode(geometry: SCNSphere(radius: 0.01))
        node.geometry?.firstMaterial?.diffuse.contents = UIColor.yellow
        return node
    }()
    
    var heatMapNode:SCNNode = {
        let node = SCNNode(geometry:SCNPlane(width: 2, height: 2))  // -1 to 1
        
        let program = SCNProgram()
        program.vertexFunctionName = "heatMapVert"
        program.fragmentFunctionName = "heatMapFrag"
        
        node.geometry?.firstMaterial?.program = program;
        node.geometry?.firstMaterial?.blendMode = SCNBlendMode.add;
        
        return node;
    } ()
    
    var target : UIView = UIView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        target.backgroundColor = UIColor.red
        target.frame = CGRect.init(x: 0,y:0 ,width:25 ,height:25)
        target.layer.cornerRadius = 12.5
        sceneView.addSubview(target)
        
        // Set the view's delegate
        sceneView.delegate = self
        //sceneView.session.delegate = self
        sceneView.automaticallyUpdatesLighting = true
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        let device = sceneView.device!
        let eyeGeometry = ARSCNFaceGeometry(device: device)!
        eyeLasers = EyeLasers(geometry: eyeGeometry)
        eyeRaycastData = RaycastData(geometry: eyeGeometry)
        sceneView.scene.rootNode.addChildNode(eyeLasers!)
        sceneView.scene.rootNode.addChildNode(eyeRaycastData!)
        
        virtualPhoneNode.geometry?.firstMaterial?.isDoubleSided = true
        virtualPhoneNode.addChildNode(virtualScreenNode)

        sceneView.scene.rootNode.addChildNode(heatMapNode)
        
        //sceneView.scene.rootNode.addChildNode(testSphereStart)
        //sceneView.scene.rootNode.addChildNode(testSphereEnd)
        self.sceneView.scene.rootNode.addChildNode(virtualPhoneNode)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARFaceTrackingConfiguration()

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }

    // MARK: - ARSCNViewDelegate
    

    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let faceAnchor = anchor as? ARFaceAnchor else { return }
        eyeLasers?.transform = node.transform;
        eyeRaycastData?.transform = node.transform;
        eyeLasers?.update(withFaceAnchor: faceAnchor)
        eyeRaycastData?.update(withFaceAnchor: faceAnchor)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        virtualPhoneNode.transform = (sceneView.pointOfView?.transform)!
        
        let options : [String: Any] = [SCNHitTestOption.backFaceCulling.rawValue: false,
                                       SCNHitTestOption.searchMode.rawValue: 1,
                                       SCNHitTestOption.ignoreChildNodes.rawValue : false,
                                       SCNHitTestOption.ignoreHiddenNodes.rawValue : false]
        
        testSphereStart.worldPosition = self.eyeRaycastData!.leftEye.worldPosition
        testSphereEnd.worldPosition = self.eyeRaycastData!.leftEyeEnd.worldPosition
        
        let hitTestLeftEye = virtualPhoneNode.hitTestWithSegment(
            from: virtualPhoneNode.convertPosition(self.eyeRaycastData!.leftEye.worldPosition, from:nil),
            to:  virtualPhoneNode.convertPosition(self.eyeRaycastData!.leftEyeEnd.worldPosition, from:nil),
            //from: self.eyeRaycastData!.leftEye.worldPosition,
            //to:  self.eyeRaycastData!.leftEyeEnd.worldPosition,
            options: options)
        
        let hitTestRightEye = virtualPhoneNode.hitTestWithSegment(
            from: virtualPhoneNode.convertPosition(self.eyeRaycastData!.rightEye.worldPosition, from:nil),
            to:  virtualPhoneNode.convertPosition(self.eyeRaycastData!.rightEyeEnd.worldPosition, from:nil),
            //from: self.eyeRaycastData!.rightEye.worldPosition,
            //to:  self.eyeRaycastData!.rightEyeEnd.worldPosition,
            options: options)
        
        if (hitTestLeftEye.count > 0 && hitTestRightEye.count > 0) {
            
            var coords = screenPositionFromHittest(hitTestLeftEye[0], secondResult:hitTestRightEye[0])
            //print("x:\(coords.x) y: \(coords.y)")
            
            incrementHeatMapAtPosition(x:Int(coords.x * 3), y:Int(coords.y * 3))  // convert from points to pixels here
            
            let nsdata = NSData.init(bytes: &m_data, length: phoneWidth * phoneHeight)
            heatMapNode.geometry?.firstMaterial?.setValue(nsdata, forKey: "heatmapTexture")
            
            DispatchQueue.main.async(execute: {() -> Void in
                self.target.center = CGPoint.init(x: CGFloat(coords.x), y:CGFloat(coords.y))
            })
        }
    }
    
    func screenPositionFromHittest(_ result1: SCNHitTestResult, secondResult result2: SCNHitTestResult) -> simd_float2 {
        let iPhoneXPointSize = simd_float2(375, 812)  // size of iPhoneX in points
        let iPhoneXMeterSize = simd_float2(0.0623908297, 0.135096943231532)

        let xLC = ((result1.localCoordinates.x + result2.localCoordinates.x) / 2.0)
        var x = xLC / (iPhoneXMeterSize.x / 2.0) * iPhoneXPointSize.x
        
        let yLC = -((result1.localCoordinates.y + result2.localCoordinates.y) / 2.0);
        var y = yLC / (iPhoneXMeterSize.y / 2.0) * iPhoneXPointSize.y + 312
        
        // The 312 points adjustment above is presumably to adjust for the Extrinsics on the iPhone camera.
        // I didn't calculate them and instead ripped them from :
        // https://github.com/virakri/eye-tracking-ios-prototype/blob/master/Eyes%20Tracking/ViewController.swift
        // Probably better to get real values from measuring the camera position to the center of the screen.
        
        x = Float.maximum(Float.minimum(x, iPhoneXPointSize.x-1), 0)
        y = Float.maximum(Float.minimum(y, iPhoneXPointSize.y-1), 0)
        
        // Do just a bit of smoothing. Nothing crazy.
        positions.append(simd_float2(x,y));
        if positions.count > numPositions {
            positions.removeFirst()
        }
        
        var total = simd_float2(0,0);
        for pos in positions {
            total.x += pos.x
            total.y += pos.y
        }
        
        total.x /= Float(positions.count)
        total.y /= Float(positions.count)
        
        return total
    }

    /** Note. I'm not using this because I couldn't figure out how to set an MTLTexture to an SCNProgram because Scenekit has terrible
        documentation. That said you should DEFINITELY fix this if you ever plan to use something like this in production.
        So I left it in for reference. */
    func metalTextureFromArray(_ array:[UInt8], width:Int, height:Int) -> MTLTexture {
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: MTLPixelFormat.a8Unorm, width: width, height: height, mipmapped: false)
        
        let texture = self.sceneView.device?.makeTexture(descriptor: textureDescriptor)
        let region = MTLRegion(origin: MTLOriginMake(0, 0, 0), size: MTLSizeMake(width, height, 1))
        texture?.replace(region: region, mipmapLevel: 0, withBytes: array, bytesPerRow: width)
        
        return texture!
    }
    
    func incrementHeatMapAtPosition(x: Int, y: Int) {
        let radius:Int = 46; // in pixels
        let maxIncrement:Float = 25;
        
        for curX in x - radius ... x + radius {
            for curY in y - radius ... y + radius {
                let idx = posToIndex(x:curX, y:curY)
                
                if (idx != -1) {
                    let offset = simd_float2(Float(curX - x), Float(curY - y));
                    let len = simd_length(offset)
                    
                    if (len >= Float(radius)) {
                        continue;
                    }

                    let incrementValue = Int((1 - (len / Float(radius))) * maxIncrement);
                    if (255 - m_data[idx] > incrementValue) {
                        m_data[idx] = UInt8(Int(m_data[idx]) + incrementValue)
                    } else {
                        m_data[idx] = 255
                    }
                }
            }
        }
    }
    
    func posToIndex(x:Int, y:Int) -> Int {
        if (x < 0 || x >= phoneWidth ||
            y < 0 || y >= phoneHeight) {
            return -1;
        }
        
        return x + y * phoneWidth;
    }
}
