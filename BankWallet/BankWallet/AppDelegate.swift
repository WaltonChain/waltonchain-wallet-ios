import UIKit
import ThemeKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    private var backgroundTask: UIBackgroundTaskIdentifier = UIBackgroundTaskIdentifier.invalid

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        App.shared.appManager.didFinishLaunching()
        Theme.updateNavigationBarTheme()

        window = UIWindow(frame: UIScreen.main.bounds)
        window?.makeKeyAndVisible()

        window?.backgroundColor = .themeTyler
        window?.rootViewController = LaunchRouter.module()

        UIApplication.shared.setMinimumBackgroundFetchInterval(3600)

        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        App.shared.appManager.willResignActive()
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        App.shared.appManager.didBecomeActive()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        App.shared.appManager.didEnterBackground()

        backgroundTask = UIApplication.shared.beginBackgroundTask {
            UIApplication.shared.endBackgroundTask(self.backgroundTask)
            self.backgroundTask = UIBackgroundTaskIdentifier.invalid
        }
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        App.shared.appManager.willEnterForeground()

        if backgroundTask != UIBackgroundTaskIdentifier.invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = UIBackgroundTaskIdentifier.invalid
        }
    }

    func applicationWillTerminate(_ application: UIApplication) {
        App.shared.appManager.willTerminate()
    }

    func application(_ application: UIApplication, shouldAllowExtensionPointIdentifier extensionPointIdentifier: UIApplication.ExtensionPointIdentifier) -> Bool {
        if extensionPointIdentifier == .keyboard {
            //disable custom keyboards
            return false
        }
        return true
    }

//    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
//        App.shared.backgroundPriceAlertManager.fetchRates { success in
//            completionHandler(success ? .newData : .failed)
//        }
//    }

}
