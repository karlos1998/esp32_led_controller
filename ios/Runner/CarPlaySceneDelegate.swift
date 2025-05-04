import UIKit
import CarPlay
import Flutter

class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {
    
    var interfaceController: CPInterfaceController?
    var flutterEngine: FlutterEngine?
    var methodChannel: FlutterMethodChannel?
    
    // Connect to the Flutter engine when CarPlay is connected
    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene,
                                 didConnect interfaceController: CPInterfaceController) {
        self.interfaceController = interfaceController
        
        // Get the Flutter engine from the AppDelegate
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            // Create a new Flutter engine for CarPlay
            self.flutterEngine = FlutterEngine(name: "CarPlayEngine")
            self.flutterEngine?.run()
            
            // Set up method channel for communication with Flutter
            let messenger = self.flutterEngine?.binaryMessenger
            self.methodChannel = FlutterMethodChannel(name: "com.tougelight/carplay", 
                                                     binaryMessenger: messenger!)
            
            // Set up the CarPlay interface
            setupCarPlayInterface()
        }
    }
    
    // Clean up when CarPlay is disconnected
    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene,
                                 didDisconnectInterfaceController interfaceController: CPInterfaceController) {
        self.interfaceController = nil
        self.flutterEngine = nil
        self.methodChannel = nil
    }
    
    // Set up the CarPlay interface with controls for the LED lights
    private func setupCarPlayInterface() {
        // Create buttons for the main functions
        let toggleButton = CPGridButton(titleVariants: ["Toggle LED"], 
                                       image: UIImage(systemName: "lightbulb")!, 
                                       handler: { [weak self] button in
            self?.methodChannel?.invokeMethod("toggleLed", arguments: nil)
        })
        
        let brightnessUpButton = CPGridButton(titleVariants: ["Brightness +"], 
                                            image: UIImage(systemName: "sun.max")!, 
                                            handler: { [weak self] button in
            self?.methodChannel?.invokeMethod("increaseBrightness", arguments: nil)
        })
        
        let brightnessDownButton = CPGridButton(titleVariants: ["Brightness -"], 
                                              image: UIImage(systemName: "sun.min")!, 
                                              handler: { [weak self] button in
            self?.methodChannel?.invokeMethod("decreaseBrightness", arguments: nil)
        })
        
        // Create color preset buttons
        let redButton = CPGridButton(titleVariants: ["Red"], 
                                   image: UIImage(systemName: "circle.fill")!.withTintColor(.red, renderingMode: .alwaysOriginal), 
                                   handler: { [weak self] button in
            self?.methodChannel?.invokeMethod("setColor", arguments: ["red"])
        })
        
        let greenButton = CPGridButton(titleVariants: ["Green"], 
                                     image: UIImage(systemName: "circle.fill")!.withTintColor(.green, renderingMode: .alwaysOriginal), 
                                     handler: { [weak self] button in
            self?.methodChannel?.invokeMethod("setColor", arguments: ["green"])
        })
        
        let blueButton = CPGridButton(titleVariants: ["Blue"], 
                                    image: UIImage(systemName: "circle.fill")!.withTintColor(.blue, renderingMode: .alwaysOriginal), 
                                    handler: { [weak self] button in
            self?.methodChannel?.invokeMethod("setColor", arguments: ["blue"])
        })
        
        // Create a grid template with the buttons
        let gridTemplate = CPGridTemplate(title: "Touge Light Controller", 
                                        gridButtons: [toggleButton, brightnessUpButton, brightnessDownButton, 
                                                     redButton, greenButton, blueButton])
        
        // Set the root template
        interfaceController?.setRootTemplate(gridTemplate, animated: true)
    }
}