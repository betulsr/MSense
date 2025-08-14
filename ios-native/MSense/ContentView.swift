//
//  ContentView.swift
//  MSense
//
//  Created by AI Assistant on 2025-08-08.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        MainTabView()
    }
}

#Preview {
    ContentView()
        .environmentObject(ThemeManager())
        .environmentObject(PredictionService())
}
