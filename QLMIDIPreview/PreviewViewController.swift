//  QLMIDIPreviewViewController
//
//  View controller for the QLMIDI preview
//
//  This is the main view controller for the QLMIDI preview. The view controller initializes the content
//  shown in the preview. This file also has references to various elements in PreviewViewController.xib,
//  declaring their types and containing all of their logic and variables.
//
//  QLMIDI presents its preview view in two different states, embedded and popout. The elements of both
//  are contained in PreviewViewController.xib, and shown or hidden depending on the state of the view.
//  The view is assumed to be embedded by default when it is initialized in preparePreviewOfFile(), and
//  changes to the popout state when an observer is notified of a change in view.window.level.

import Cocoa
import Quartz
import AVFoundation


// This image cell serves as a box whose width adjusts with the window's width. The value is used in draw().
class CustomImageCell: NSImageCell {
    // Overrides draw() to be able to call NSBezierPath() to draw a rectangle with up to date NSRect.width
    override func draw(withFrame cellFrame: NSRect, in controlView: NSView) {
        super.draw(withFrame: cellFrame, in: controlView)
        let drawRect = NSRect(x: 0, y: 1, width: cellFrame.width, height: 31)
        NSColor(named: NSColor.Name("controlBarColor"))!.setFill()
        NSBezierPath(roundedRect: drawRect, xRadius: 8, yRadius: 8).fill()
    }
}

class PreviewViewController: NSViewController, QLPreviewingController {
    
    
    override var nibName: NSNib.Name? { return NSNib.Name("PreviewViewController") }
    override var preferredContentSize: NSSize { get { return NSMakeSize(565, 266) } set {} }
    
    var midiPlayer: AVMIDIPlayer!
    var updateTimer: Timer!
    var windowLevelObservation: NSKeyValueObservation?
    
    var viewHasSetup: Bool = false // True if setupPopoutView() has already been called.
    var playerIsPlaying: Bool = true // Keeps track of whether the player should automatically play in situations where the user has interacted with the controls.
    var compactControls: Bool = false // Prevents changes in view.frame.width from triggering code multiple times in updateDisplay().
    
    var fileURL: URL?
    let skipInterval: Double = 15.00
    var fileName: String?
    var durationLabelString: NSAttributedString?
    var timeElapsedLabelString: NSAttributedString?
    let timeLabelAttributes: [NSAttributedString.Key: Any] = [.foregroundColor: NSColor(named: NSColor.Name("timeLabelColor"))!, .font: NSFont.monospacedDigitSystemFont(ofSize: 12, weight: NSFont.Weight.regular)]
    
    let savePositionOfLastPreview: Bool = true // Make this into a setting. The user can select whether to save the position in the last preview.
    let automaticallyPlayPreview: Bool = true // Make this into a setting.
    
    
    @IBOutlet weak var playButton: NSButton!
    @IBOutlet weak var skipBackButton: NSButton!
    @IBOutlet weak var skipForwardButton: NSButton!
    @IBOutlet weak var progressSliderCell: QLMIDIProgressSlider!
    @IBOutlet weak var progressSlider: NSSlider!
    @IBOutlet weak var timeElapsedLabel: NSTextField!
    @IBOutlet weak var durationLabel: NSTextField!
    @IBOutlet weak var barRect: NSImageView!
    @IBOutlet weak var barRectCell: CustomImageCell! // This image cell serves as a box whose width adjusts with the window's width. This value is used in CustomImageCell.draw().
    @IBOutlet weak var embeddedImage: NSImageView!
    @IBOutlet weak var viewImage: NSImageView!
    @IBOutlet weak var titleLabel: NSTextField!
    
    @IBOutlet weak var sliderLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var playButtonLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var skipForwardButtonLeadingConstraint: NSLayoutConstraint!
    @IBOutlet var titleTrailingConstraint: NSLayoutConstraint!
    @IBOutlet var unembeddedImageLeadingConstraint: NSLayoutConstraint!
    
    
    // Handles the press of the play button, toggling its state and resetting playback if pressed when the preview is finished.
    @IBAction func playToggle(_ sender: Any) {
        if midiPlayer.isPlaying {
            midiPlayer.stop()
            playerIsPlaying = false
        } else {
            midiPlayer.play()
            playerIsPlaying = true
        }
        
        if midiPlayer.currentPosition >= midiPlayer.duration {
            playButton.state = NSControl.StateValue.on
            midiPlayer.currentPosition = 0
            midiPlayer.play()
        }
    }
    
    @IBAction func sliderClick(_ sender: Any) {
        midiPlayer.currentPosition = progressSliderCell.doubleValue
        if playerIsPlaying {
            playButton.state = NSControl.StateValue.on
            midiPlayer.play()
        }
    }
    
