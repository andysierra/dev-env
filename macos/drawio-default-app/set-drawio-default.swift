// Registra la PWA draw.io como app por defecto de los archivos .drawio en macOS.
//
//   swift set-drawio-default.swift                       # usa la ruta por defecto
//   swift set-drawio-default.swift /ruta/a/draw.io.app   # otra ruta del shim
//
// .drawio no tiene UTI declarado por ninguna app, asi que LaunchServices le asigna
// un UTI dinamico (dyn.ah62d4rv4ge80k6xbs7y08). UTType(filenameExtension:) lo resuelve
// y NSWorkspace.setDefaultApplication lo asocia. Idempotente: re-ejecutar no rompe nada.
// Requiere macOS 12+. No necesita `duti` ni editar plists de LaunchServices a mano.

import Foundation
import AppKit
import UniformTypeIdentifiers

let defaultApp = NSHomeDirectory()
    + "/Applications/Chromium Apps.localized/draw.io.app"
let appPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : defaultApp

guard FileManager.default.fileExists(atPath: appPath) else {
    FileHandle.standardError.write("no existe la app: \(appPath)\n".data(using: .utf8)!)
    exit(1)
}
guard let type = UTType(filenameExtension: "drawio") else {
    FileHandle.standardError.write("no se pudo resolver el UTI de .drawio\n".data(using: .utf8)!)
    exit(1)
}

let appURL = URL(fileURLWithPath: appPath)
print("app  : \(appPath)")
print("UTI  : \(type.identifier) (dinamico: \(type.isDynamic))")

let done = DispatchSemaphore(value: 0)
var failed = false
NSWorkspace.shared.setDefaultApplication(at: appURL, toOpen: type) { error in
    if let error { print("ERROR: \(error)"); failed = true }
    done.signal()
}
done.wait()
if failed { exit(1) }

if let current = NSWorkspace.shared.urlForApplication(toOpen: type) {
    print("ahora: \(current.path)")
}
