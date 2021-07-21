//
//  ContentView.swift
//  SectionedFetchRequest_Experiment
//
//  Created by Chuck Hartman on 6/28/21.
//

import SwiftUI
import CoreData

struct ContentView: View {
    
    @Environment(\.managedObjectContext) private var viewContext

    // See the README file for a detailed explanation of the issue and the supplied workaround.
    
    @SectionedFetchRequest(sectionIdentifier: \Attribute.sectionName,
                           sortDescriptors: [SortDescriptor(\Attribute.item.order, order: .forward),
                                             SortDescriptor(\Attribute.order, order: .forward)],
                           predicate: nil,
                           animation: .default)
    private var attributes: SectionedFetchResults<String, Attribute>
    
    // WORKAROUND: A Publisher that generates an event when the Managed Object Context gets saved
    private var contextDidSave =  NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)

    var body: some View {
        NavigationView {
            List {
                ForEach(attributes) { section in
                    Section(header: Text("Section for Item '\(section.id)'")) {
                        ForEach(section) { attribute in
                            Text("Attribute[\(attribute.order)] for Item[\(attribute.item.order)] named '\(attribute.item.name)'")
                        }
                    }
                }
            }
            .navigationTitle("SectionedFetchRequest")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button("Reset", action: { Task.init { await self.reset() } } ),
                                trailing: Button("Swap", action: { Task.init { await self.swap() } } ) )
        }
        
        // BEGIN WORKAROUND
        // Uncommenting the following will resolve the issue of the View not being updated when the "Swap" button is tapped.
//        .onReceive(self.contextDidSave) { notification in
//            self.handleContextDidSaveNotification(notification: notification)
//        }
        // END WORKAROUND
    }
    
    private func handleContextDidSaveNotification(notification: Notification) {
        
        // Don't bother if there are no results
        guard attributes.count > 0 else { return }
        
        // A more general solution should probably use the SortDescriptor key paths
        // to help decide whether or not an updated object will affect the results sort order.
//        for sortDescriptor in attributes.sortDescriptors {
//            let sortDescriptor = NSSortDescriptor(sortDescriptor)
//            print("SortDescriptor Keypath: \(sortDescriptor.key ?? "")")
//        }
        
        // This workaround only checks for "updated" objects
        // A more general solution may need to check other notification types as well
        
        // Get the Set of NSManagedOject's that were updated when the Context was saved.
        if let updates = notification.userInfo?["updated"] as? Set<NSManagedObject> {

            // For performance reasons, the results should be refreshed only when it is really necessary.
            // The code below attempts to do that by comparing each updated object to all of the objects
            // that have a relationship with each Results object.
            // Additional/Different tests may be needed for a completely general solution.
            
            var refreshResultsNeeded = false
            
            outerLoop: for update in updates {
                // Get Entity name of the object that was updated
                if let updatedEntityName = update.entity.name {
                    // Since there is results, there should always be at least one Section
                    let section = attributes[0]
                    // That Section should always contain at least one NSManagedObject
                    // Go through all of the relationships to the Entity of the Results
                    for relationship in section[0].entity.relationshipsByName.values {
                        // Get Name of an Entity related to the Results object
                        if let destinationEntityName = relationship.destinationEntity?.name {
                            // Get Key Path of the relationship
                            let destinationKeyPath = relationship.name
                            // Is the Entity Name of the updated object the same as the Entity that is related to Results?
                            if updatedEntityName == destinationEntityName {
                                // If so, is the updated object the same object that is related to a Results object?
                                // Go through all of the Results objects in all sections
                                for section in attributes {
                                    for attribute in section {
                                        let relatedObject = attribute.value(forKey: destinationKeyPath) as! NSManagedObject
                                        if relatedObject.objectID == update.objectID {
                                            // The results should be refetched since an object that is related to a Results
                                            // object has been updated and could have changed the order of the sections.
                                            refreshResultsNeeded = true
                                            // No need to look any further
                                            break outerLoop
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            if refreshResultsNeeded {
                // This is a trick that causes the SectionedFetchResults to be refetched by toggling the nsPredicate
                // dynamic property between two different values that always select all Attribute objects.
                
                // Of course, this only works if nsPredicate is not being used for something else.
                attributes.nsPredicate = (attributes.nsPredicate == nil ? NSPredicate(format: "1==1") : nil)
            }
        }
    }
    
    @MainActor
    func reset() async {
        
        PersistenceController.initialDbSetup()
    }

    @MainActor
    func swap() async {
        
        do {
            // The following code swaps the order properties of the first two Item objects.
            
            let items = try self.viewContext.fetch(Item.fetchAllInOrder())
            let firstItemOrder = items[0].order
            let secondItemOrder = items[1].order
            items[0].order = secondItemOrder
            items[1].order = firstItemOrder
            try self.viewContext.save()
            
            // Because none of the Item "names" have changed, all of the Attribute objects will
            // still be grouped together into the same Section with the same name.
            
            // However, because the "order" of the "Item" objects has been changed,
            // the order of the Attribute objects in the fetched results (and therefore
            // the order of Sections) should be different as well.
            // These committed changes should cause the fetched results to be refreshed and
            // in turn cause SwiftUI to update the View.
            
            // In this case, the View is not updated unless the App is terminated and restarted or
            // unless the workaround from above is enabled.
            
            // BTW, changes committed to any value property of an Attribute object will
            // cause the fetched results (and the View) to be updated properly.

        } catch let error as NSError {
            fatalError("Unresolved error \(error), \(error.userInfo)")
        }
    }
    
}
