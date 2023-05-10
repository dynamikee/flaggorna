//
//  SceneViewContainer.swift
//  Flaggorna
//
//  Created by Mikael Mattsson on 2023-05-10.
//

import SwiftUI
import SceneKit
import UIKit

struct SceneViewContainer: UIViewRepresentable {
    var scene: SCNScene
    var randomCountry: String

    func makeUIView(context: Context) -> SCNView {
        let sceneView = SCNView()
        sceneView.scene = scene

        // Set background color to match the app's background color
        sceneView.backgroundColor = UIColor.clear

        addFlagNode(to: scene, randomCountry: randomCountry)
        return sceneView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
    }

    private func addFlagNode(to scene: SCNScene, randomCountry: String) {
        
        let flagTexture = UIImage(named: randomCountry)
        let flagNode = FlagNode(frameSize: CGSize(width: 1.2, height: 0.8), xyCount: CGSize(width: 144, height: 96), diffuse: flagTexture)
        flagNode.position.z = -1
        flagNode.runAction(SCNAction.repeatForever(flagNode.flagAction))
        flagNode.addShader() // Optional: Apply a shader to the geometry for animation effect
        flagNode.scale = SCNVector3(10, 10, 10) // Optional: Adjust the scale of the flag
        scene.rootNode.addChildNode(flagNode)
    }
}
