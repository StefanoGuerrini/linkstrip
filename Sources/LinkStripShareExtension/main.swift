import Foundation

/// `NSExtensionMain` is a C entry point provided by the extension host but is
/// not imported into Swift. Re-export it manually so the .appex binary has the
/// correct entry symbol.
@_silgen_name("NSExtensionMain")
func NSExtensionMain(_ argc: Int32, _ argv: UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>) -> Int32

/// App-extension entry point. Hands control to the system extension host,
/// which instantiates the class named in `NSExtensionPrincipalClass`.
_ = NSExtensionMain(CommandLine.argc, CommandLine.unsafeArgv)
