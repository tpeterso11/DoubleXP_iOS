//
//  CallManager.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 1/12/21.
//  Copyright © 2021 Peterson, Toussaint. All rights reserved.
//

import Foundation
//import SendBirdCalls

class CallManager {
    private let accessToken = "44e9e5f770f5151a8738491ac6dd778464f4af8d"
    
    
    /*func initializeCallSDK(currentUser: User){
        SendBirdCall.configure(appId: "B1CA477B-83D6-40D9-A8BB-10C959689426")
        
        let params = AuthenticateParams(userId: currentUser.uId, accessToken: accessToken)
        SendBirdCall.authenticate(with: params) { user, error in
            guard let user = user, error == nil else {
                return
            }
                
            
            print(user.isActive)
        }
    }
    
    func makeCall(directCallDelegate: DirectCallDelegate, callerUid: String){
        let dialParams = DialParams(calleeId: callerUid, isVideoCall: false, callOptions: CallOptions(), customItems: [:])
        let directCall = SendBirdCall.dial(with: dialParams) { directCall, error in
            //
        }
        directCall!.delegate = directCallDelegate
    }*/
    
    
}
