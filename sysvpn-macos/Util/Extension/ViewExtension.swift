//
//  ViewExtension.swift
//  sysvpn-macos
//
//  Created by NuocLoc on 03/09/2022.
//

import Foundation
import SwiftUI 

extension View {
    func trackingMouse(onMove: @escaping (NSPoint) -> Void) -> some View {
        TrackinAreaView(onMove: onMove) { self }
    }
    
    func expandTap(tap: @escaping () -> ()) -> some View {
        self.modifier(ExpandAreaTap()).onTapGesture(perform: tap)
    }
    func onNSView(added: @escaping (NSView) -> Void) -> some View {
      NSViewAccessor(onNSViewAdded: added) { self }
    }
}

private struct ExpandAreaTap: ViewModifier {
    func body(content: Content) -> some View {
        content.contentShape(Rectangle())
    }
}

 
extension NSTableView {
    open override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        backgroundColor = NSColor.clear
        enclosingScrollView?.drawsBackground = false 
        enclosingScrollView?.hasVerticalScroller = false
        enclosingScrollView?.hasHorizontalScroller = false
    }
}
 
struct NSViewAccessor<Content>: NSViewRepresentable where Content: View {
  var onNSView: (NSView) -> Void
  var viewBuilder: () -> Content
   
  init(onNSViewAdded: @escaping (NSView) -> Void, @ViewBuilder viewBuilder: @escaping () -> Content) {
    self.onNSView = onNSViewAdded
    self.viewBuilder = viewBuilder
  }
   
  func makeNSView(context: Context) -> NSViewAccessorHosting<Content> {
    return NSViewAccessorHosting(onNSView: onNSView, rootView: self.viewBuilder())
  }
   
  func updateNSView(_ nsView: NSViewAccessorHosting<Content>, context: Context) {
    nsView.rootView = self.viewBuilder()
  }
}
class NSViewAccessorHosting<Content>: NSHostingView<Content> where Content : View {
  var onNSView: ((NSView) -> Void)
   
  init(onNSView: @escaping (NSView) -> Void, rootView: Content) {
    self.onNSView = onNSView
    super.init(rootView: rootView)
  }
   
  @objc required dynamic init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
   
  required init(rootView: Content) {
    fatalError("init(rootView:) has not been implemented")
  }
   
  override func didAddSubview(_ subview: NSView) {
    super.didAddSubview(subview)
    onNSView(subview)
  }
}
