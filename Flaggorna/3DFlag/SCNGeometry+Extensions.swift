//
//  SCNGeometry+Extensions.swift
//  Flaggorna
//
//  Created by Mikael Mattsson on 2023-05-08.
//

import SceneKit.SCNGeometry

extension SCNGeometry {
    /// Get the vertices, texture mapping and indices for a plane geometry
    ///
    /// - Parameters:
    ///   - size: how large you want the geometry
    ///   - xyCount: how many vertices you want, in the width and in the height
    ///     minimum of 2 for each
    /// - Returns: vertices, texture mapping and indices for your plane geometry
    static func PlaneParts(size: CGSize, xyCount: CGSize = CGSize(width: 2, height: 2)) -> ([SCNVector3], SCNGeometrySource, SCNGeometryElement) {
        var triPositions = [SCNVector3].init(repeating: SCNVector3Zero, count: Int(xyCount.width * xyCount.height))
        var yPos = size.height / 2
        let xStart = -size.width / 2
        var indices: [UInt32] = []
        var textureCoord: [CGPoint] = [CGPoint].init(repeating: CGPoint.zero, count: Int(xyCount.width * xyCount.height))
        for y in 0..<Int(xyCount.height) {
            for x in 0..<Int(xyCount.width) {
                triPositions[y * Int(xyCount.width) + x] = SCNVector3(xStart + size.width * CGFloat(x) / CGFloat(xyCount.width - 1), yPos, 0)
                textureCoord[y * Int(xyCount.width) + x] = CGPoint(x: CGFloat(x) / CGFloat(xyCount.width - 1), y: CGFloat(y) / CGFloat(xyCount.height - 1))
                if x > 0 && y > 0 {
                    let currentCoord = CGFloat(y * Int(xyCount.width) + x)
                    indices.append(contentsOf: [
                        UInt32(currentCoord - xyCount.width - 1),
                        UInt32(currentCoord - 1),
                        UInt32(currentCoord - xyCount.width),
                        UInt32(currentCoord - xyCount.width),
                        UInt32(currentCoord - 1),
                        UInt32(currentCoord)
                        ])
                }
            }
            yPos -= size.height / (xyCount.height - 1)
        }
        return (triPositions, SCNGeometrySource(textureCoordinates: textureCoord), SCNGeometryElement(indices: indices, primitiveType: .triangles))
    }



}
