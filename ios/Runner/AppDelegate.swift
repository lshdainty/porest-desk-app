import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "PorestClipboardHint") {
      ClipboardHintChannel.register(with: registrar)
    }
  }
}

/// 클립보드를 **읽지 않고** 힌트만 넘겨 주는 채널.
///
/// iOS 는 앱이 클립보드 내용을 읽을 때마다 "○○에서 붙여넣기" 배너를 띄운다.
/// 홈에 들어올 때마다 읽으면 그 배너가 계속 떠 사용자를 괴롭히므로,
/// 여기서는 내용 접근이 없는 두 가지만 본다.
///
/// - `changeCount` — 클립보드가 바뀔 때마다 오르는 정수. 같은 복사본에 대해
///   배너를 다시 띄우지 않으려고 쓴다(사용자가 한 번 닫으면 그 값을 기억한다).
/// - `hasNumber` — `detectPatterns` 로 "숫자가 들어 있는가" 만 확인한다.
///   결제 문자에는 금액이 반드시 있으므로 약한 단서로 쓸 만하고,
///   이 API 는 내용을 넘겨주지 않아 붙여넣기 배너가 뜨지 않는다.
///
/// 실제 읽기는 사용자가 배너를 눌렀을 때 Dart 쪽에서 한 번만 한다.
///
/// (별도 파일로 두려면 Xcode 프로젝트에 파일 참조를 추가해야 해서 여기 함께 둔다.)
enum ClipboardHintChannel {
  private static let channelName = "porest/clipboard_hint"

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: channelName,
      binaryMessenger: registrar.messenger())

    channel.setMethodCallHandler { call, result in
      guard call.method == "hint" else {
        result(FlutterMethodNotImplemented)
        return
      }
      respondWithHint(result)
    }
  }

  private static func respondWithHint(_ result: @escaping FlutterResult) {
    let board = UIPasteboard.general
    let changeCount = board.changeCount

    guard #available(iOS 14.0, *) else {
      // iOS 13 에는 패턴 감지가 없다. hasStrings 는 내용을 넘기지 않으므로
      // 배너 없이 "문자열이 있다" 까지는 알 수 있다.
      result(["changeCount": changeCount, "hasNumber": board.hasStrings])
      return
    }

    board.detectPatterns(for: [.number]) { outcome in
      let hasNumber: Bool
      switch outcome {
      case .success(let patterns):
        hasNumber = patterns.contains(.number)
      case .failure:
        // 감지에 실패해도 앱이 멈출 이유는 없다 — 배너를 띄우지 않을 뿐이다.
        hasNumber = false
      }
      DispatchQueue.main.async {
        result(["changeCount": changeCount, "hasNumber": hasNumber])
      }
    }
  }
}
