//
//  Persistence.swift
//  SectionedFetchRequest_Experiment
//
//  Created by Chuck Hartman on 6/28/21.
//

import CoreData

struct PersistenceController {
    
    static var shared = PersistenceController()
    
    let container: NSPersistentContainer

    init() {
        container = NSPersistentContainer(name: "SectionedFetchRequest_Experiment")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
    }
    
    // MARK: - Database setup
    
    static func initialDbSetup() -> Void {
        
        Item.deleteAll()
        
        let item1 = Item.newItem(name: "Z", order: 0)
        _ = Attribute.newAttribute(item: item1, name: "\(item1.name).0", order: 0)
        _ = Attribute.newAttribute(item: item1, name: "\(item1.name).1", order: 1)
        _ = Attribute.newAttribute(item: item1, name: "\(item1.name).2", order: 2)

        let item2 = Item.newItem(name: "Y", order: 1)
        _ = Attribute.newAttribute(item: item2, name: "\(item2.name).0", order: 0)
        _ = Attribute.newAttribute(item: item2, name: "\(item2.name).1", order: 1)
        _ = Attribute.newAttribute(item: item2, name: "\(item2.name).2", order: 2)

        let item3 = Item.newItem(name: "X", order: 2)
        _ = Attribute.newAttribute(item: item3, name: "\(item3.name).0", order: 0)
        _ = Attribute.newAttribute(item: item3, name: "\(item3.name).1", order: 1)
        _ = Attribute.newAttribute(item: item3, name: "\(item3.name).2", order: 2)

        do {
            try PersistenceController.shared.container.viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
    
}
