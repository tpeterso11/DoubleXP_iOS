//
//  AppDelegate.swift
//  DoubleXP
//
//  Created by Peterson, Toussaint on 2/2/19.
//  Copyright © 2019 Peterson, Toussaint. All rights reserved.
//

import UIKit
import CoreData
import Firebase
import FBSDKCoreKit
import GoogleSignIn

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, MessagingDelegate {

    var window: UIWindow?
    var appProperties: NSDictionary = [:]
    var gcGames: [GamerConnectGame]!
    var freeAgentProfiles: [FreeAgentObject]!
    var selectedGCGame: GamerConnectGame?
    var currentUser: User?
    var currentLanding: LandingActivity?
    var currentMediaFrag: MediaFrag?
    var currentProfileFrag: PlayerProfile?
    var currentFrag: String = ""
    var interviewManager = InterviewManager()
    var mediaManager = MediaManager()
    var socialMediaManager = SocialMediaManager()
    var navStack = KeepOrderDictionary<String, ParentVC>() //pageNames
    var mediaCache = MediaCache()
    var twitchChannels = [TwitchChannelObj]()
    var competitions = [CompetitionObj]()
    var announcementManager = AnnouncementManager()
    var imageCache = NSCache<NSString, UIImage>()
    
    private var apnsToken: String = ""
    private var fcmToken: String = ""

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        gcGames = [GamerConnectGame]()
        freeAgentProfiles = [FreeAgentObject]()
        // Override point for customization after application launch.
        
        FirebaseApp.configure()
        GIDSignIn.sharedInstance().clientID = FirebaseApp.app()?.options.clientID
        
        Messaging.messaging().delegate = self
        
        TwitterHelper.shared.start(withConsumerKey: "sEWJZFZjZAIaxwZUrzdd2JPeI", consumerSecret: "K2yk5yy8AHmyC4mMFHecB1WBoowFnf4uMs4ET7zEjFe06hWmCm")
        
        if #available(iOS 10.0, *) {
          // For iOS 10 display notification (sent via APNS)
            UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate

            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(
                options: authOptions,
                completionHandler: {_, _ in })
            }
            else {
                    let settings: UIUserNotificationSettings =
                    UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
                    application.registerUserNotificationSettings(settings)
        }

        application.registerForRemoteNotifications()
        
        getToken()

        return true
    }
    
    @available(iOS 9.0, *)
    func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any])
      -> Bool {
      return GIDSignIn.sharedInstance().handle(url)
    }
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        return GIDSignIn.sharedInstance().handle(url)
    }
    
    func addToNavStack(vc: ParentVC){
        self.navStack[vc.pageName!] = vc
        print(self.navStack.count)
    }
    
    func clearAndAddToNavStack(vc: ParentVC){
        self.navStack = KeepOrderDictionary<String, ParentVC>()
        self.navStack[vc.pageName!] = vc
        
        self.currentLanding?.stackDepth = self.navStack.count
    }
    
    func resetStack(vc: ParentVC){
        let homeController = GamerConnectFrag()
        homeController.pageName = "Home"
        homeController.navDictionary = ["state": "original"]
        
        self.navStack = KeepOrderDictionary<String, ParentVC>()
        self.navStack["Home"] = homeController
        self.navStack[vc.pageName!] = vc
    }
    
    private func rebuildNavStack(vc: ParentVC){
        let homeController = GamerConnectFrag()
        
        switch(vc.pageName){
        case "Home":
            self.navStack[vc.pageName!] = vc
        case "View Teams":
            self.navStack = KeepOrderDictionary<String, ParentVC>()
            self.navStack["Home"] = GamerConnectFrag()
            self.navStack["Team"] = TeamFrag()
            self.navStack[vc.pageName!] = vc
            break
        default:
            print("none")
            //self.navStack = KeepOrderDictionary<String, ParentVC>()
        }
    }
    
    func handleToken(){
        if(currentUser != nil){
            if(currentUser!.notifications == "false"){
                self.fcmToken = ""
            }
            
            guard !self.fcmToken.isEmpty else{
                return
            }
            
            let ref = Database.database().reference().child("Users").child(currentUser!.uId)
            ref.child("fcmToken").setValue(self.fcmToken)
        }
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
        UIApplication.shared.applicationIconBadgeNumber = 0
        
        AppEvents.activateApp()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        self.saveContext()
    }

    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentContainer(name: "DoubleXP")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    func getToken(){
        InstanceID.instanceID().instanceID { (result, error) in
          if let error = error {
            print("Error fetching remote instance ID: \(error)")
          } else if let result = result {
            print("Remote instance ID token: \(result.token)")
            
            //self.instanceIDTokenMessage.text  = "Remote InstanceID token: \(result.token)"
          }
        }
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        // If you are receiving a notification message while your app is in the background,
        // this callback will not be fired till the user taps on the notification launching the application.
        // TODO: Handle data of notification
        // With swizzling disabled you must let Messaging know about the message, for Analytics
         Messaging.messaging().appDidReceiveMessage(userInfo)
        // Print message ID.
        //if let messageID = userInfo[gcmMessageIDKey] {
       //     print("Message ID: \(messageID)")
        //}

        // Print full message.
        print(userInfo)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // If you are receiving a notification message while your app is in the background,
        // this callback will not be fired till the user taps on the notification launching the application.
        // TODO: Handle data of notification
        // With swizzling disabled you must let Messaging know about the message, for Analytics
         Messaging.messaging().appDidReceiveMessage(userInfo)
        // Print message ID.
        //if let messageID = userInfo[gcmMessageIDKey] {
        //    print("Message ID: \(messageID)")
        //}

        // Print full message.
        print(userInfo)

        completionHandler(UIBackgroundFetchResult.newData)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Unable to register for remote notifications: \(error.localizedDescription)")
    }
    
    func messaging(_ messaging: Messaging, didReceive remoteMessage: MessagingRemoteMessage) {
        print("Received data message: \(remoteMessage.appData)")

    }
    // [END ios_10_data_message]

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        print("Firebase registration token: \(fcmToken)")

        // TODO: If necessary send token to application server.
        // Note: This callback is fired at each app startup and whenever a new token is generated.
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        //  Register.
        let deviceTokenString = deviceToken.reduce("", {$0 + String(format: "%02X", $1)})
        print("deviceTokenString: \(deviceTokenString)")
        self.apnsToken = deviceTokenString

        //set apns token in messaging
        Messaging.messaging().apnsToken = deviceToken

        //get FCM token
        if let token = Messaging.messaging().fcmToken {
            self.fcmToken = token
            print("FCM token: \(token)")
        }

        //subscribe to topic to send message to multiple device
        //self.subscribeToTopic()
    }
    
    /*func application(
      _ application: UIApplication,
      continue userActivity: NSUserActivity,
      restorationHandler: @escaping ([UIUserActivityRestoring]?
    ) -> Void) -> Bool {
      
      // 1
      guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
        let url = userActivity.webpageURL,
        let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
          return false
      }
      
      // 2
      if let computer = ItemHandler.sharedInstance.items
        .filter({ $0.path == components.path}).first {
        presentDetailViewController(computer)
        return true
      }
      
      // 3
      if let webpageUrl = URL(string: "http://rw-universal-links-final.herokuapp.com") {
        application.open(webpageUrl)
        return false
      }
      
      return false
    }*/
}

