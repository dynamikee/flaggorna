//
//  Design.swift
//  Flaggorna
//
//  Created by Mikael Mattsson on 2023-06-27.
//

import SwiftUI

struct CountryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: UIScreen.main.bounds.width * 0.8, alignment: .leading)
            .padding(15)
            .background(configuration.isPressed ? Color(UIColor(red: 0.15, green: 0.15, blue: 0.18, alpha: 0.2)) : Color(UIColor(red: 0.22, green: 0.22, blue: 0.25, alpha: 1.00)))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(configuration.isPressed ? Color.white.opacity(0.2) : Color.white, lineWidth: 8)
            )
            .font(.title)
            .fontWeight(.black)
            .foregroundColor(configuration.isPressed ? Color.white.opacity(0.2) : Color.white)
    }
}



struct OrdinaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(15)
            .background(configuration.isPressed ? Color(UIColor(red: 0.15, green: 0.15, blue: 0.18, alpha: 0.2)) : Color(UIColor(red: 0.22, green: 0.22, blue: 0.25, alpha: 1.00)))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(configuration.isPressed ? Color.white.opacity(0.2) : Color.white, lineWidth: 8)
            )
            .font(.title)
            .fontWeight(.black)
            .foregroundColor(configuration.isPressed ? Color.white.opacity(0.2) : Color.white)
    }
}

struct LowKeyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(16)
            .background(configuration.isPressed ? Color.gray.opacity(0.2) : Color.gray.opacity(0.4))
            .cornerRadius(8)
            .font(.body)
            .fontWeight(.bold)
            .foregroundColor(.white)
    }
}

struct FireworkParticlesGeometryEffect : GeometryEffect {
    var time : Double
    var speed = Double.random(in: 20 ... 200)
    var direction = Double.random(in: -Double.pi ...  Double.pi)
    
    var animatableData: Double {
        get { time }
        set { time = newValue }
    }
    func effectValue(size: CGSize) -> ProjectionTransform {
        let xTranslation = speed * cos(direction) * time
        let yTranslation = speed * sin(direction) * time
        let affineTranslation =  CGAffineTransform(translationX: xTranslation, y: yTranslation)
        return ProjectionTransform(affineTranslation)
    }
}

struct ParticlesModifier: ViewModifier {
    @State var time = 0.0
    @State var scale = 0.1
    let duration = 3.0
    
    func body(content: Content) -> some View {
        ZStack {
            ForEach(0..<80, id: \.self) { index in
                content
                    .hueRotation(Angle(degrees: time * 80))
                    .scaleEffect(scale)
                    .modifier(FireworkParticlesGeometryEffect(time: time))
                    .opacity(((duration-time) / duration))
            }
        }
        .onAppear {
            withAnimation (.easeOut(duration: duration)) {
                self.time = duration
                self.scale = 1.0
            }
        }
    }
}

