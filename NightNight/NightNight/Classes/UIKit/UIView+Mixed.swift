//
//  UIView+Mixed.swift
//  Pods
//
//  Created by Draveness.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
//  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
//  FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
//  DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
//  SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
//  CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
//  OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
//  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//


import Foundation

public extension UIView {
    
    public var mixedBackgroundColor: MixedColor? {
        get { return getMixedColor(&Keys.backgroundColor) }
        set {
            backgroundColor = newValue?.unfold()
            setMixedColor(&Keys.backgroundColor, value: newValue)
        }
    }
    
    public var mixedTintColor: MixedColor? {
        get { return getMixedColor(&Keys.tintColor) }
        set {
            tintColor = newValue?.unfold()
            setMixedColor(&Keys.tintColor, value: newValue)
        }
    }
    

    override func _updateCurrentStatus() {
        super._updateCurrentStatus()
        
        if let mixedBackgroundColor = mixedBackgroundColor {
            backgroundColor = mixedBackgroundColor.unfold()
        }
        
        if let mixedTintColor = mixedTintColor {
            tintColor = mixedTintColor.unfold()
        }
        
    }
}