    @IBAction func skipBackClick(_ sender: Any) {
        let skipPosition = midiPlayer.currentPosition - skipInterval
        if skipPosition >= 0 {
            midiPlayer.currentPosition = skipPosition
        } else {
            midiPlayer.currentPosition = 0
        }
    }
    
    @IBAction func skipForwardClick(_ sender: Any) {
        let skipPosition = midiPlayer.currentPosition + skipInterval
        if skipPosition <= midiPlayer.duration {
            midiPlayer.currentPosition = skipPosition
        } else {
            midiPlayer.currentPosition = midiPlayer.duration
        }
    }
    
    // Contains the initialization code for the preview view.
    func preparePreviewOfFile(at url: URL, completionHandler handler: @escaping (Error?) -> Void) {
        
        setupEmbeddedView()
        fileURL = url
        
        // Creates an observer that receives a notification when the window level variable changes. Level is 0 when the window is in the background and 3 when it is in focus, and is never 3 when the view is embedded in Finder.
        windowLevelObservation = observe(\.self.view.window!.level, options: [.old, .new]) { object, change in
            if change.oldValue != nil && change.newValue != nil {
                if change.newValue!.rawValue == 0 {
                    if self.midiPlayer != nil { self.midiPlayer.stop() }
                    self.playButton.state = NSControl.StateValue.off
                    if self.savePositionOfLastPreview == false {
                        self.midiPlayer.currentPosition = TimeInterval(0)
                    }
                }
                if change.newValue!.rawValue == 3 && self.playerIsPlaying == true {
                    // Because the window level always starts at 0 and changes to 3 when a popout window is created, call setupPopoutView() on the first change.
                    if self.viewHasSetup == false {
                        self.setupPopoutView()
                        self.viewHasSetup = true
                    }
                    self.midiPlayer.play()
                    self.playButton.state=NSControl.StateValue.on
                }
            }
        }
        
        // Call the completion handler to signal that the preview is available.
        handler(nil)
    }
    
    // Hides popout view elements.
    func setupEmbeddedView() {
        playButton.isHidden = true
        skipForwardButton.isHidden = true
        skipBackButton.isHidden = true
        progressSlider.isHidden = true
        timeElapsedLabel.isHidden = true
        durationLabel.isHidden = true
        barRect.isHidden = true
        viewImage.isHidden = true
        titleLabel.isHidden = true
        
        titleTrailingConstraint.isActive = false
        unembeddedImageLeadingConstraint.isActive = false
    }
    
    // Unhides popout view elements and further initializes the view.
    func setupPopoutView() {
        // Initializes the MIDI player.
        do {
            midiPlayer = try AVMIDIPlayer.init(contentsOf: fileURL!, soundBankURL: nil)
        } catch {
            NSLog ("Failed to initialize midi player")
        }
        
        // Initializes a repeating timer that calls updateDisplay().
        updateTimer = Timer.scheduledTimer(timeInterval: 0.0167, target: self, selector: #selector(self.updateDisplay), userInfo: nil, repeats: true)
        
        // Starts playing
        midiPlayer.play()
        self.playButton.state=NSControl.StateValue.on
        progressSliderCell.maxValue = Double(midiPlayer.duration)
        
        // Hides the image shown by the embedded view and unhides popout view elements
        embeddedImage.isHidden = true
        playButton.isHidden = false
        skipForwardButton.isHidden = false
        skipBackButton.isHidden = false
        progressSlider.isHidden = false
        timeElapsedLabel.isHidden = false
        durationLabel.isHidden = false
        barRect.isHidden = false
        viewImage.isHidden = false
        titleLabel.isHidden = false
        titleTrailingConstraint.isActive = true
        unembeddedImageLeadingConstraint.isActive = true
        
        // Sets up the label containing the file's name and duration.
        let durationString: String = getTimeString(timeValue: midiPlayer.duration)
        durationLabelString = NSAttributedString(string: durationString, attributes: timeLabelAttributes)
        durationLabel.attributedStringValue = durationLabelString!
        
        let titleAttributes: [NSAttributedString.Key: Any] = [.foregroundColor: NSColor.labelColor, .font: NSFont.systemFont(ofSize: 22, weight: NSFont.Weight.semibold)]
        let newlineAttributes: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 6.72)]
        let timeAttributes: [NSAttributedString.Key: Any] = [.foregroundColor: NSColor.secondaryLabelColor, .font: NSFont.systemFont(ofSize: 16, weight: NSFont.Weight.light)]
        let durationAttributes: [NSAttributedString.Key: Any] = [.foregroundColor: NSColor.secondaryLabelColor, .font: NSFont.systemFont(ofSize: 16, weight: NSFont.Weight.semibold)]
        
