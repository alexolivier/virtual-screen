import AppKit

let app = NSApplication.shared
NSApp.setActivationPolicy(.accessory)

let delegate = AppDelegate()
app.delegate = delegate

let mainMenu = NSMenu()

let appMenuItem = NSMenuItem()
mainMenu.addItem(appMenuItem)
let appMenu = NSMenu()
appMenu.addItem(NSMenuItem(title: "Quit VirtualScreen", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
appMenuItem.submenu = appMenu

app.mainMenu = mainMenu

app.run()
