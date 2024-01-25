//
//  ContentView.swift
//  MetalRaycastProblem
//
//  Created by Todd Littlejohn on 1/25/24.
//

import SwiftUI

struct ContentView: View {
    
    let metalRaycast = MetalRaycast()
    
    var body: some View {
        VStack {
            Button("Test") {
                print(metalRaycast.sendComputeRaycastCommandAndFetchResult())
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