/*func presentDetailViewController(_ computer: Computer) {
  let storyboard = UIStoryboard(name: "Main", bundle: nil)
  
  guard
    let detailVC = storyboard
      .instantiateViewController(withIdentifier: "DetailController")
        as? ComputerDetailController,
    let navigationVC = storyboard
      .instantiateViewController(withIdentifier: "NavigationController")
        as? UINavigationController
  else { return }
  
  detailVC.item = computer
  navigationVC.modalPresentationStyle = .formSheet
  navigationVC.pushViewController(detailVC, animated: true)
}*/

public struct KeepOrderDictionary<Key, Value> where Key : Hashable
{
    public private(set) var values: [Value]

    fileprivate var keyToIndexMap: [Key:Int]
    fileprivate var indexToKeyMap: [Int:Key]

    public init()
    {
        self.values = [Value]()
        self.keyToIndexMap = [Key:Int]()
        self.indexToKeyMap = [Int:Key]()
    }

    public var count: Int
    {   return values.count}

    public mutating func add(key: Key, _ value: Value)
    {
        if let index = keyToIndexMap[key]
        {   values[index] = value}
        else
        {
            values.append(value)
            keyToIndexMap[key] = values.count - 1
            indexToKeyMap[values.count - 1] = key
        }
    }

    public mutating func add(index: Int, _ value: Value) -> Bool
    {
        if let key = indexToKeyMap[index]
        {
            add(key: key, value)
            return true
        }

        return false
    }

    public func get(key: Key) -> (Key, Value)?
    {
        if let index = keyToIndexMap[key]
        {   return (key, values[index])}

        return nil
    }

    public func get(index: Int) -> (Key, Value)?
    {
        if let key = indexToKeyMap[index]
        {   return (key, values[index])}

        return nil
    }

    public mutating func removeValue(forKey key: Key) -> Bool
    {
        guard let index = keyToIndexMap[key] else
        {   return false}

        values.remove(at: index)

        keyToIndexMap.removeValue(forKey: key)
        indexToKeyMap.removeValue(forKey: index)

        return true
    }

    public mutating func removeValue(at index: Int) -> Bool
    {
        guard let key = indexToKeyMap[index] else
        {   return false}

        values.remove(at: index)

        keyToIndexMap.removeValue(forKey: key)
        indexToKeyMap.removeValue(forKey: index)

        return true
    }
}

extension KeepOrderDictionary
{
    public subscript(key: Key) -> Value?
        {
        get
        {   return get(key: key)?.1}

        set
        {
            if let newValue = newValue
            {   add(key: key, newValue)}
            else
            {   let _ = removeValue(forKey: key)}
        }
    }

    public subscript(index: Int) -> Value?
        {
        get
        {   return get(index: index)?.1}

        set
        {
            if let newValue = newValue
            {   let _ = add(index: index, newValue)}
        }
    }
}

extension KeepOrderDictionary : ExpressibleByDictionaryLiteral
{
    public init(dictionaryLiteral elements: (Key, Value)...)
    {
        self.init()
        for entry in elements
        {   add(key: entry.0, entry.1)}
    }
}

extension KeepOrderDictionary : Sequence
{
    public typealias Iterator = IndexingIterator<[(key: Key, value: Value)]>

    public func makeIterator() -> KeepOrderDictionary.Iterator
    {
        var content = [(key: Key, value: Value)]()

        for i in 0 ..< count
        {
            if let value: Value = self[i], let key: Key = indexToKeyMap[i]
            {     content.append((key: key, value: value))}
        }

        return content.makeIterator()
    }
}
