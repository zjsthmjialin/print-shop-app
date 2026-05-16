import Flutter
import UIKit

public class ICloudStoragePlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "com.printshopapp/icloud",
            binaryMessenger: registrar.messenger()
        )
        let instance = ICloudStoragePlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getDocumentsPath":
            if let containerURL = FileManager.default.url(
                forUbiquityContainerIdentifier: nil
            ) {
                let documentsURL = containerURL.appendingPathComponent("Documents", isDirectory: true)
                try? FileManager.default.createDirectory(
                    at: documentsURL,
                    withIntermediateDirectories: true,
                    attributes: nil
                )
                result(documentsURL.path)
            } else {
                result(nil)
            }
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
