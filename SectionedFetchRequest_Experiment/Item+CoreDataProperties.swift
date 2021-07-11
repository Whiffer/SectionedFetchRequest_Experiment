//
//  Item+CoreDataProperties.swift
//  SectionedFetchRequest_Experiment
//
//  Created by Chuck Hartman on 6/29/21.
//
//

import Foundation
import CoreData

extension Item {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Item> {
        return NSFetchRequest<Item>(entityName: "Item")
    }

    @nonobjc public class func fetchAllInOrder() -> NSFetchRequest<Item> {
        let fetchRequest = fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Item.order, ascending: true)]
        return fetchRequest
    }

    @NSManaged public var name: String
    @NSManaged public var order: Int32
    @NSManaged public var attribute: NSSet?
}

// MARK: Generated accessors for attribute
extension Item {

    @objc(addAttributeObject:)
    @NSManaged public func addToAttribute(_ value: Attribute)

    @objc(removeAttributeObject:)
    @NSManaged public func removeFromAttribute(_ value: Attribute)

    @objc(addAttribute:)
    @NSManaged public func addToAttribute(_ values: NSSet)

    @objc(removeAttribute:)
    @NSManaged public func removeFromAttribute(_ values: NSSet)

}

extension Item : Identifiable {
    
    public class func newItem(name: String, order: Int?) -> Item {
        
        let item = Item(context: PersistenceController.shared.container.viewContext)
        item.name = name
        item.order = Int32(order ?? 0)
        return item
    }
    
    class func deleteAll() -> Void {
        
        let context = PersistenceController.shared.container.viewContext

        do {
            let items = try context.fetch(Item.fetchRequest())
            for item in items {
                context.delete(item)
            }
            try context.save()
        } catch let error as NSError {
            fatalError("Unresolved error \(error), \(error.userInfo)")
        }
    }
    
}
