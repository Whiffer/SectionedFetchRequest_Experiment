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
    
    // By using the \.sectionName keypath for the sectionIdentifier, all of the Attribute objects
    // that are related to the same Item object will be grouped into the same List Section.
    
    // The first SortDescriptor sorts all of the Attribute objects based on the value of
    // the \.item.order keypath.  i.e. The order of the Sections is a function of a value property
    // of the related Item and not a function of any value property of the Attribute.

    // In WWDC21-10017 (@ 24:40), Scott Perry warns that the sectionIdentifier and the first SortDescriptor
    // must be coordinated for the Sections to be grouped properly.
    // In this case, since the sectionIdentifier and the sortDescriptors are never dynamically updqated and
    // the values of both \.sectionName and \.item.order are always based on
    // the same related Item object, they are guaranteeded to be (and stay) in sync.
    
    @SectionedFetchRequest(sectionIdentifier: \.sectionName,
                           sortDescriptors: [SortDescriptor(\.item.order, order: .forward),
                                             SortDescriptor(\.order, order: .forward)],
                           predicate: nil,
                           animation: .default)
    private var attributes: SectionedFetchResults<String, Attribute>
    
    @State private var state = false

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
    }
    
    @MainActor
    func reset() async {
        
        PersistenceController.initialDbSetup()
    }

    @MainActor
    func swap() async {
        
        let context = PersistenceController.shared.container.viewContext

        do {
            // The following code swaps the order properties of the first two Item objects.
            
            let items = try context.fetch(Item.fetchAllInOrder())
            let firstItemOrder = items[0].order
            let secondItemOrder = items[1].order
            items[0].order = secondItemOrder
            items[1].order = firstItemOrder
            try context.save()
            
            // Because none of the Item "names" have changed, all of the Attribute objects will
            // still be grouped together into the same Section with the same name.
            
            // However, because the "order" of the Item objects has been changed,
            // the order of the Attribute objects in the fetched results (and therefore
            // the order of Sections) should be different as well.
            // These committed changes should cause the fetched results to be refreshed and
            // in turn cause SwiftUI to update the View.
            
            // In this case, the View is not updated unless the App is terminated and restarted or
            // unless the workaround trick from below is enabled.
            
            // BTW, changes committed to any value property of an Attribute object will
            // cause the fetched results (and the View) to be updated properly.

        } catch let error as NSError {
            fatalError("Unresolved error \(error), \(error.userInfo)")
        }
        
        //**********************************************************
        // WORKAROUND Trick
        //
        // Uncommenting this code will get SwiftUI to update the fetched results for
        // attributes:SectionedFetchResults<String, Attribute> by toggling a @State var that triggers
        // a change to the nsPredicate dynamic property.
        // This works even though the changed nsPredicate property value has no real effect on the results fetched.
        
//        self.state.toggle()
//        self.attributes.nsPredicate = (self.state ? NSPredicate(format: "1==1") : NSPredicate(format: "0==0"))
        //**********************************************************
        
        //**********************************************************
        // QUESTION - Can this be made to work?
        //
        // The documentation for the update() method seems to imply that new results should be fetched
        // when it is called,  However, when it is called, the fetched results do not seem to change and the
        // View does not get updated.
        
//        var attributes = self.$attributes.projectedValue
//        attributes.update()
        //**********************************************************
    }
    
}
