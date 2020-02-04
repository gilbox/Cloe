// Created by Gil Birman on 1/2/20.

import Cocoa
import FirebaseCore
import FirebaseAuth
import FirebaseDatabase
import FirebaseFirestore
import SwiftUI

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

  var window: NSWindow!

  func applicationDidFinishLaunching(_ aNotification: Notification) {
    // create store
    let store = AppStore(
      reducer: appReducer,
      state: .initialValue,
      middlewares: [createLogMiddleware(), createPublisherMiddleware()])

    // inject store into root view
    let contentView = ContentView().environmentObject(store)

    // Create the window and set the content view.
    window = NSWindow(
        contentRect: NSRect(x: 0, y: 0, width: 480, height: 300),
        styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
        backing: .buffered, defer: false)
    window.center()
    window.setFrameAutosaveName("Main Window")
    window.contentView = NSHostingView(rootView: contentView)
    window.makeKeyAndOrderFront(nil)
  }

  func applicationWillTerminate(_ aNotification: Notification) {
    // Insert code here to tear down your application
  }


}

