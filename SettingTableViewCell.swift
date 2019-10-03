import Foundation
import UIKit
import MessageUI
class SettingTableViewCell: UITableViewCell {
    var linkURL: URL?
    func initMail(subject: String, to: String) -> MFMailComposeViewController {
        let mailto = MFMailComposeViewController()
        mailto.setSubject(subject)
        mailto.setToRecipients([to])
        let df = DateFormatter()
        let now = Date()
        mailto.setMessageBody("\n\n"+df.string(from: now), isHTML: false)
        return mailto
    }
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        if(selected) {
            super.setSelected(false, animated: animated)
        }
    }
}
