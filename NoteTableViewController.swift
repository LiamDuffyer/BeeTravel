import UIKit
import CoreData
import CloudKit
import CloudCore
import LongPressReorder
import NightNight
import SideMenu
var currentDate = Date()
var shareTitle : String = ""
var shareNoteArray = [DisplayGroup]()
var headerTag : Int = 0
var indexPathFocus = IndexPath()
var nextIndexPath = NSIndexPath()
var enter = false
var nextGroup : Int = 0
var childrenItems = [DisplayGroup]()
var parentInd : Int = 0
var old : Bool = false
class NoteTableViewController: UITableViewController, UITextViewDelegate {
    var reorderTableView: LongPressReorderTableView!
    var note = Note(noteTitle: "", groupItems: [[""]], groups: [""], date: currentDate)
    var noteArray = [
        DisplayGroup(
            indentationLevel: 1,
            item: Item(value: ""),
            hasChildren: false,
            done: false,
            isExpanded: true)
    ]
    var cellHeights: [IndexPath : CGFloat] = [:]
    var dataToSend: AnyObject?
    @IBOutlet weak var NoteTitle: UITextView!
    var placeholderLabel : UILabel!
    @IBOutlet weak var NoteDate: EdgeInsetLabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        if let delegate = UIApplication.shared.delegate as? AppDelegate {
            if (delegate.openNote.count > 0) {
                self.noteArray = delegate.openNote
                self.NoteTitle.text = delegate.openNoteTitle
                self.updateEntity(id: selectedID, attribute: "groups", value: self.noteArray)
                self.updateEntity(id: selectedID, attribute: "title", value: self.NoteTitle.text)
                delegate.openNote.removeAll()
            }
        }
        self.tableView.mixedBackgroundColor = MixedColor(normal: 0xffffff, night: 0x263238)
        self.tableView.contentInset = UIEdgeInsetsMake(-10, 0, 0, 0)
        currentDate = Date()
        self.NoteTitle.tag = 1
        self.NoteTitle.delegate = self
        self.NoteTitle.mixedBackgroundColor = MixedColor(normal: 0xffffff, night: 0x263238)
        self.NoteTitle.mixedTextColor = MixedColor(normal: 0x5e5e5e, night: 0xffffff)
        placeholderLabel = UILabel(frame: CGRect(x: 5, y: 0, width: self.NoteTitle.frame.width, height: self.NoteTitle.frame.height))
        placeholderLabel.text = "Add a title"
        self.NoteTitle.addSubview(placeholderLabel)
        placeholderLabel.textColor = UIColor.lightGray
        placeholderLabel.font = placeholderLabel.font.withSize(22)
        placeholderLabel.isHidden = !self.NoteTitle.text.isEmpty
        self.NoteDate.layer.addBorder(edge: UIRectEdge.bottom, color: UIColor(red:0.87, green:0.90, blue:0.91, alpha:1.0), thickness: 0.5)
        let menuButton = UIButton()
        menuButton.setImage(UIImage(named: "menu"), for: .normal)
        menuButton.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
        menuButton.imageView?.contentMode = .scaleAspectFit
        menuButton.imageEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 10)
        menuButton.addTarget(self, action: #selector(sideMenu), for: .touchUpInside)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: menuButton)
        tableView.estimatedRowHeight = UITableViewAutomaticDimension
        tableView.rowHeight = UITableViewAutomaticDimension
        old = false
        getNote()
        reorderTableView = LongPressReorderTableView(tableView, scrollBehaviour: .early)
        reorderTableView.delegate = self
        reorderTableView.enableLongPressReorder()
        headerTag = 0
        let tap = UITapGestureRecognizer(target: self, action: #selector(hideKeyBoard))
        self.view.addGestureRecognizer(tap)
    }
    @objc func hideKeyBoard(sender: UITapGestureRecognizer? = nil){
        view.endEditing(true)
    }
    @objc func collapseGroup(sender: UITapGestureRecognizer? = nil){
        let tappedImage = sender?.view as! UIImageView
        var cell = tappedImage.superview?.superview?.superview as! UITableViewCell
        let indexPath = self.tableView.indexPath(for: cell)
        let parentRow = indexPath!.row
        if (parentRow+1 < noteArray.count-1) {
            for i in (parentRow+1...noteArray.count-1) {
                if (noteArray[i].indentationLevel == noteArray[parentRow].indentationLevel) {
                    nextGroup = i
                    break
                }
            }
        } else {
            nextGroup = noteArray.count
        }
        if (parentRow+1 <= nextGroup-1) {
            for i in (parentRow+1...nextGroup-1) {
                noteArray[i].isExpanded.toggle()
            }
        }
        for i in (0...noteArray.count-1) {
            print("loop: \(noteArray[i].isExpanded)")
        }
        self.updateEntity(id: selectedID, attribute: "groups", value: self.noteArray)
        let contentOffset = tableView.contentOffset
        tableView.reloadData()
        tableView.setContentOffset(contentOffset, animated: false)
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let headerView = tableView.tableHeaderView {
            let height = headerView.systemLayoutSizeFitting(UILayoutFittingCompressedSize).height
            var headerFrame = headerView.frame
            if (headerFrame.height < ((headerView.viewWithTag(1)?.frame.height)!) + 30) {
                tableView.tableHeaderView?.frame.size = CGSize(width: headerFrame.width, height: (headerView.viewWithTag(1)?.frame.height)! + 35)
                tableView.reloadData()
            }
            headerView.mixedBackgroundColor = MixedColor(normal: 0xffffff, night: 0x263238)
        }
        for subView in tableView.tableHeaderView?.subviews as [UIView]! {
            if let textView = subView as? UITextView {
                if (textView.text == "" && self.noteArray.count == 0) {
                    textView.becomeFirstResponder()
                } else {
                    placeholderLabel.isHidden = !textView.text.isEmpty
                }
            }
        }
        if (!indexPathFocus.isEmpty) {
            let rows = self.noteArray.count - 1
            if indexPathFocus.row < rows {
                nextIndexPath = NSIndexPath(row: indexPathFocus.row + 1, section: indexPathFocus.section)
                if let textCell = tableView.cellForRow(at: nextIndexPath as IndexPath) as? ExpandingCell {
                    if enter == true {
                        self.tableView.scrollToRow(at: nextIndexPath as IndexPath, at: UITableViewScrollPosition.middle, animated: true)
                        textCell.textView.becomeFirstResponder()
                        enter = false
                    }
                }
            }
        }
    }
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeights[indexPath] ?? 40.0
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    func textViewDidChange(_ textView: UITextView) {
        if textView.tag == 1 {
            placeholderLabel.isHidden = !textView.text.isEmpty
            if (textView.frame.height > self.tableView.viewWithTag(9999)?.frame.height ?? 80) {
                tableView.beginUpdates()
                self.tableView.viewWithTag(9999)?.frame = CGRect(x: 0, y: 0, width: (self.tableView.viewWithTag(9999)?.frame.width)!, height: textView.frame.height + 40)
                tableView.endUpdates()
            } else {
                tableView.beginUpdates()
                self.tableView.viewWithTag(9999)?.frame = CGRect(x: 0, y: 0, width: (self.tableView.viewWithTag(9999)?.frame.width)!, height: textView.frame.height + 40)
                tableView.endUpdates()
            }
            self.note!.noteTitle = textView.text!
            self.updateEntity(id: selectedID, attribute: "title", value: self.note!.noteTitle)
        } else {
            let cell: UITableViewCell = textView.superview!.superview as! UITableViewCell
            let table: UITableView = cell.superview as! UITableView
            let textViewIndexPath = table.indexPath(for: cell)
            let textViewSection = textViewIndexPath?.section
            let textViewRow = textViewIndexPath?.row
            indexPathFocus = textViewIndexPath!
            noteArray[textViewRow!].item?.value = textView.text
            self.updateEntity(id: selectedID, attribute: "groups", value: self.noteArray)
            let currentOffset = tableView.contentOffset
            UIView.setAnimationsEnabled(false)
            tableView.beginUpdates()
            tableView.endUpdates()
            UIView.setAnimationsEnabled(true)
            tableView.setContentOffset(currentOffset, animated: false)
        }
    }
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return noteArray.count
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") as! ExpandingCell
        cell.textView?.text = noteArray[indexPath.row].item?.value
        let indent = CGFloat(noteArray[indexPath.row].indentationLevel * 10)
        let frame = CGRect(x: 0, y: 8, width: 10, height: 10)
        let dot = UIImageView(frame: frame)
        dot.mixedBackgroundColor = MixedColor(normal: 0xffffff, night: 0x263238)
        dot.contentMode = .scaleAspectFit
        var image: UIImage = UIImage(named: "dot")!.withRenderingMode(.alwaysOriginal)
        image = resizeImage(image: image, newWidth: 12)!
        dot.image = image
        dot.tag = 123
        dot.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(collapseGroup))
        dot.addGestureRecognizer(tap)
        if (noteArray[indexPath.row].indentationLevel == 1) {
            for constraint in cell.contentView.constraints {
                if constraint.identifier == "cellIndent" {
                    constraint.constant = 8
                }
            }
            if (cell.textView?.viewWithTag(123) == nil) {
                cell.textView?.textContainerInset = UIEdgeInsets(top: 5,left: 10,bottom: 5,right: 0)
                cell.textView?.addSubview(dot)
                cell.textView?.removeLeftBorder()
            }
        } else {
            cell.textView?.removeLeftBorder()
            for constraint in cell.contentView.constraints {
                if constraint.identifier == "cellIndent" {
                    constraint.constant = 13
                }
            }
            cell.textView?.textContainerInset = UIEdgeInsets(top: 5,left: indent,bottom: 5,right: 0)
            if (cell.textView?.viewWithTag(123) != nil) {
                cell.textView.viewWithTag(123)?.removeFromSuperview()
            }
            cell.textView?.addLeftBorder()
        }
        if (self.noteArray[indexPath.row].done == true) {
            cell.textView?.mixedTextColor = MixedColor(normal: UIColor(red:0.79, green:0.79, blue:0.79, alpha:1.0), night: UIColor(red:0.71, green:0.71, blue:0.71, alpha:1.0))
            cell.textView?.font = UIFont.systemFont(ofSize: 15, weight: UIFont.Weight.ultraLight)
        } else if (noteArray[indexPath.row].indentationLevel == 1){
            cell.textView?.mixedTextColor = MixedColor(normal: 0x585858, night: 0xffffff)
            cell.textView?.font = UIFont.systemFont(ofSize: 15, weight: UIFont.Weight.medium)
        } else {
            cell.textView?.mixedTextColor = MixedColor(normal: 0x585858, night: 0xffffff)
            cell.textView?.font = UIFont.systemFont(ofSize: 15, weight: UIFont.Weight.light)
        }
        return cell
    }
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.contentView.mixedBackgroundColor = MixedColor(normal: 0xffffff, night: 0x263238)
        for subview in cell.contentView.subviews {
            if subview.tag == 1234 {
               subview.mixedBackgroundColor = MixedColor(normal: 0xefefef, night: 0x4b4b4b)
            }
        }
        cellHeights[indexPath] = cell.frame.size.height
    }
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            self.noteArray.remove(at: indexPath.row)
            tableView.deleteRows(at: [IndexPath(row: indexPath.row, section: 1)], with: .fade)
        }
    }
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if let cell = textView.superview?.superview as? UITableViewCell {
            headerTag = 0
            let indexPath = tableView.indexPath(for: cell)!
            if(text == "\n" || text == "\r") {
                indexPathFocus = indexPath
                enter = true
                var indent = noteArray[indexPath.row].indentationLevel
                if (noteArray.indices.contains(indexPath.row+1) && noteArray[indexPath.row+1].indentationLevel > 1) {
                    indent = 2
                }
                noteArray.insert(
                    DisplayGroup(
                        indentationLevel: indent,
                        item: Item(value: ""),
                        hasChildren: false,
                        done: false,
                        isExpanded: true),
                    at: indexPath.row + 1
                )
                self.updateEntity(id: selectedID, attribute: "group", value: self.noteArray)
                let contentOffset = tableView.contentOffset
                tableView.reloadData()
                tableView.setContentOffset(contentOffset, animated: false)
                return false
            }
            if text == "" && range.length == 0 && textView.text == "" {
                self.noteArray.remove(at: indexPath.row)
                self.updateEntity(id: selectedID, attribute: "groups", value: self.noteArray)
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
        }
        if(text == "\n" || text == "\r") {
            if (textView.tag == 1) {
                textView.resignFirstResponder()
            }
        }
        return true
    }
     @available(iOS 11.0, *)
    override func tableView(_ tableView: UITableView,
                   leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration?
    {
        let indentAction = UIContextualAction(style: .normal, title:  "Indent", handler: { (ac:UIContextualAction, view:UIView, success:(Bool) -> Void) in
            let cell = tableView.cellForRow(at: indexPath) as! ExpandingCell
            if (indexPath.row-1 >= 0 && indexPath.row+1 <= self.noteArray.count-1) {
                if (self.noteArray[indexPath.row].indentationLevel < self.noteArray[indexPath.row+1].indentationLevel) {
                    for j in (indexPath.row+1...self.noteArray.count-1) {
                        if (self.noteArray[j].indentationLevel <= self.noteArray[indexPath.row].indentationLevel) {
                            nextGroup = j
                            break
                        } else {
                            nextGroup = self.noteArray.count
                        }
                    }
                    if (indexPath.row+1 < nextGroup-1) {
                        for k in (indexPath.row+1...nextGroup-1) {
                            self.noteArray[k].indentationLevel += 1
                        }
                    } else {
                        self.noteArray[indexPath.row+1].indentationLevel += 1
                    }
                    for i in (0...indexPath.row-1).reversed() {
                        if (self.noteArray[i].indentationLevel < self.noteArray[indexPath.row].indentationLevel) {
                            self.noteArray[indexPath.row].item?.parent = self.noteArray[i].item
                            self.noteArray[i].hasChildren = true
                            self.updateEntity(id: selectedID, attribute: "groups", value: self.noteArray)
                            break
                        }
                    }
                }
            }
            self.noteArray[indexPath.row].indentationLevel += 1
            self.updateEntity(id: selectedID, attribute: "groups", value: self.noteArray)
            let contentOffset = tableView.contentOffset
            tableView.reloadData()
            tableView.setContentOffset(contentOffset, animated: false)
            success(true)
        })
        indentAction.image = UIImage(named: "indent")
        return UISwipeActionsConfiguration(actions: [indentAction])
    }
    @available(iOS 11.0, *)
    override func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration?
    {
        let cell = tableView.cellForRow(at: indexPath) as! ExpandingCell
        let outdentAction = UIContextualAction(style: .normal, title:  "Outdent >", handler: { (ac:UIContextualAction, view:UIView, success:(Bool) -> Void) in
            if (self.noteArray[indexPath.row].indentationLevel > 1) {
                for (ind, element) in self.noteArray.enumerated() {
                    if (self.noteArray[indexPath.row].item?.parent === self.noteArray[ind].item) {
                        self.noteArray[ind].hasChildren = false
                        self.tableView.beginUpdates()
                        self.tableView.reloadRows(at: [IndexPath(item: ind, section: indexPath.section)], with: UITableViewRowAnimation.fade)
                        self.tableView.endUpdates()
                    }
                }
                let myIndent = self.noteArray[indexPath.row].indentationLevel
                if (self.noteArray[indexPath.row].indentationLevel == 1) {
                    self.noteArray[indexPath.row].item?.parent = nil
                } else if (indexPath.row-1 > 0) {
                    for i in (0...indexPath.row-1).reversed() {
                        if (self.noteArray[i].indentationLevel < myIndent) {
                            self.noteArray[indexPath.row].item?.parent = self.noteArray[i].item
                            break
                        }
                    }
                }
                if (indexPath.row+1 <= self.noteArray.count-1 && self.noteArray[indexPath.row].indentationLevel < self.noteArray[indexPath.row+1].indentationLevel) {
                    for j in (indexPath.row+1...self.noteArray.count-1) {
                        if (self.noteArray[j].indentationLevel <= myIndent) {
                            nextGroup = j
                            break
                        } else {
                            nextGroup = self.noteArray.count
                        }
                    }
                    if (indexPath.row+1 < nextGroup-1) {
                        for k in (indexPath.row+1...nextGroup-1) {
                            if (self.noteArray[k].indentationLevel > 0) {
                                self.noteArray[k].indentationLevel -= 1
                            }
                        }
                    } else {
                        if (self.noteArray[indexPath.row+1].indentationLevel > 0) {
                            self.noteArray[indexPath.row+1].indentationLevel -= 1
                        }
                    }
                }
                self.noteArray[indexPath.row].indentationLevel -= 1
            }
            self.updateEntity(id: selectedID, attribute: "groups", value: self.noteArray)
            let contentOffset = tableView.contentOffset
            tableView.reloadData()
            tableView.setContentOffset(contentOffset, animated: false)
            success(true)
        })
        outdentAction.image = UIImage(named: "outdent")
        let deleteAction = UIContextualAction(style: .normal, title:  "Delete", handler: { (ac:UIContextualAction, view:UIView, success:(Bool) -> Void) in
            if (self.noteArray[indexPath.row].hasChildren) {
                let alert = UIAlertController(title: "Delete group", message: "Are you sure you want to delete this item and it's children?", preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { action in
                    if (indexPath.row+1 < self.noteArray.count-1) {
                        for i in (indexPath.row+1...self.noteArray.count-1) {
                            if (self.noteArray[i].indentationLevel == self.noteArray[indexPath.row].indentationLevel) {
                                nextGroup = i
                                break
                            } else {
                                nextGroup = self.noteArray.count
                            }
                        }
                    }
                    if (indexPath.row+1 <= nextGroup-1) {
                        for i in (indexPath.row+1...nextGroup-1).reversed() {
                            self.noteArray.remove(at: i)
                            tableView.deleteRows(at: [IndexPath(row: i, section: indexPath.section)], with: .fade)
                        }
                    }
                    self.noteArray.remove(at: indexPath.row)
                    tableView.deleteRows(at: [indexPath], with: .fade)
                }))
                alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: { action in
                }))
                self.present(alert, animated: true, completion: nil)
            } else {
                self.noteArray.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
            if (self.noteArray.count == 0) {
                self.noteArray.append(
                    DisplayGroup(
                        indentationLevel: 1,
                        item: Item(value: ""),
                        hasChildren: false,
                        done: false,
                        isExpanded: true)
                )
                let contentOffset = tableView.contentOffset
                tableView.reloadData()
                tableView.setContentOffset(contentOffset, animated: false)
            }
            self.updateEntity(id: selectedID, attribute: "groups", value: self.noteArray)
            success(true)
        })
        deleteAction.backgroundColor = .red
        deleteAction.image = UIImage(named: "delete")
        let doneAction = UIContextualAction(style: .normal, title:  "Done", handler: { (ac:UIContextualAction, view:UIView, success:(Bool) -> Void) in
            if cell.textView.text.contains("✓") {
                self.noteArray[indexPath.row].item?.value = (self.noteArray[indexPath.row].item?.value)!.replacingOccurrences(of: "✓ ", with: "", options: NSString.CompareOptions.literal, range:nil)
                self.noteArray[indexPath.row].item?.value = (self.noteArray[indexPath.row].item?.value)!.replacingOccurrences(of: "✓", with: "", options: NSString.CompareOptions.literal, range:nil)
                self.noteArray[indexPath.row].done = false
            } else {
                self.noteArray[indexPath.row].done = true
                self.noteArray[indexPath.row].item?.value =  "✓ \((self.noteArray[indexPath.row].item?.value)! ?? "")"
            }
            self.updateEntity(id: selectedID, attribute: "groups", value: self.noteArray)
            success(true)
            let contentOffset = tableView.contentOffset
            tableView.reloadData()
            tableView.setContentOffset(contentOffset, animated: false)
        })
        doneAction.backgroundColor = UIColor(red:0.38, green:0.77, blue:0.97, alpha:1.0)
        doneAction.image = UIImage(named: "check")
        return UISwipeActionsConfiguration(actions: [outdentAction, doneAction, deleteAction ])
    }
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    func updateDate(dateVar: Date) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let myString = formatter.string(from: dateVar)
        let yourDate = formatter.date(from: myString)
        formatter.dateFormat = "MMM dd, yyyy - h:mm a"
        let myStringafd = formatter.string(from: yourDate!)
        self.NoteDate.text = myStringafd
        self.NoteDate.font = UIFont.systemFont(ofSize: 12, weight: UIFont.Weight.light)
        self.NoteDate.mixedTextColor = MixedColor(normal: 0x4b4b4b, night: 0xeaeaea)
    }
    func getNote() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Notes")
        request.returnsObjectsAsFaults = false
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        do {
            let results = try context.fetch(request)
            for data in results as! [NSManagedObject] {
                if selectedID != nil && data.objectID == selectedID as! NSManagedObjectID {
                    if data.value(forKey: "title") != nil {
                        self.NoteTitle.text = data.value(forKey: "title") as? String
                        self.NoteTitle.mixedTextColor = MixedColor(normal: 0x5e5e5e, night: 0xffffff)
                    }
                    if data.value(forKey: "updateDate") != nil {
                        updateDate(dateVar: data.value(forKey: "updateDate") as! Date)
                    }
                    if data.value(forKey: "groups") != nil {
                        let groupData = data.value(forKey: "groups") as! NSData
                        let unarchiveObject = NSKeyedUnarchiver.unarchiveObject(with: groupData as Data)
                        let arrayObject = unarchiveObject as AnyObject! as! [DisplayGroup]
                        noteArray = arrayObject
                    }
                    if data.value(forKey: "groupItems") != nil {
                        let groupItemData = data.value(forKey: "groupItems") as! NSData
                        let unarchiveObject = NSKeyedUnarchiver.unarchiveObject(with: groupItemData as Data)
                        let arrayObject = unarchiveObject as AnyObject! as! [[String]]
                        note?.groupItems = arrayObject
                        if (arrayObject.count) > 0 {
                            let groupData = data.value(forKey: "groups") as! NSData
                            let unarchiveObjectOld = NSKeyedUnarchiver.unarchiveObject(with: groupData as Data)
                            let arrayObjectOld = unarchiveObjectOld as AnyObject! as! [Any]
                            if arrayObjectOld[0] is DisplayGroup {
                            } else {
                                note?.groups = arrayObjectOld as! [String]
                                old = true
                                var oldNote = [DisplayGroup]()
                                for (i, group) in (note?.groups.enumerated())! {
                                    oldNote.append(
                                        DisplayGroup(
                                            indentationLevel: 1,
                                            item: Item(value: group),
                                            hasChildren: false,
                                            done: false,
                                            isExpanded: true)
                                    )
                                    for groupItem in (note?.groupItems[i])! {
                                        oldNote.append(
                                            DisplayGroup(
                                                indentationLevel: 2,
                                                item: Item(value: groupItem),
                                                hasChildren: false,
                                                done: false,
                                                isExpanded: true)
                                        )
                                    }
                                }
                                noteArray = oldNote
                            }
                        }
                    }
                } else if selectedID == nil {
                    updateDate(dateVar: currentDate)
                    if template.isEmpty == false {
                        self.NoteTitle.text = (template[0] as! String)
                        self.noteArray = template[1] as! [DisplayGroup]
                        self.updateEntity(id: selectedID, attribute: "groups", value: self.noteArray)
                        self.updateEntity(id: selectedID, attribute: "title", value: self.NoteTitle.text)
                    }
                }
            }
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
    }
    func updateEntity(id: Any?, attribute: String, value: Any) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.persistentContainer.viewContext
        if id == nil {
            let entity =  NSEntityDescription.entity(forEntityName: "Notes", in:managedContext)
            let noteEntity = NSManagedObject(entity: entity!,insertInto: managedContext)
            switch attribute {
            case "title":
                noteEntity.setValue(value, forKey: "title")
            case "groups":
                let groupData = NSKeyedArchiver.archivedData(withRootObject: value)
                noteEntity.setValue(groupData, forKey: "groups")
            case "groupItems":
                let groupItemData = NSKeyedArchiver.archivedData(withRootObject: value)
                noteEntity.setValue(groupItemData, forKey: "groupItems")
            default:
                return
            }
            noteEntity.setValue(currentDate, forKey: "updateDate")
            do {
                try managedContext.save()
                if selectedID == nil {
                    selectedID = noteEntity.objectID
                }
            } catch let error as NSError  {
                print("Could not save \(error), \(error.userInfo)")
            }
        } else {
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Notes")
            request.returnsObjectsAsFaults = false
            do {
                let results = try managedContext.fetch(request)
                for data in results as! [NSManagedObject] {
                    if selectedID != nil && data.objectID == selectedID as! NSManagedObjectID {
                        switch attribute {
                        case "updateDate":
                            data.setValue(value, forKey: "updateDate")
                        case "title":
                            data.setValue(value, forKey: "title")
                        case "groups":
                            let groupData = NSKeyedArchiver.archivedData(withRootObject: value)
                            data.setValue(groupData, forKey: "groups")
                        case "groupItems":
                            let groupItemData = NSKeyedArchiver.archivedData(withRootObject: value)
                            data.setValue(groupItemData, forKey: "groupItems")
                        default:
                            return
                        }
                        data.setValue(currentDate, forKey: "updateDate")
                    } 
                }
            } catch let error as NSError {
                print("Could not fetch \(error), \(error.userInfo)")
            }
        }
        do {
            try managedContext.save()
        } catch let error as NSError  {
            print("Could not save \(error), \(error.userInfo)")
        }
        updateDate(dateVar: currentDate)
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
    @objc func sideMenu(_ sender: UIButton!) {
        shareTitle = NoteTitle.text
        shareNoteArray = noteArray
        hideKeyBoard()
        performSegue(withIdentifier: "sideMenu", sender: self)
    }
}
extension CALayer {
    func addBorder(edge: UIRectEdge, color: UIColor, thickness: CGFloat) {
        let border = CALayer()
        switch edge {
        case UIRectEdge.top:
            border.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: thickness)
            break
        case UIRectEdge.bottom:
            border.frame = CGRect(x: 0, y: self.frame.height - thickness, width: self.frame.width, height: thickness)
            break
        case UIRectEdge.left:
            border.frame = CGRect(x: 0, y: 0, width: thickness, height: self.frame.height)
            break
        case UIRectEdge.right:
            border.frame = CGRect(x: self.frame.width - thickness, y: 0, width: thickness, height: self.frame.height)
            break
        default:
            break
        }
        border.backgroundColor = color.cgColor;
        border.name = "border"
        self.addSublayer(border)
    }
}
extension UITextView {
    func addLeftBorder (){
        let border = CALayer()
        border.frame = CGRect(x: 0, y: 0, width: 1.0, height: self.frame.height)
        border.backgroundColor = UIColor(red:0.79, green:0.79, blue:0.79, alpha:0.5).cgColor
        border.name = "border"
        self.layer.addSublayer(border)
    }
    func removeLeftBorder() {
        for subview in self.layer.sublayers! {
            if subview.name == "border" {
                subview.removeFromSuperlayer()
                break
            }
        }
    }
}
extension NoteTableViewController {
    override func positionChanged(currentIndex sourceIndexPath: IndexPath, newIndex destinationIndexPath: IndexPath) {
        let movedObject = noteArray[sourceIndexPath.row]
        parentInd = destinationIndexPath.row
        noteArray.remove(at: sourceIndexPath.row)
        noteArray.insert(movedObject, at: destinationIndexPath.row)
        let contentOffset = tableView.contentOffset
        tableView.reloadData()
        tableView.setContentOffset(contentOffset, animated: false)
        self.updateEntity(id: selectedID, attribute: "groups", value: self.noteArray)
    }
    override func startReorderingRow(atIndex indexPath: IndexPath) -> Bool {
        hideKeyBoard()
        childrenItems.removeAll()
        if (indexPath.row+1 < noteArray.count-1) {
                if (noteArray[indexPath.row].indentationLevel < noteArray[indexPath.row+1].indentationLevel) {
                for i in (indexPath.row+1...noteArray.count-1) {
                    if (noteArray[indexPath.row].indentationLevel >= noteArray[i].indentationLevel ) {
                        nextGroup = i
                        break
                    } else {
                        nextGroup = noteArray.count
                    }
                }
                if (indexPath.row+1 <= nextGroup-1) {
                    for i in (indexPath.row+1...nextGroup-1) {
                        childrenItems.append(noteArray[i])
                    }
                }
            }
        }
        return true
    }
    override func reorderFinished(initialIndex: IndexPath, finalIndex: IndexPath) {
        if (initialIndex != finalIndex && childrenItems.count > 0) {
            for (i, child) in childrenItems.enumerated() {
                let ind = (i + 1) + (finalIndex.row)
                noteArray.insert(child, at: ind)
            }
            if (initialIndex < finalIndex) {
                for (i, child) in childrenItems.enumerated() {
                    if let ind = noteArray.index(where: {$0 == child}) {
                        noteArray.remove(at: ind)
                    }
                }
            } else {
                for (i, child) in childrenItems.enumerated() {
                    if let ind = noteArray.reversed().index(where: {$0 == child}) {
                        noteArray.remove(at: ind.base-1)
                    }
                }
            }
        }
        let contentOffset = tableView.contentOffset
        tableView.reloadData()
        tableView.setContentOffset(contentOffset, animated: false)
        self.updateEntity(id: selectedID, attribute: "groups", value: self.noteArray)
    }
}
