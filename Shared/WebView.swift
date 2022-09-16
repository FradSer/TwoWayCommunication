//
//  WebView.swift
//  TwoWayCommunication
//
//  Created by Frad LEE on 2022/9/16.
//

import SwiftUI
import WebKit

#if os(macOS)
  public typealias WebViewRepresentable = NSViewRepresentable
#elseif os(iOS)
  public typealias WebViewRepresentable = UIViewRepresentable
#endif

// MARK: - WebView

struct WebView: WebViewRepresentable {
  // MARK: Internal

  class Coordinator: NSObject, WKNavigationDelegate {
    // MARK: Lifecycle

    init(_ parent: WebView) {
      self.parent = parent
    }

    // MARK: Internal

    let parent: WebView

    func webView(_: WKWebView, didCommit _: WKNavigation!) {
      parent.loadStatusChanged?(true, nil)
    }

    func webView(_: WKWebView, didFinish _: WKNavigation!) {
      parent.loadStatusChanged?(false, nil)
    }

    func webView(
      _: WKWebView,
      didFail _: WKNavigation!,
      withError error: Error
    ) {
      parent.loadStatusChanged?(false, error)
    }
  }

  var file: String
  var loadStatusChanged: ((Bool, Error?) -> Void)?

  func makeCoordinator() -> WebView.Coordinator {
    Coordinator(self)
  }

  #if os(iOS)
    func makeUIView(context: Context) -> WKWebView {
      let view = WKWebView()

      view.scrollView.isScrollEnabled = false
      view.isOpaque = false
      view.backgroundColor = .clear

      view.navigationDelegate = context.coordinator

      return view
    }

    func updateUIView(_ view: WKWebView, context _: Context) {
      loadFileURL(file, view: view)
    }

  #elseif os(macOS)
    func makeNSView(context: Context) -> WKWebView {
      let view = WKWebView()

      view.navigationDelegate = context.coordinator
      view.enclosingScrollView?.automaticallyAdjustsContentInsets = true

      return view
    }

    func updateNSView(_ view: WKWebView, context _: Context) {
      loadFileURL(file, view: view)
    }
  #endif

  // MARK: Private

  private func onLoadStatusChanged(perform: ((Bool, Error?) -> Void)?)
    -> some View {
    var copy = self
    copy.loadStatusChanged = perform
    return copy
  }

  private func loadFileURL(_ fileName: String, view: WKWebView) {
    let filePath = Bundle.main.path(
      forResource: fileName,
      ofType: "html"
    )

    let filePathURL = URL(fileURLWithPath: filePath!, isDirectory: false)
    view.loadFileURL(
      filePathURL,
      allowingReadAccessTo: filePathURL
    )
  }
}
