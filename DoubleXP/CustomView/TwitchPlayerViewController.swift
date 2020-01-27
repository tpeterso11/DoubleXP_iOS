//
//  TwitchPlayerViewController.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 1/26/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//
import UIKit
import TwitchPlayer

public class TwitchPlayerViewController: UIViewController {

    /// `twitchPlayer` is the view that is being used to display a stream, video, or collection in a ViewController.
    @IBOutlet weak var twitchPlayer: TwitchPlayer!
    
    /// `togglePlaybackPress` will toggle the playback of the stream. Activated upon pressing the button with the play
    /// label.
    ///
    /// - Parameter sender: The button labeled with a play button.
    //@IBAction func togglePlaybackPress(_ sender: Any) {
    //    twitchPlayer.togglePlaybackState()
    //}
}
