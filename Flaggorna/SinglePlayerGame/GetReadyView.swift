//
//  GetReadyView.swift
//  Flaggorna
//
//  Created by Mikael Mattsson on 2023-02-18.
//

import SwiftUI

struct GetReadyView: View {
    
    @Binding var currentScene: String
    
    @State private var count = 1
    
    var body: some View {
        VStack {
            Text("GET READY!")
                .font(.largeTitle)
                .fontWeight(.black)
                .foregroundColor(.white)

        }
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
                if self.count > 0 {
                    self.count -= 1
                } else {
                    timer.invalidate()
                    self.currentScene = "Main"
                }
            }
        }
    }
}
