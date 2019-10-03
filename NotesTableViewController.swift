import Foundation
import UIKit
import CoreData
import CloudKit
import CloudCore
import LongPressReorder
import Floaty
import NightNight
import CoreLocation
var notes =  [[Any]]()
var selectedID : Any?
var template = [Any]()
var templates = [[Any]]()
var addButtonView : UIView?
class NotesTableViewController: UITableViewController, NSFetchedResultsControllerDelegate {
    var reorderTableView: LongPressReorderTableView!
    let floaty = Floaty()
    let context = persistentContainer.viewContext
    var locationManager:CLLocationManager = CLLocationManager.init()
    var locationCurrent:CLLocation = CLLocation.init()
    var Weather2D:CLLocationCoordinate2D = CLLocationCoordinate2D.init()
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.delegate = self
       if(CLLocationManager.authorizationStatus() != .authorizedWhenInUse)
       {
           locationManager.requestWhenInUseAuthorization()
       }
       locationManager.distanceFilter = kCLDistanceFilterNone
       locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
       locationManager.startUpdatingLocation()
        self.tableView.mixedBackgroundColor = MixedColor(normal: 0xffffff, night: 0x263238)
        let tap = UITapGestureRecognizer(target: self, action: #selector(doubleTapped))
        tap.numberOfTapsRequired = 2
        self.navigationController?.navigationBar.addGestureRecognizer(tap)
        self.navigationController?.navigationBar.mixedBarTintColor = MixedColor(normal: 0xffffff, night: 0x263238)
        let infoButton = UIButton()
        infoButton.setImage(#imageLiteral(resourceName: "info").withRenderingMode(.alwaysOriginal), for: .normal)
        infoButton.frame = CGRect(x: 0, y: 0, width: 28, height: 28)
        infoButton.imageView?.contentMode = .scaleAspectFit
        infoButton.imageEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 0)
        infoButton.addTarget(self, action: #selector(showInfo), for: .touchUpInside)
        let weatherButton = UIButton()
        weatherButton.setImage(#imageLiteral(resourceName: "weather").withRenderingMode(.alwaysOriginal), for: .normal)
        weatherButton.frame = CGRect(x: 0, y: 0, width: 28, height: 28)
        weatherButton.imageView?.contentMode = .scaleAspectFit
        weatherButton.imageEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 0)
        weatherButton.addTarget(self, action: #selector(WeatherPushAction), for: .touchUpInside)
        self.navigationItem.rightBarButtonItems = [UIBarButtonItem(customView: infoButton),UIBarButtonItem(customView: weatherButton)]
        let label = UILabel()
        label.text = "Noteline"
        label.textAlignment = .left
        label.textColor = UIColor(red:0.38, green:0.77, blue:0.97, alpha:1.0)
        label.font = UIFont.systemFont(ofSize: 42, weight: UIFont.Weight.medium)
        self.navigationItem.leftBarButtonItem = UIBarButtonItem.init(customView: label)
        floaty.buttonImage = UIImage(named: "add")
        floaty.tag = 200
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        self.navigationController?.navigationBar.tintColor = UIColor(red:0.38, green:0.77, blue:0.97, alpha:1.0)
        reorderTableView = LongPressReorderTableView(tableView)
        reorderTableView.delegate = self
        self.tableView.estimatedRowHeight = 88.0
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.contentInset = UIEdgeInsetsMake(10, 0, 0, 0)
    }
    override func viewDidAppear(_ animated: Bool) {
        getNotes()
        getTemplates()
        tableView.reloadData()
        if templates.isEmpty {
            if ((addButtonView) != nil) {
                self.parent?.view.viewWithTag(100)?.isHidden = false
            } else {
                addButtonView = UIView(frame: CGRect(x: view.frame.maxX - 100, y: view.frame.maxY - 100, width: 100, height: 100))
                let addButton = UIButton(type: .system)
                addButton.setImage(#imageLiteral(resourceName: "add").withRenderingMode(.alwaysOriginal), for: .normal)
                addButton.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
                addButton.addTarget(self, action: #selector(addNote), for: .touchUpInside)
                addButtonView?.tag = 100
                addButtonView?.addSubview(addButton)
                self.parent?.view.addSubview(addButtonView!)
            }
        } else {
            self.parent?.view.viewWithTag(200)?.isHidden = false
            floaty.items.removeAll()
            floaty.addItem("Blank", icon: UIImage(named: "plus")!, handler: { item in
                selectedID = nil
                template = []
                self.parent?.view.viewWithTag(200)?.isHidden = true
                self.performSegue(withIdentifier: "editNote", sender: self)
            })
            for templateItem in templates {
                let floatyTitle = templateItem[0] as! String
                floaty.addItem(floatyTitle, icon: UIImage(named: "plus")!, handler: { item in
                    selectedID = nil
                    template = [floatyTitle, templateItem[1]]
                    self.parent?.view.viewWithTag(200)?.isHidden = true
                    self.performSegue(withIdentifier: "editNote", sender: self)
                })
            }
            for item in floaty.items {
                let recognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.floatyLongPress))
                item.addGestureRecognizer(recognizer)
            }
            self.parent?.view.addSubview(floaty)
        }
    }
    @objc func doubleTapped() {
        NightNight.toggleNightTheme()
    }
    @objc func floatyLongPress(sender: UILongPressGestureRecognizer) {
        if sender.state == UIGestureRecognizerState.began {
            let floatyItem = sender.view as! FloatyItem
            for (index,item) in self.floaty.items.enumerated() {
                if item == floatyItem && index != 0 {
                    func removeTemplateItem(alert: UIAlertAction!) {
                        self.floaty.removeItem(item: item)
                        removeTemplateData(templateTitle: item.title!)
                    }
                    let alert = UIAlertController(title: "Remove Template", message: "Do you want to delete this template?", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Remove", style: .destructive, handler: removeTemplateItem))
                    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if notes.count == 0 {
            self.tableView.setEmptyMessage("Create a new Note by clicking \n the '+' button below.")
        } else {
            self.tableView.restore()
        }
        return notes.count
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Note", for: indexPath) as! NoteCell
        cell.noteTitle?.text = notes[indexPath.row][0] as? String
        cell.noteDate?.text = notes[indexPath.row][1] as? String
        cell.noteTitle?.mixedTextColor = MixedColor(normal: 0x5e5e5e, night: 0xffffff)
        cell.noteDate?.mixedTextColor = MixedColor(normal: 0x4b4b4b, night: 0xeaeaea)
        cell.noteDate?.layer.addBorder(edge: UIRectEdge.bottom, color: UIColor(red:0.87, green:0.90, blue:0.91, alpha:1.0), thickness: 0.5)
        return cell
    }
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.contentView.mixedBackgroundColor = MixedColor(normal: 0xffffff, night: 0x263238)
    }
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let delete = UITableViewRowAction(style: .destructive, title: "Delete") { (action, indexPath) in
            self.deleteNote(id: notes[indexPath.row][2] as! NSManagedObjectID)
            notes.remove(at: indexPath.row)
            tableView.reloadData()
        }
        return [delete]
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedID = notes[indexPath.row][2]
        view.superview?.superview?.superview?.viewWithTag(100)?.isHidden = true
        view.superview?.superview?.superview?.viewWithTag(200)?.isHidden = true
    }
    @objc func addNote(_ sender: UIButton!) {
        selectedID = nil
        template = []
        view.superview?.superview?.superview?.viewWithTag(100)?.isHidden = true
        view.superview?.superview?.superview?.viewWithTag(200)?.isHidden = true
        performSegue(withIdentifier: "editNote", sender: self)
    }
    @objc func showInfo (_ sender: UIButton!) {
        view.superview?.superview?.superview?.viewWithTag(100)?.isHidden = true
        view.superview?.superview?.superview?.viewWithTag(200)?.isHidden = true
        performSegue(withIdentifier: "showInfo", sender: self)
    }
    @objc func WeatherPushAction(_ sender: UIButton!) {
        if(self.locationCurrent.coordinate.latitude == 0.0 || self.locationCurrent.coordinate.longitude == 0.0)
        {
            let alert = UIAlertController.init(title: "Location Error", message: "The current location acquisition fails, please reposition", preferredStyle: .alert)
            let actionOk = UIAlertAction.init(title: "OK", style: .default) { (actionOk) in
                self.locationManager.startUpdatingLocation()
            }
            alert.addAction(actionOk)
            self.present(alert, animated: true, completion: nil)
            return ;
        }else
        {
            let WeatherGit = NotelineWeatherViewController.init()
            WeatherGit.loaction = self.locationCurrent
            WeatherGit.lat = self.Weather2D.latitude
            WeatherGit.lng = self.Weather2D.longitude
            self.present(WeatherGit, animated: true, completion: nil)
        }
    }
    func getTemplates() {
        templates.removeAll()
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Templates")
        let sort = NSSortDescriptor(key: "title", ascending: true)
        let sortDescriptors = [sort]
        request.returnsObjectsAsFaults = false
        request.sortDescriptors = sortDescriptors
        do {
            let results = try context.fetch(request)
            for data in results as! [NSManagedObject] {
                if data.value(forKey: "title") != nil {
                    let templateTitle = data.value(forKey: "title") as! String
                    if templateTitle != "" {
                        let groupData = data.value(forKey: "groups") as! NSData
                        let unarchiveObject = NSKeyedUnarchiver.unarchiveObject(with: groupData as Data)
                        let arrayObject = unarchiveObject as AnyObject! as! [DisplayGroup]
                        var groups = arrayObject
                        templates.append([templateTitle, groups])
                    }
                }
            }
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
    }
    func removeTemplateData(templateTitle: String) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Templates")
        let sort = NSSortDescriptor(key: "title", ascending: true)
        let sortDescriptors = [sort]
        request.returnsObjectsAsFaults = false
        request.sortDescriptors = sortDescriptors
        do {
            let results = try context.fetch(request)
            for data in results as! [NSManagedObject] {
                if data.value(forKey: "title") != nil {
                    if (templateTitle == data.value(forKey: "title") as! String) {
                        context.delete(data)
                        do {
                            try context.save() 
                        } catch {
                        }
                    }
                }
            }
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
    }
    func getNotes() {
        notes.removeAll()
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Notes")
        let sort = NSSortDescriptor(key: "updateDate", ascending: false)
        let sortDescriptors = [sort]
        request.returnsObjectsAsFaults = false
        request.sortDescriptors = sortDescriptors
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        do {
            let results = try context.fetch(request)
            for data in results as! [NSManagedObject] {
                if data.value(forKey: "title") != nil && data.value(forKey: "updateDate") != nil {
                    let myString = formatter.string(from: data.value(forKey: "updateDate") as! Date)
                    let yourDate = formatter.date(from: myString)
                    formatter.dateFormat = "MMM dd, yyyy - h:mm a"
                    let myStringafd = formatter.string(from: yourDate!)
                    notes.append([data.value(forKey: "title") as! String, myStringafd, data.objectID])
                } else if data.value(forKey: "title") != nil {
                    notes.append([data.value(forKey: "title") as! String, "no date", data.objectID])
                } else {
                    notes.append(["no title", "no date", data.objectID])
                }
            }
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
    }
    func deleteNote(id: NSManagedObjectID) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Notes")
        request.returnsObjectsAsFaults = false
        do {
            let results = try context.fetch(request)
            for data in results as! [NSManagedObject] {
                if (data.objectID == id) {
                    context.delete(data)
                    do {
                        try context.save() 
                    } catch {
                    }
                }
            }
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
    }
    func resizeImage(image: UIImage, newWidth: CGFloat) -> UIImage? {
        let scale = newWidth / image.size.width
        let newHeight = image.size.height * scale
        UIGraphicsBeginImageContext(CGSize(width: newWidth, height: newHeight))
        image.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
    @objc func showEditing() {
        tableView.setEditing(!tableView.isEditing, animated: true)
    }
}
extension UITableView {
    func setEmptyMessage(_ message: String) {
        let messageLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.bounds.size.width, height: self.bounds.size.height))
        messageLabel.text = message
        messageLabel.textColor = UIColor.lightGray
        messageLabel.numberOfLines = 2;
        messageLabel.textAlignment = .center;
        messageLabel.font = UIFont(name: "Gill Sans", size: 20)
        messageLabel.sizeToFit()
        self.backgroundView = messageLabel;
        self.separatorStyle = .none;
    }
    func restore() {
        self.backgroundView = nil
    }
}
@available(iOS 10.0, *)
extension NotesTableViewController : CLLocationManagerDelegate
{
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if(locations.count > 0)
        {
            self.locationCurrent = locations[0]
            self.Weather2D = locations[0].coordinate
        }
    }
}
