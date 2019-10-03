import UIKit
import NightNight
import SafariServices
class InfoUIViewControler: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet var versionLabel: UILabel!
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
        let build = Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as! String
        let versionstring = "Version " + version + " (" + build + ")"
        versionLabel.text = versionstring
    }
       override func didReceiveMemoryWarning() {
            super.didReceiveMemoryWarning()
        }
        let contributors = [
            "Sophia Melanie",
            "Liam Duffyer"
        ]
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            switch section {
            case 0:
                return 1
            case 1:
                return contributors.count
            default:
                return 0
            }
        }
        func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
            switch section {
            case 0:
                return "Noteline for iOS is an open source project created by Sophia Melanie and Liam Duffyer"
            case 1:
                return "Thanks to the contributors to Noteline!"
            default:
                return ""
            }
        }
        func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
            if let headerView = view as? UITableViewHeaderFooterView {
                switch section {
                case 0:
                    headerView.textLabel?.text = "Noteline for iOS is an open source project created by Sophia Melanie and Liam Duffyer"
                case 1:
                    headerView.textLabel?.text = "Thanks to the contributors to Noteline!"
                default:
                    headerView.textLabel?.text = ""
                }
            }
        }
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Contributor", for: indexPath) as! SettingTableViewCell
            switch indexPath.section {
            case 0:
                cell.textLabel!.text = "Check out our code on GitHub"
                cell.selectionStyle = UITableViewCell.SelectionStyle.blue
                cell.accessoryType = UITableViewCell.AccessoryType.disclosureIndicator
            case 1:
                cell.textLabel!.text = contributors[indexPath.row]
            default:
                break
            }
            return cell
        }
        func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            if indexPath.section == 0 {
                let cell = self.tableView(tableView, cellForRowAt: indexPath) as! SettingTableViewCell
                let lnk = URL(string: "https://github.com/LiamDuffyer/Noteline")
                self.showDetailViewController(SFSafariViewController(url: lnk!), sender: cell)
            }
        }
        func numberOfSections(in tableView: UITableView) -> Int {
            return 2
        }
    }
