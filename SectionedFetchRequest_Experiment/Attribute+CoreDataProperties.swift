//
//  Attribute+CoreDataProperties.swift
//  SectionedFetchRequest_Experiment
//
//  Created by Chuck Hartman on 6/29/21.
//
//

import Foundation
import CoreData


extension Attribute {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Attribute> {
        return NSFetchRequest<Attribute>(entityName: "Attribute")
    }

    @NSManaged public var name: String
    @NSManaged public var order: Int32
    @NSManaged public var item: Item

}

extension Attribute : Identifiable {

    @objc var sectionName: String {
        get {
            return self.item.name
        }
    }

    class func newAttribute(item: Item, name: String, order: Int?) -> Attribute {
        
        let attribute = Attribute(context: PersistenceController.shared.container.viewContext)
        attribute.name = name
        attribute.order = Int32(order ?? 0)
        attribute.item = item
        return attribute
    }
    
}
