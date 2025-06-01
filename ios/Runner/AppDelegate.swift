import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  // Create a Flutter engine that can be shared between scenes
  lazy var flutterEngine = FlutterEngine(name: "main")

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Initialize and run the Flutter engine
    flutterEngine.run()

    // Register plugins with the Flutter engine
    GeneratedPluginRegistrant.register(with: flutterEngine)

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Support for iOS versions before iOS 13 (which introduced the scene delegate)
  override func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
    // Called when a new scene session is being created
    if connectingSceneSession.role == UISceneSession.Role.windowApplication {
      // Return the default scene configuration for the regular app
      let config = UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
      config.delegateClass = SceneDelegate.self
      return config
    } else if connectingSceneSession.role.rawValue == "CPTemplateApplicationSceneSessionRoleApplication" {
      // Return the CarPlay scene configuration
      let config = UISceneConfiguration(name: "CarPlay Configuration", sessionRole: connectingSceneSession.role)
      config.delegateClass = CarPlaySceneDelegate.self
      return config
    }

    return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
  }
}
