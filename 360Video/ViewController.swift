//
//  ViewController.swift
//  360Video
//
//  Created by idz on 5/1/16.
//  Copyright © 2016 iOS Developer Zone.
//  License: MIT https://raw.githubusercontent.com/iosdevzone/PanoView/master/LICENSE
//

import UIKit
import SceneKit
import CoreMotion
import SpriteKit
import AVFoundation
import ARKit

extension Int {
    var degreesToRadians: CGFloat { return CGFloat(Int(self)) * .pi / 180 }
}

class ViewController: UIViewController {
    
    let motionManager = CMMotionManager()
    var isControlsShown = false
    var controlsNode = SCNNode()
    var mainNode = SCNNode()
    var playNode = SCNNode()
    var pauseNode = SCNNode()
    var stopNode = SCNNode()
    var videoNode = SKVideoNode()
    var videoARNode = SCNNode()
    var player = AVPlayer()
    
    @IBOutlet weak var sceneView: ARSCNView!
    
    func createPlaneNode(_ material: AnyObject?) -> SCNNode {
        let plane = SCNPlane(width: 4.8, height: 2.7)
        plane.firstMaterial!.isDoubleSided = true
        plane.firstMaterial!.diffuse.contents = material
        videoARNode = SCNNode(geometry: plane)
        videoARNode.position = SCNVector3Make(0,0,0.01)
        videoARNode.scale = SCNVector3(0.2,0.2,0.2)
        videoARNode.eulerAngles = SCNVector3(180.degreesToRadians,0,0)
        videoARNode.name = "VideoNode"
        return videoARNode
    }
    
    func animateNode(node:SCNNode, scale:SCNVector3)
    {
        let animation = CABasicAnimation(keyPath: "scale")
        animation.fromValue = node.scale
        animation.toValue = scale
        animation.duration = 0.3
        animation.autoreverses = false
        animation.repeatCount = 1
        node.scale = scale
        node.addAnimation(animation, forKey: "scale")
    }
    
    @IBAction func add(_ sender: Any) {
        self.resetSession()
        let urlStr = Bundle.main.path(forResource:"sample", ofType: "mp4")
        let url = URL(fileURLWithPath: urlStr ?? "")
        player = AVPlayer(url: url as URL)
        videoNode = SKVideoNode(avPlayer: player)
        let size = CGSize(width: self.view.frame.width, height: self.view.frame.height)
        videoNode.size = size
        videoNode.position = CGPoint(x: size.width/2, y: size.height/2)
        videoNode.play()
        let spriteScene = SKScene(size: size)
        spriteScene.addChild(videoNode)
        
        let planeNode = createPlaneNode(spriteScene)
        configureScene(node: planeNode)
        guard motionManager.isDeviceMotionAvailable else {
            fatalError("Device motion is not available")
        }
    }
    
    @IBAction func reset(_ sender: Any) {
        self.resetSession()
    }
    
    func configureScene(node planeNode: SCNNode) {
        // Set the scene
        let scene = SCNScene()
        sceneView.scene = scene
        sceneView.showsStatistics = true
        
        mainNode = SCNNode(geometry: SCNPlane(width: 4.8, height: 2.7))
        mainNode.geometry?.firstMaterial?.diffuse.contents = #imageLiteral(resourceName: "bg")
        mainNode.position = SCNVector3Make(0,0,-6)
        mainNode.movabilityHint = .fixed
        mainNode.addChildNode(planeNode)
        
        playNode = SCNNode(geometry: SCNPlane(width: 0.3, height: 0.3))
        playNode.geometry?.firstMaterial?.diffuse.contents = #imageLiteral(resourceName: "play")
        playNode.position = SCNVector3(0,-1.1,0.03)
        playNode.name = "play"
        mainNode.addChildNode(playNode)

        pauseNode = SCNNode(geometry: SCNPlane(width: 0.3, height: 0.3))
        pauseNode.geometry?.firstMaterial?.diffuse.contents = #imageLiteral(resourceName: "pause")
        pauseNode.position = SCNVector3(-0.4,-1.1,0.03)
        pauseNode.name = "pause"
        mainNode.addChildNode(pauseNode)

        stopNode = SCNNode(geometry: SCNPlane(width: 0.3, height: 0.3))
        stopNode.geometry?.firstMaterial?.diffuse.contents = #imageLiteral(resourceName: "stop")
        stopNode.position = SCNVector3(0.4,-1.1,0.03)
        stopNode.name = "stop"
        mainNode.addChildNode(stopNode)

        controlsNode = SCNNode(geometry: SCNPlane(width: 4.8, height: 0.4))
        controlsNode.geometry?.firstMaterial?.diffuse.contents = UIColor.lightGray
        controlsNode.opacity = 0.05
        controlsNode.position = SCNVector3(0,-1.15,0.02)
        controlsNode.name = "controls bg"
        mainNode.addChildNode(controlsNode)
        scene.rootNode.addChildNode(mainNode)
        hideControls(true)
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let configuration = ARWorldTrackingConfiguration()
        sceneView.session.configuration?.isLightEstimationEnabled = true
        sceneView.session.run(configuration)
        
        let tapGesture = UITapGestureRecognizer.init(target: self, action: #selector(self.addVideoNode))
        self.sceneView.addGestureRecognizer(tapGesture)
        
//        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: self.player.currentItem, queue: .main) { _ in
//            self.player.seek(to: kCMTimeZero)
//            self.player.play()
//        }
    }
    
    func addVideoNode(sender : UITapGestureRecognizer)
    {
        let location: CGPoint = sender.location(in: self.sceneView)
        let hits = self.sceneView.hitTest(location, options: nil)
        if let tappedNode = hits.first?.node {
            print(tappedNode.name ?? "")
            if tappedNode.name == "VideoNode"
            {
                self.hideControls(false)
                self.animateNode(node: tappedNode, scale: SCNVector3(1,1,1))
            }
            else if tappedNode.name == "play"
            {
                player.play()
            }
            else if tappedNode.name == "pause"
            {
                player.pause()
            }
            else if tappedNode.name == "stop"
            {
                player.seek(to:(player.currentItem?.duration)!)
                player.pause()
                player.seek(to: kCMTimeZero)
//                player.replaceCurrentItem(with: nil)
                self.hideControls(true)
                self.animateNode(node: videoARNode, scale: SCNVector3(0.2,0.2,0.2))
            }
        }
    }
    
    func hideControls(_ show:Bool)
    {
        controlsNode.isHidden = show
        playNode.isHidden = show
        pauseNode.isHidden = show
        stopNode.isHidden = show
    }
    
    func resetSession()
    {
        sceneView.session.pause()
        sceneView.scene.rootNode.enumerateChildNodes { (node, stop) in
            node.removeFromParentNode()
        }
        sceneView.session.run(sceneView.session.configuration!, options: [.resetTracking, .removeExistingAnchors])
    }
    override func viewDidAppear(_ animated: Bool) {
//        sceneView.play(self)
    }
    
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

