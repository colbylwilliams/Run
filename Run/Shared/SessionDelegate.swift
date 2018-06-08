//
//  SessionDelegate.swift
//  Run
//
//  Created by Colby L Williams on 6/7/18.
//  Copyright © 2018 Colby L Williams. All rights reserved.
//

import Foundation
import WatchConnectivity

class SessionDelegate: NSObject, WCSessionDelegate {
    
    // Called when the session has completed activation.
    // If session state is WCSessionActivationStateNotActivated there will be an error with more details.
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        
    }
    
    
    /** ------------------------- iOS App State For Watch ------------------------ */
    
    // Called when the session can no longer be used to modify or add any new transfers and,
    // all interactive messages will be cancelled, but delegate callbacks for background transfers can still occur.
    // This will happen when the selected watch is being changed.
    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {
        
    }
    
    
    // Called when all delegate callbacks for the previously selected watch has occurred.
    // The session can be re-activated for the now selected watch using activateSession.
    func sessionDidDeactivate(_ session: WCSession) {
        
    }
    
    
    // Called when any of the Watch state properties change.
    func sessionWatchStateDidChange(_ session: WCSession) {
        
    }
    #endif
    
    /** ------------------------- Interactive Messaging ------------------------- */
    
    // Called when the reachable state of the counterpart app changes.
    // The receiver should check the reachable property on receiving this delegate callback.
    func sessionReachabilityDidChange(_ session: WCSession) {
        
    }
    
    
    // Called on the delegate of the receiver. Will be called on startup if the incoming message caused the receiver to launch.
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        
    }
    
    
    // Called on the delegate of the receiver when the sender sends a message that expects a reply.
    // Will be called on startup if the incoming message caused the receiver to launch.
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        
    }
    
    
    // Called on the delegate of the receiver. Will be called on startup if the incoming message data caused the receiver to launch.
    func session(_ session: WCSession, didReceiveMessageData messageData: Data) {
        
    }
    
    
    // Called on the delegate of the receiver when the sender sends message data that expects a reply.
    // Will be called on startup if the incoming message data caused the receiver to launch.
    func session(_ session: WCSession, didReceiveMessageData messageData: Data, replyHandler: @escaping (Data) -> Void) {
        
    }
    
    
    /** -------------------------- Background Transfers ------------------------- */
    
    // Called on the delegate of the receiver. Will be called on startup if an applicationContext is available.
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        
    }
    
    
    // Called on the sending side after the user info transfer has successfully completed or failed with an error.
    // Will be called on next launch if the sender was not running when the user info finished.
    func session(_ session: WCSession, didFinish userInfoTransfer: WCSessionUserInfoTransfer, error: Error?) {
        
    }
    
    
    // Called on the delegate of the receiver. Will be called on startup if the user info
    // finished transferring when the receiver was not running.
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        
    }
    
    
    // Called on the sending side after the file transfer has successfully completed or failed with an error.
    // Will be called on next launch if the sender was not running when the transfer finished.
    func session(_ session: WCSession, didFinish fileTransfer: WCSessionFileTransfer, error: Error?) {
        
    }
    
    
    // Called on the delegate of the receiver. Will be called on startup if the file finished
    // transferring when the receiver was not running. The incoming file will be located in the Documents/Inbox/
    // folder when being delivered. The receiver must take ownership of the file by moving it to another location.
    // The system will remove any content that has not been moved when this delegate method returns.
    func session(_ session: WCSession, didReceive file: WCSessionFile) {
        
    }
}

