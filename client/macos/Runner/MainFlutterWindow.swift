import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    self.contentViewController = flutterViewController

    let defaultSize = NSSize(width: 1400, height: 900)
    self.contentMinSize = NSSize(width: 1100, height: 700)

    if let screen = NSScreen.main {
      let visible = screen.visibleFrame
      let origin = NSPoint(
        x: visible.midX - defaultSize.width / 2,
        y: visible.midY - defaultSize.height / 2
      )
      self.setFrame(
        NSRect(origin: origin, size: defaultSize),
        display: true
      )
    } else {
      self.setContentSize(defaultSize)
    }

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
