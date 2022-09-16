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
      let contentController = ContentController(view)
      let userScript = WKUserScript(
        source: """
          var _selector = document.querySelector('input[name=myCheckbox]');
              _selector.addEventListener('change', function(event) {
                  var message = (_selector.checked) ? "Toggle Switch is on" : "Toggle Switch is off";
                  if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.toggleMessageHandler) {
                      window.webkit.messageHandlers.toggleMessageHandler.postMessage({
                          "message": message
                      });
                  }
              });
        """,
        injectionTime: .atDocumentEnd,
        forMainFrameOnly: false,
        in: .defaultClient
      )

      view.configuration.userContentController.add(
        contentController,
        contentWorld: .defaultClient,
        name: "toggleMessageHandler"
      )
      view.configuration.userContentController.addUserScript(userScript)
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

  class ContentController: NSObject, WKScriptMessageHandler {
    // MARK: Lifecycle

    init(_ parent: WKWebView?) {
      self.parent = parent
    }

    // MARK: Internal

    var parent: WKWebView?

    func userContentController(
      _: WKUserContentController,
      didReceive message: WKScriptMessage
    ) {
      guard let dict = message.body as? [String: AnyObject] else {
        return
      }

      guard let message = dict["message"] else {
        return
      }

      let script = "document.getElementById('value').innerText = \"\(message)\""

      parent?.evaluateJavaScript(script) { result, error in
        if let result = result {
          print("Label is updated with message: \(result)")
        } else if let error = error {
          print("An error occurred: \(error)")
        }
      }
    }
  }

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
