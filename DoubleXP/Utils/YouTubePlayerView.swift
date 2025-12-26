//
//  YouTubePlayerView.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 7/6/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//


import WebKit

final class YouTubePlayerView: UIView, WKScriptMessageHandler {
    private let webView: WKWebView
    
    // MARK: - Playback polling support
    
    enum PlaybackState: String {
        case unstarted = "unstarted"
        case ended     = "ended"
        case playing   = "playing"
        case paused    = "paused"
        case buffering = "buffering"
        case cued      = "cued"
        case unknown   = "unknown"
    }
    
    struct PlaybackSnapshot {
        let state: PlaybackState
        let current: Double?
        let duration: Double?
    }
    
    class TimePollHandle {
        fileprivate var timer: Timer?
        fileprivate init() {}
    }
    
    public var isPlayerReady = false
    private var lastSnapshot: PlaybackSnapshot?
    private var captionsEnabled = false
    private var pollHandle: TimePollHandle?
    var progressUpdateHandler: ((Float) -> Void)?
    
    // ✅ Exposed computed property
    var currentTime: Double? { lastSnapshot?.current }
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        let contentController = WKUserContentController()
        let cfg = WKWebViewConfiguration()
        cfg.allowsInlineMediaPlayback = true
        cfg.mediaTypesRequiringUserActionForPlayback = []
        cfg.userContentController = contentController
        
        webView = WKWebView(frame: .zero, configuration: cfg)
        super.init(frame: frame)
        
