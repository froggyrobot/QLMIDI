//  QLMIDIProgressSlider
//
//  Slider used to control MIDI playback
//
//  The NSSlider is a default slider provided by Cocoa, which contains an NSSliderCell. A custom NSSliderCell
//  is needed to change the appearance or the slider. The appearance of both the slider and the slider's knob
//  are customized in the overrides of drawKnob(), knobRect() and drawBar().

import Cocoa


class QLMIDIProgressSlider: NSSliderCell {
    
    // Sets the color and calls NSBezierPath() to draw the slider's knob.
    override func drawKnob(_ knobRect: NSRect) {
        
        var knob = NSRect(x: 0.0, y: 0.0, width: 3, height: 15.0)

        knob.origin.x = knobRect.origin.x + (knobRect.size.width - knob.size.width) / 2
        knob.origin.y = knobRect.origin.y + (knobRect.size.height - knob.size.height) / 2 - 2
        NSColor.white.setFill()
        NSBezierPath.init(roundedRect: knob, xRadius: 1.5, yRadius: 1.5).fill()
    }
    
    // Determines the size and x, y coordinates of the slider's knob.
    override func knobRect(flipped: Bool) -> NSRect{
        let superRect = super.knobRect(flipped:false)
        
        return NSRect(x: superRect.origin.x, y: 5, width: superRect.width, height: 18)
    }
    
    // Sets the color and calls NSBezierPath() to draw the slider's bar. Both the backround (trackBar) and fill
    // (fillBar) colors and NSBezierPath() calls are handled in this function.
    override func drawBar(inside drawBarRect: NSRect, flipped: Bool) {
        var trackBar = drawBarRect
        trackBar.size.height = CGFloat(3)
        
        let knob = knobRect(flipped:false)
        trackBar.origin.x += (knob.size.width - 5) / 2
        trackBar.size.width -= (knob.size.width - 5)
                
        let knobRect = knobRect(flipped:false)
        
        var fillBar = trackBar
        fillBar.origin.x = fillBar.origin.x /*+ 2*/
        fillBar.size.width =  knobRect.origin.x - 2.3
        
        var emptyBar = trackBar
        emptyBar.origin.x = knobRect.origin.x + 14.7
        emptyBar.size.width = (trackBar.size.width - knobRect.origin.x) - 3.2
        
        var leftCircle = trackBar
        leftCircle.size.width = 4
        leftCircle.origin.x -= 2
        
        var rightCircle = trackBar
        rightCircle.size.width = 4
        rightCircle.origin.x = trackBar.maxX - 2
                
        let cornerRadius = 1.5
        
        NSColor(named: NSColor.Name("fillBarColor"))!.setFill()
        NSBezierPath(roundedRect: fillBar, xRadius: 0, yRadius: 0).fill()
        NSBezierPath(roundedRect: leftCircle, xRadius: cornerRadius, yRadius: cornerRadius).fill()
        
        NSColor(named: NSColor.Name("emptyBarColor"))!.setFill()
        NSBezierPath(roundedRect: emptyBar, xRadius: 0, yRadius: 0).fill()
        NSBezierPath(roundedRect: rightCircle, xRadius: cornerRadius, yRadius: cornerRadius).fill()
        
        
    }
}