        let fileName: String = (fileURL!.lastPathComponent)
        let titleString = "\(fileName.dropLast(4))"
        let newlineString = "\n\n"
        let timeString = "Time: "
        let title = NSMutableAttributedString(string: titleString, attributes: titleAttributes)
        let newline = NSMutableAttributedString(string: newlineString, attributes: newlineAttributes)
        let time = NSMutableAttributedString(string: timeString, attributes: timeAttributes)
        let duration = NSMutableAttributedString(string: durationString, attributes: durationAttributes)
        title.append(newline)
        title.append(time)
        title.append(duration)
        titleLabel.attributedStringValue = title
    }
    
    // Deinitializes the timer to free resources.
    override func viewWillDisappear() {
        if updateTimer != nil { updateTimer.invalidate() }
        super.viewWillDisappear()
    }
    
    // Converts the player's time & duration Double values to seconds, minutes and hours.
    func getTimeString(timeValue: Double) -> String {
        let rawValue: Int = Int(timeValue)
        var seconds: Int = rawValue
        var minutes: Int = seconds / 60
        let hours: Int = minutes / 60
        seconds = rawValue - minutes * 60
        minutes = rawValue / 60 - hours * 60
        
        var timeString: String = "00:00:00"
        
        var secondsString: String = "00"
        var minutesString: String = "00"
        var hoursString: String = "00"
        
        if seconds < 10 {
            secondsString = "0\(seconds)"
        } else {
            secondsString = "\(seconds)"
        }
        
        if minutes < 10 {
            minutesString = "0\(minutes)"
        } else {
            minutesString = "\(minutes)"
        }
        
        if hours < 10 {
            hoursString = "0\(hours)"
        } else {
            hoursString = "\(hours)"
        }
        
        if hours > 1{
            if hours < 10 {
                hoursString = "0\(hours)"
            } else {
                hoursString = "\(hours)"
            }
            timeString = "\(hoursString):\(minutesString):\(secondsString)"
        } else {
            timeString = "\(minutesString):\(secondsString)"
        }
        return timeString
    }
    
    @objc func updateDisplay() {
        progressSliderCell.doubleValue = Double((midiPlayer.currentPosition))
        
        timeElapsedLabelString = NSAttributedString(string: getTimeString(timeValue: progressSliderCell.doubleValue), attributes: timeLabelAttributes)
        timeElapsedLabel.attributedStringValue = timeElapsedLabelString!
        
        // Hide the skip buttons when the window is resized down
        if view.frame.width < 565 && compactControls == false {
            skipForwardButton.isEnabled = false
            skipBackButton.isEnabled = false
            sliderLeadingConstraint.constant = 96.5
            playButtonLeadingConstraint.constant = 20.5
            skipForwardButtonLeadingConstraint.constant = 20.5
            
            collapseAnimation()
            
            compactControls = true // Set this to true so that the program won't execute this code again even though width is less than 565
        }
        
        // Unhide the skip buttons when the window is resized up
        if view.frame.width >= 565 && compactControls == true {
            skipForwardButton.isEnabled = true
            skipBackButton.isEnabled = true
            sliderLeadingConstraint.constant = 171
            playButtonLeadingConstraint.constant = 57
            skipForwardButtonLeadingConstraint.constant = 92
            
            expandAnimation()
            
            compactControls = false // Set this to false so that the program won't execute this code again even though width is greater than 565
        }
        
        if midiPlayer.currentPosition >= midiPlayer.duration {
            playButton.state = NSControl.StateValue.off
            midiPlayer.stop()
        }
    }
    
    // Animates the toolbar collapsing
    func collapseAnimation() {
        NSAnimationContext.runAnimationGroup({ (context) in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
            
            skipBackButton.animator().alphaValue = 0.0
            skipForwardButton.animator().alphaValue = 0.0
            
            progressSlider.animator().setFrameOrigin(NSMakePoint(1, 1))
            timeElapsedLabel.animator().setFrameOrigin(NSMakePoint(1, 1))
            skipForwardButton.animator().setFrameOrigin(NSMakePoint(1, 1))
            playButton.animator().setFrameOrigin(NSMakePoint(1, 1))
        })
    }
    
    // Animates the tool bar expanding
    func expandAnimation() {
        NSAnimationContext.runAnimationGroup({ (context) in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
            
            skipBackButton.animator().alphaValue = 1.0
            skipForwardButton.animator().alphaValue = 1.0
            
            progressSlider.animator().setFrameOrigin(NSMakePoint(100, 100))
            timeElapsedLabel.animator().setFrameOrigin(NSMakePoint(100, 100))
            skipForwardButton.animator().setFrameOrigin(NSMakePoint(100, 100))
            playButton.animator().setFrameOrigin(NSMakePoint(100, 100))
        })
    }
}
