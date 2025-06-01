import UIKit
import Flutter

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        // Create a window for this scene
        window = UIWindow(windowScene: windowScene)

        // Get the Flutter engine from the app delegate
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            // The flutterEngine is not optional, so we can use it directly
            let flutterEngine = appDelegate.flutterEngine

            // Create the Flutter view controller using the engine
            let flutterViewController = FlutterViewController(engine: flutterEngine, nibName: nil, bundle: nil)

            // Set the Flutter view controller as the root view controller
            window?.rootViewController = flutterViewController
            window?.makeKeyAndVisible()
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called when the scene is being released by the system
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called when the scene is about to enter the foreground
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called when the scene has entered the background
    }
}
