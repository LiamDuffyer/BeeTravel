import UIKit
import Foundation
import CoreData
public class Note {
    var noteTitle: String
    var updatedDate = Date()
    var groupItems = [[String]]()
    var groups = [String]()
    init?(noteTitle: String, groupItems: [[String]], groups: [String], date: Date) {
        if groups.isEmpty || groupItems.isEmpty {
            return nil
        }
        self.noteTitle = noteTitle
        self.groupItems = groupItems
        self.groups = groups
        self.updatedDate = date
    }
}
class Item: NSObject, NSCoding {
    var value: String
    weak var parent: Item?
    init(value: String) {
        self.value = value
    }
    required init(coder aDecoder: NSCoder)
    {
        self.value = aDecoder.decodeObject(forKey: "value") as! String
        self.parent = aDecoder.decodeObject(forKey: "parent") as? Item
    }
    func encode(with aCoder: NSCoder){
        aCoder.encode(value, forKey: "value")
        aCoder.encode(parent, forKey: "parent")
    }
}
class DisplayGroup: NSObject, NSCoding {
    var indentationLevel: Int
    var item: Item?
    var hasChildren: Bool
    var done: Bool
    var isExpanded: Bool
    init(indentationLevel: Int, item: Item, hasChildren: Bool, done: Bool, isExpanded: Bool ) {
        self.indentationLevel = indentationLevel
        self.item = item
        self.hasChildren = hasChildren
        self.done = done
        self.isExpanded = true
    }
    required init(coder aDecoder: NSCoder)
    {
        self.indentationLevel = aDecoder.decodeInteger(forKey: "indentationLevel")
        self.hasChildren = aDecoder.decodeBool(forKey: "hasChildren")
        self.item = aDecoder.decodeObject(forKey: "item") as! Item
        self.done = aDecoder.decodeBool(forKey: "done")
        self.isExpanded = aDecoder.decodeBool(forKey: "isExpanded")
    }
    func encode(with aCoder: NSCoder)
    {
        aCoder.encode(item, forKey: "item")
        aCoder.encode(hasChildren, forKey: "hasChildren")
        aCoder.encode(indentationLevel, forKey: "indentationLevel")
        aCoder.encode(done, forKey: "done")
        aCoder.encode(done, forKey: "isExpanded")
    }
}
