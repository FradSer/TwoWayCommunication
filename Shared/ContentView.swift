//
//  ContentView.swift
//  Shared
//
//  Created by Frad LEE on 2022/9/16.
//

import SwiftUI

// MARK: - ContentView

struct ContentView: View {
  var body: some View {
    VStack {
      WebView(file: "index")
    }
    .background(Color.white)
  }
}

// MARK: - ContentView_Previews

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
