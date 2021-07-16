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

    // The @SectionedFetchRequest is configured as follows:
    
    // By using the \Attribute.sectionName keypath for the sectionIdentifier, all of the Attribute objects
    // that are related to the same Item object will be grouped into the same List Section.
    
    // The first SortDescriptor sorts all of the Attribute objects based on the value of
    // the \Attribute.item.order keypath.  i.e. The order of the Sections is a function of a value property
    // of the related Item object and not a function of any value property of the Attribute.

    // In WWDC21-10017 (@ 24:40), Scott Perry warns that the sectionIdentifier and the first SortDescriptor
    // must be coordinated for the Sections to be grouped properly.
    // In this case, since the sectionIdentifier and the sortDescriptors are never dynamically updqated and
    // the values of both \Attribute.sectionName and \Attribute.item.order are always based on
    // the same related Item object, they are guaranteeded to be (and stay) in sync.
    
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
            .navigationBarItems(leading: Button("Reset", action: { async { await self.reset() } } ),
                                trailing: Button("Swap", action: { async { await self.swap() } } ) )
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
                if let updatedEntityName = update.entity.name {
                    // Since there is results, there should always be at least one Section
                    let section = attributes[0]
                    // That Section should always contain at least one NSManagedObject
                    for relationship in section[0].entity.relationshipsByName.values {
                        // Get Name of an Entity related to the Results object
                        if let destinationEntityName = relationship.destinationEntity?.name {
                            let destinationKeyPath = relationship.name
                            // Is the Entity Name of the updated object the same as the Entity that is related to Results?
                            if updatedEntityName == destinationEntityName {
                                // If so, is the updated object the same object that is related to a Results object?
                                for section in attributes {
                                    for attribute in section {
                                        let relatedObject = attribute.value(forKey: destinationKeyPath) as! NSManagedObject
                                        if relatedObject.objectID == update.objectID {
                                            // The results should be refetched since an object that is related to a Results
                                            // object has been updated and could have changed the order of the sections.
                                            refreshResultsNeeded = true
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