        contentController.add(self, name: "playerReady")
        setupWebView()
    }
    
    required init?(coder: NSCoder) {
        let cfg = WKWebViewConfiguration()
        cfg.allowsInlineMediaPlayback = true
        cfg.mediaTypesRequiringUserActionForPlayback = []
        webView = WKWebView(frame: .zero, configuration: cfg)
        super.init(coder: coder)
        setupWebView()
        print("🧩 [YT] init(coder:); allowsInline=\(cfg.allowsInlineMediaPlayback)")
    }
    
    deinit {
        if let handle = pollHandle {
            stopTimePolling(handle)
        }

        webView.configuration.userContentController.removeScriptMessageHandler(forName: "playerReady")
        webView.stopLoading()
        webView.navigationDelegate = nil
        webView.uiDelegate = nil

        NotificationCenter.default.removeObserver(self)

        // Make sure we resign if we were the active player
        YouTubePlaybackCoordinator.shared.resign(self)

        print("🧩 [YT] deinit YouTubePlayerView")
    }
    
    override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)

        // When removed from the window (view popped/dismissed),
        // pause and give up coordinator ownership.
        if newWindow == nil {
            pause()
            YouTubePlaybackCoordinator.shared.resign(self)
        }
    }
    
    private func setupWebView() {
        webView.scrollView.isScrollEnabled = false
        webView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(webView)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: topAnchor),
            webView.bottomAnchor.constraint(equalTo: bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
    }
    
    // MARK: - Load YouTube
    
    /// ✅ Overload with playerVars (fixes 'extra argument' issue)
    func load(videoID: String,
              shouldAutoplay: Bool = false,
              startTime: TimeInterval? = nil,
              playerVars: [String: Any]? = nil) {
        
        YouTubePlaybackCoordinator.shared.claim(self)
        
        var vars = [
            "playsinline": 1,
            "mute": 1,
            "controls": 0,
            "rel": 0,
            "showinfo": 0,
            "modestbranding": 1,
            "iv_load_policy": 3,
            "disablekb": 1,
            "cc_load_policy": captionsEnabled ? 1 : 0,
            "autoplay": shouldAutoplay ? 1 : 0,
            "start": Int(startTime ?? 0)
        ] as [String : Any]
        
        if let custom = playerVars {
            for (k, v) in custom { vars[k] = v }
        }
        
        let varsString = vars.map { key, value in
            "'\(key)': \(jsLiteral(for: value))"
        }.joined(separator: ", ")
        
        let embedHTML = """
        <!DOCTYPE html>
        <html>
          <head>
            <meta name="viewport" content="initial-scale=1, maximum-scale=1">
            <style>
              html, body { margin:0; padding:0; background:#000; height:100%; overflow:hidden; }
              #player { position:absolute; top:0; left:0; width:100%; height:100%; }
            </style>
          </head>
          <body>
            <div id="player"></div>
            <script>
              var tag = document.createElement('script');
              tag.src = "https://www.youtube.com/iframe_api";
              var firstScriptTag = document.getElementsByTagName('script')[0];
              firstScriptTag.parentNode.insertBefore(tag, firstScriptTag);
              
              var player;
              var captionsEnabled = \(captionsEnabled ? "true" : "false");
              
              function onYouTubeIframeAPIReady() {
                player = new YT.Player('player', {
                  height: '100%',
                  width: '100%',
                  videoId: '\(videoID)',
                  playerVars: { \(varsString) },
                  events: { 'onReady': onPlayerReady }
                });
              }
              
              function onPlayerReady(event) {
                try { player.mute(); } catch(e) {}
                try { if (\(shouldAutoplay ? "true" : "false")) player.playVideo(); } catch(e) {}
                window.webkit.messageHandlers.playerReady.postMessage("ready");
              }
              
              // --- Safe getters ---
              function yt_getState() { try { return player ? player.getPlayerState() : null; } catch(e){return null;} }
              function yt_getCurrent() { try { return player ? player.getCurrentTime() : null; } catch(e){return null;} }
              function yt_getDuration() { try { return player ? player.getDuration() : null; } catch(e){return null;} }
              
              // --- Mute helpers ---
              function yt_mute()   { try { if (player) player.mute(); } catch(e){} }
              function yt_unmute() { try { if (player) player.unMute(); } catch(e){} }
              function yt_isMuted(){ try { return player ? player.isMuted() : true; } catch(e){return true;} }
              
              // --- ✅ Captions helper ---
              function yt_setCaptions(enabled) {
                captionsEnabled = enabled;
                try { player.setOption('captions', 'track', enabled ? {} : null); } catch(e){}
              }
            </script>
          </body>
        </html>
        """
        
        isPlayerReady = false
        webView.loadHTMLString(embedHTML, baseURL: URL(string: "http://www.doublexpapp.com"))
        print("🧩 [YT] load(videoID:\(videoID), autoplay:\(shouldAutoplay)) with vars: \(vars)")
    }
    
    /// Loads a video and starts playing from a specific time.
    func loadAndPlay(videoID: String, startTime: TimeInterval) {
        self.load(videoID: videoID, shouldAutoplay: true, startTime: startTime)
    }

    /// Pauses the video and seeks back to a specific time.
    func pauseAndRewind(to time: TimeInterval) {
        self.pause()
        webView.evaluateJavaScript("player.seekTo(\(time), true);", completionHandler: nil)
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "playerReady",
           let messageBody = message.body as? String,
           messageBody == "ready" {
            print("✅ [YT] Player is ready.")
            self.isPlayerReady = true
            // Start polling for progress
            let handle = startTimePolling(interval: 0.25) { [weak self] snapshot in
                guard let self = self,
                      let current = snapshot.current,
                      let duration = snapshot.duration,
                      duration > 0 else { return }
                
                let progress = Float(current / duration)
                self.progressUpdateHandler?(progress)
            }
            self.pollHandle = handle
        }
    }
    
    // MARK: - Playback control
    func play() { webView.evaluateJavaScript("player.playVideo();", completionHandler: nil) }
    func pause() {
        if let handle = pollHandle {
            stopTimePolling(handle)
            pollHandle = nil
        }
        webView.evaluateJavaScript("player.pauseVideo();", completionHandler: nil)
    }
    
    // MARK: - Mute
    func mute() { webView.evaluateJavaScript("yt_mute();", completionHandler: nil) }
    func unmute() { webView.evaluateJavaScript("yt_unmute();", completionHandler: nil) }
    
    func toggleMute() {
        let js = """
        (function(){
          try { return yt_isMuted() ? (yt_unmute(), false) : (yt_mute(), true); }
          catch(e){ return true; }
        })();
        """
        webView.evaluateJavaScript(js) { result, _ in
            if let muted = result as? Bool {
                print("🔁 [YT] toggleMute → \(muted)")
            }
        }
    }
    
    // MARK: - ✅ Captions Control
    func toggleCaptions() {
        captionsEnabled.toggle()
        let js = "yt_setCaptions(\(captionsEnabled ? "true" : "false"));"
        webView.evaluateJavaScript(js, completionHandler: nil)
        print("💬 [YT] captions \(captionsEnabled ? "enabled" : "disabled")")
    }
    
    // MARK: - Polling
    func startTimePolling(interval: TimeInterval,
                          handler: @escaping (PlaybackSnapshot) -> Void) -> TimePollHandle {
        let handle = TimePollHandle()
        let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.samplePlayback(handler: handler)
        }
        handle.timer = timer
        RunLoop.main.add(timer, forMode: .common)
        print("🛰️ [YT] polling every \(interval)s")
        return handle
    }
    
    func stopTimePolling(_ handle: TimePollHandle) {
        handle.timer?.invalidate()
        print("🛰️ [YT] stop polling")
    }
    
    func samplePlayback(handler: @escaping (PlaybackSnapshot) -> Void) {
        let js = """
        (function(){
          var s = yt_getState(); var t = yt_getCurrent(); var d = yt_getDuration();
          return JSON.stringify({state:s, current:t, duration:d});
        })();
        """
        webView.evaluateJavaScript(js) { [weak self] result, error in
            if let error = error {
                print("⚠️ [YT] poll JS error: \(error.localizedDescription)")
                handler(PlaybackSnapshot(state: .unknown, current: nil, duration: nil))
                return
            }
            guard let str = result as? String,
                  let data = str.data(using: .utf8) else {
                handler(PlaybackSnapshot(state: .unknown, current: nil, duration: nil))
                return
            }
            do {
                if let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    let sRaw = obj["state"] as? Int ?? -999
                    let t = obj["current"] as? Double
                    let d = obj["duration"] as? Double
                    let state: PlaybackState
                    switch sRaw {
                        case -1: state = .unstarted
                        case  0: state = .ended
                        case  1: state = .playing
                        case  2: state = .paused
                        case  3: state = .buffering
                        case  5: state = .cued
                        default: state = .unknown
                    }
                    let snapshot = PlaybackSnapshot(state: state, current: t, duration: d)
                    self?.lastSnapshot = snapshot
                    handler(snapshot)
                }
            } catch {
                print("⚠️ [YT] poll decode error: \(error)")
                handler(PlaybackSnapshot(state: .unknown, current: nil, duration: nil))
            }
        }
    }
    
    // MARK: - Compatibility no-ops
    func setVerticalCropBias(_ value: CGFloat) { print("🧩 [YT] setVerticalCropBias \(value)") }
    func setRevealAtSeconds(_ value: Double) { print("🧩 [YT] setRevealAtSeconds \(value)") }
    
    func loadWithDiagnostics(videoID: String, shouldAutoplay: Bool = false, startTime: TimeInterval? = nil, playerVars: [String: Any]? = nil) {
        
        print("🔍 [YouTube] Loading video: \(videoID)")
        print("🔍 [YouTube] Autoplay: \(shouldAutoplay)")
        print("🔍 [YouTube] PlayerVars: \(playerVars ?? [:])")
        
        var vars = [
            "playsinline": 1,
            "mute": 1,
            "controls": 0,
            "rel": 0,
            "showinfo": 0,
            "modestbranding": 1,
            "iv_load_policy": 3,
            "disablekb": 1,
            "cc_load_policy": self.captionsEnabled ? 1 : 0,  // Use self
            "autoplay": shouldAutoplay ? 1 : 0,
            "start": Int(startTime ?? 0)
        ] as [String : Any]
        
        if let custom = playerVars {
            for (k, v) in custom { vars[k] = v }
        }
        
        let varsString = vars.map { "'\($0.key)': \($0.value)" }.joined(separator: ", ")
        
        // ENHANCED HTML WITH ERROR TRACKING
        let embedHTML = """
        <!DOCTYPE html>
        <html>
          <head>
            <meta name="viewport" content="initial-scale=1, maximum-scale=1">
            <style>
              html, body { margin:0; padding:0; background:#000; height:100%; overflow:hidden; }
              #player { position:absolute; top:0; left:0; width:100%; height:100%; }
              #debug { position:absolute; top:10px; left:10px; color:white; font-size:12px; z-index:9999; background:rgba(0,0,0,0.7); padding:10px; max-width:90%; }
            </style>
          </head>
          <body>
            <div id="debug">Loading...</div>
            <div id="player"></div>
            <script>
              function log(msg) {
                console.log(msg);
                document.getElementById('debug').innerHTML += msg + '<br>';
              }
              
              log('Starting YouTube iframe API load...');
              
              var tag = document.createElement('script');
              tag.src = "https://www.youtube.com/iframe_api";
              tag.onerror = function() {
                log('❌ FAILED TO LOAD YOUTUBE API SCRIPT');
              };
              tag.onload = function() {
                log('✅ YouTube API script loaded');
              };
              var firstScriptTag = document.getElementsByTagName('script')[0];
              firstScriptTag.parentNode.insertBefore(tag, firstScriptTag);
              
              var player;
              var captionsEnabled = \(self.captionsEnabled ? "true" : "false");  // Use self
              
              function onYouTubeIframeAPIReady() {
                log('✅ YouTube iframe API ready');
                try {
                  player = new YT.Player('player', {
                    height: '100%',
                    width: '100%',
                    videoId: '\(videoID)',
                    playerVars: { \(varsString) },
                    events: { 
                      'onReady': onPlayerReady,
                      'onError': onPlayerError,
                      'onStateChange': onPlayerStateChange
                    }
                  });
                  log('✅ Player created for video: \(videoID)');
                } catch(e) {
                  log('❌ Error creating player: ' + e.message);
                }
              }
              
              function onPlayerReady(event) {
                log('✅ Player ready callback fired');
                try { 
                  player.mute(); 
                  log('✅ Player muted');
                } catch(e) {
                  log('⚠️ Mute failed: ' + e.message);
                }
                try { 
                  if (\(shouldAutoplay ? "true" : "false")) {
                    player.playVideo();
                    log('✅ Autoplay triggered');
                  }
                } catch(e) {
                  log('⚠️ Autoplay failed: ' + e.message);
                }
                window.webkit.messageHandlers.playerReady.postMessage("ready");
              }
              
              function onPlayerError(event) {
                var errorCode = event.data;
                var errorMsg = '';
                switch(errorCode) {
                  case 2: errorMsg = 'Invalid video ID'; break;
                  case 5: errorMsg = 'HTML5 player error'; break;
                  case 100: errorMsg = 'Video not found or private'; break;
                  case 101: errorMsg = 'Video embedding not allowed by owner'; break;
                  case 150: errorMsg = 'Video embedding not allowed by owner (same as 101)'; break;
                  default: errorMsg = 'Unknown error';
                }
                log('❌ YOUTUBE ERROR ' + errorCode + ': ' + errorMsg);
                log('Video ID: \(videoID)');
              }
              
              function onPlayerStateChange(event) {
                var stateName = '';
                switch(event.data) {
                  case -1: stateName = 'unstarted'; break;
                  case 0: stateName = 'ended'; break;
                  case 1: stateName = 'playing'; break;
                  case 2: stateName = 'paused'; break;
                  case 3: stateName = 'buffering'; break;
                  case 5: stateName = 'cued'; break;
                }
                log('State change: ' + stateName);
              }
              
              // --- Safe getters ---
              function yt_getState() { try { return player ? player.getPlayerState() : null; } catch(e){return null;} }
              function yt_getCurrent() { try { return player ? player.getCurrentTime() : null; } catch(e){return null;} }
              function yt_getDuration() { try { return player ? player.getDuration() : null; } catch(e){return null;} }
              
              // --- Mute helpers ---
              function yt_mute()   { try { if (player) player.mute(); } catch(e){} }
              function yt_unmute() { try { if (player) player.unMute(); } catch(e){} }
              function yt_isMuted(){ try { return player ? player.isMuted() : true; } catch(e){return true;} }
              
              // --- Captions helper ---
              function yt_setCaptions(enabled) {
                captionsEnabled = enabled;
                try { player.setOption('captions', 'track', enabled ? {} : null); } catch(e){}
              }
            </script>
          </body>
        </html>
        """
        
        isPlayerReady = false
        self.webView.loadHTMLString(embedHTML, baseURL: URL(string: "http://www.doublexpapp.com")) // Use self
        print("🧩 [YT] loadWithDiagnostics(videoID:\(videoID), autoplay:\(shouldAutoplay)) with vars: \(vars)")
    }
    
    func seekTo(_ time: Double) {
         webView.evaluateJavaScript("player.seekTo(\(time), true);", completionHandler: nil)
     }
    
    private func jsLiteral(for value: Any) -> String {
        switch value {
        case let b as Bool:
            return b ? "true" : "false"
        case let i as Int:
            return "\(i)"
        case let d as Double:
            return "\(d)"
        case let s as String:
            // Escape single quotes
            let escaped = s.replacingOccurrences(of: "'", with: "\\'")
            return "'\(escaped)'"
        default:
            let str = String(describing: value)
            let escaped = str.replacingOccurrences(of: "'", with: "\\'")
            return "'\(escaped)'"
        }
    }
}
