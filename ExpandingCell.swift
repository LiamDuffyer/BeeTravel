import UIKit
import NightNight
class ExpandingCell: UITableViewCell {
    @IBOutlet weak var textView: UITextView!
    override func layoutSubviews() {
        super.layoutSubviews()
        textView.mixedBackgroundColor = MixedColor(normal: 0xffffff, night: 0x263238)
    }
}
