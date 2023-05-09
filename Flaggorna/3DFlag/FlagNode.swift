//
//  FlagNode.swift
//  Flaggorna
//
//  Created by Mikael Mattsson on 2023-05-08.
//

import SceneKit

class FlagNode: SCNNode {
     var xyCount: CGSize
     var geometrySize: CGSize
     var vertices: [SCNVector3]
     var timer: Timer? = nil
     var indices: SCNGeometryElement
    var material = SCNMaterial()
     var textureCoord: SCNGeometrySource
     var flagAction: SCNAction!
    /// Create a plane of width, height, vertex count and material diffuse
    ///
    /// - Parameters:
    ///   - frameSize: physical width and height of the geometry
    ///   - xyCount: number of horizontal and vertical vertices
    ///   - diffuse: diffuse to be applied to the geometry; a color, image, or source of animated content.
    public init(frameSize: CGSize, xyCount: CGSize, diffuse: Any? = UIColor.white) {
        let (verts, textureMap, inds) = SCNGeometry.PlaneParts(size: frameSize, xyCount: xyCount)
        self.xyCount = xyCount
        self.textureCoord = textureMap
        self.geometrySize = frameSize
        self.indices = inds
        self.vertices = verts
        super.init()
        self.updateGeometry()
        self.flagAction = SCNAction.customAction(duration: 100000) { (_, elapsedTime) in
            // using duration: Double.infinity or Double.greatestFiniteMagnitude breaks `elapsedTime`
            // I'll try find some alternative that's nicer than `100000` later
            self.animateFlag(elapsedTime: elapsedTime+5000)
        }
        self.material.diffuse.contents = diffuse
        self.runAction(SCNAction.repeatForever(self.flagAction))
    }

    /// Update the geometry of this node with the vertices, texture coordinates and indices
    private func updateGeometry() {
        let src = SCNGeometrySource(vertices: vertices)
        let geo = SCNGeometry(sources: [src, self.textureCoord], elements: [self.indices])
        geo.materials = [self.material]
        self.geometry = geo
    }

    /// Wave the flag using just the x coordinate
    ///
    /// - Parameter elapsedTime: time since animation started [0-duration] in seconds
    private func animateFlag(elapsedTime: CGFloat) {
        let yCount = Int(xyCount.height)
        let xCount = Int(xyCount.width)
        let furthest = Float((yCount - 1) + (xCount - 1))
        let tNow = elapsedTime
        let waveScale = Float(0.1 * (min(tNow / 10, 1)))
        for x in 0..<xCount {
            let distance = Float(x) / furthest
            let newZ = waveScale * (sinf(5 * (Float( tNow) - distance)) * distance)
            // only the x position is effecting the translation here,
            // that's why we calculate before going to the second while loop
            for y in 0..<yCount {
                self.vertices[y * xCount + x].z = newZ
            }
        }
        self.updateGeometry()
    }

    /// Adds a shader to the geometry instead of an animation
    func addShader() {
        let waveShader = "_geometry.position.z = " +
            "0.1 *" +
            " sin(15 * (u_time - _geometry.position.x))" +
        " * (0.5 + _geometry.position.x / \(self.geometrySize.width)); \n"
        self.geometry?.shaderModifiers = [SCNShaderModifierEntryPoint.geometry: waveShader]
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
