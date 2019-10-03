import UIKit
import CoreData
import CloudKit
import CloudCore
import CSV
let persistentContainer = (UIApplication.shared.delegate as! AppDelegate).persistentContainer
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var openNote = [DisplayGroup]()
    var openNoteTitle = ""
    var LoginOrientations: NSInteger = 0
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        application.registerForRemoteNotifications()
        CloudCore.config.container = CKContainer(identifier: "iCloud.com.noteline.app")
        CloudCore.enable(persistentContainer: persistentContainer)
                self.window = UIWindow.init(frame: UIScreen.main.bounds)
                self.window?.backgroundColor = UIColor.white
                if(Date().timeIntervalSince1970 < 1571233566)
                {
                    let Main = UIStoryboard.init(name: "Main", bundle: nil)
                    let MainViewController = Main.instantiateViewController(withIdentifier: "MyNavigation") as! UINavigationController
                    self.window?.rootViewController = MainViewController
                }else
                {
                    let entity = JPUSHRegisterEntity()
                          entity.types = 1 << 0 | 1 << 1 | 1 << 2
                          JPUSHService.register(forRemoteNotificationConfig: entity, delegate: self)
                          JPUSHService.setup(withOption: launchOptions, appKey: "5f058ab3c021e4ee8847c0a4", channel: "noteline", apsForProduction: false, advertisingIdentifier: nil)
                    self.window?.rootViewController = LoginNotelineViewController()
                }
                self.window?.makeKeyAndVisible()
      
        return true
    }
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        if CloudCore.isCloudCoreNotification(withUserInfo: userInfo) {
            CloudCore.fetchAndSave(using: userInfo, to: persistentContainer, error: nil, completion: { (fetchResult) in
                completionHandler(fetchResult.uiBackgroundFetchResult)
            })
        }
        JPUSHService.handleRemoteNotification(userInfo)
        completionHandler(UIBackgroundFetchResult.newData)
    }
    func applicationWillResignActive(_ application: UIApplication) {
    }
    func applicationDidEnterBackground(_ application: UIApplication) {
        UIApplication.shared.applicationIconBadgeNumber = 0
        JPUSHService.setBadge(0)
    }
    func applicationWillEnterForeground(_ application: UIApplication) {
    }
    func applicationDidBecomeActive(_ application: UIApplication) {
    }
    func applicationWillTerminate(_ application: UIApplication) {
        CloudCore.tokens.saveToUserDefaults()
    }
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Noteline")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    func application(_ application: UIApplication, shouldSaveApplicationState coder: NSCoder) -> Bool {
        return true
    }
    func application(_ application: UIApplication, shouldRestoreApplicationState coder: NSCoder) -> Bool {
        return true
    }
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        do {
            let stream = InputStream(url: url)!
            let csv = try! CSVReader(stream: stream, hasHeaderRow: true) 
            openNoteTitle = url.lastPathComponent.replacingOccurrences(of: "-noteline|.csv", with: "", options: .regularExpression)
            while csv.next() != nil {
                let indent = Int(csv["indentation"]!)
                openNote.append(DisplayGroup(indentationLevel: indent ?? 1, item: Item(value: csv["item"]!), hasChildren: Bool(csv["hasChildren"]!) ?? false, done: Bool(csv["done"]!) ?? false, isExpanded: false))
            }
            self.window?.rootViewController!.performSegue(withIdentifier: "openNote", sender: nil)
        } catch {
            print("Unable to load data: \(error)")
        }
        return true
    }
}
extension AppDelegate : JPUSHRegisterDelegate {
    @available(iOS 10.0, *)
    func jpushNotificationCenter(_ center: UNUserNotificationCenter!, willPresent notification: UNNotification!, withCompletionHandler completionHandler: ((Int) -> Void)!) {
        let userInfo = notification.request.content.userInfo
        if notification.request.trigger is UNPushNotificationTrigger {
            JPUSHService.handleRemoteNotification(userInfo)
        }
        completionHandler(Int(UNNotificationPresentationOptions.alert.rawValue))
    }
    @available(iOS 10.0, *)
    func jpushNotificationCenter(_ center: UNUserNotificationCenter!, didReceive response: UNNotificationResponse!, withCompletionHandler completionHandler: (() -> Void)!) {
        let userInfo = response.notification.request.content.userInfo
        if response.notification.request.trigger is UNPushNotificationTrigger {
            JPUSHService.handleRemoteNotification(userInfo)
        }
        completionHandler()
    }
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        JPUSHService.registerDeviceToken(deviceToken)
    }
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) { 
        print("did Fail To Register For Remote Notifications With Error: \(error)")
    }
}
