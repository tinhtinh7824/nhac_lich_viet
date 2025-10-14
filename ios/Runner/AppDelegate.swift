import Flutter
import UIKit
import Photos

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: "nhac_lich_viet/image_saver",
        binaryMessenger: controller.binaryMessenger
      )

      channel.setMethodCallHandler { [weak self] call, result in
        guard call.method == "saveImage" else {
          result(FlutterMethodNotImplemented)
          return
        }

        guard
          let arguments = call.arguments as? [String: Any],
          let byteData = arguments["bytes"] as? FlutterStandardTypedData
        else {
          result(
            FlutterError(
              code: "INVALID_ARGUMENT",
              message: "Image bytes are missing",
              details: nil
            )
          )
          return
        }

        let fileName = arguments["name"] as? String ?? "nhac_lich_viet.png"

        self?.saveImageToPhotoLibrary(
          data: byteData.data,
          fileName: fileName,
          result: result
        )
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func saveImageToPhotoLibrary(
    data: Data,
    fileName: String,
    result: @escaping FlutterResult
  ) {
    requestPhotoAuthorization { granted in
      guard granted else {
        result(
          FlutterError(
            code: "PERMISSION_DENIED",
            message: "Photo library access denied",
            details: nil
          )
        )
        return
      }

      PHPhotoLibrary.shared().performChanges({
        let creationRequest = PHAssetCreationRequest.forAsset()
        let options = PHAssetResourceCreationOptions()
        options.originalFilename = fileName
        creationRequest.addResource(with: .photo, data: data, options: options)
      }) { success, error in
        DispatchQueue.main.async {
          if success {
            result(true)
          } else {
            result(
              FlutterError(
                code: "SAVE_ERROR",
                message: error?.localizedDescription ?? "Unknown error while saving image",
                details: nil
              )
            )
          }
        }
      }
    }
  }

  private func requestPhotoAuthorization(completion: @escaping (Bool) -> Void) {
    if #available(iOS 14, *) {
      let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
      switch status {
      case .authorized, .limited:
        completion(true)
      case .denied, .restricted:
        completion(false)
      case .notDetermined:
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { newStatus in
          DispatchQueue.main.async {
            completion(newStatus == .authorized || newStatus == .limited)
          }
        }
      @unknown default:
        completion(false)
      }
    } else {
      let status = PHPhotoLibrary.authorizationStatus()
      switch status {
      case .authorized:
        completion(true)
      case .denied, .restricted:
        completion(false)
      case .notDetermined:
        PHPhotoLibrary.requestAuthorization { newStatus in
          DispatchQueue.main.async {
            completion(newStatus == .authorized)
          }
        }
      @unknown default:
        completion(false)
      }
    }
  }
}
