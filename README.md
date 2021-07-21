# SectionedFetchRequest_Experiment

Updated: July 21, 2021
Compiles on: Xcode Version 13.0 beta 3 (13A5192j)

SwiftUI's new @SectionedFetchRequest Property Wrapper in iOS 15 Beta 3 does not properly respond to changes that are saved to the core data context.

A simple self-contained project called SectionedFetchRequest_Experiment is attached to demonstrate this issue.

The @SectionedFetchRequest property wrapper is configured to fetch all Attribute objects.  Its sectionIdentifier is set to the \Attribute.sectionName key-path, which is a computed property of the Attribute class that returns the name of the Item object that is related to it.  Therefore, all Attribute objects that are related to the same Item object will be grouped into the same List Section.

The sortDescriptors parameter is set to an array of two SortDescriptor's.  The first (major) SortDescriptor sorts all of the Attribute objects based on the value of the \Attribute.item.order key-path.  i.e. The order of the Attribute Sections is based on the order property of the "Item" entity and not a function of any value property of the Attribute entity.  The second (minor) SortDescriptor then sorts the contents of each section according to the order property of the Attribute object itself.

In WWDC21-10017 (@ 24:40), Scott Perry does warn that the sectionIdentifier and the first SortDescriptor must be coordinated for the Sections to be grouped and ordered properly.  In this case, since the values of both \Attribute.sectionName and \Attribute.item.order are always based on the same related Item object, and the fact that the sectionIdentifier and the sortDescriptors are never dynamically changed, they are guaranteed to be (and stay) in sync.

Since the Fetch Request is configured to return all Attribute objects, if any property of an Attribute object is changed in the persistent store, the FetchResults should be (and are) updated.  This will cause the ContentView to be updated as well.  

The problem with the Property Wrapper is that if the order property of any "Item" object changes which would cause the order of the Sections to be different, the FetchResults do not reflect that change and the ContentView is not updated.

All of the Attribute objects are still grouped together into the same Section with the same name because none of the Item "names" has changed,  However, since the "order" of one or more "Item" objects has changed, the order of the Attribute objects in the fetched results (and therefore the order of Sections) is likely to be different. When the context is saved after making these changes, the fetched results should be refreshed and in turn cause SwiftUI to update the ContentView.  In the case of this sample App, the View is not updated unless the App is terminated and then restarted. Only then will the order of the sections be correct.

To demonstrate this issue, compile and run the sample App. Tap the Reset button to initialize (or reinitialize) the App's core data sample database.  Then tap the Swap button. This should swap the order properties of the first two Items, however, the ContentView does not reflect this change.  Now, uncomment the workaround code and rerun the above test. This time, when the Swap button is tapped, the first two List Sections swap places as intended.

It seems that this issue is an oversight with the implementation of the @SectionedFetchRequest Property Wrapper by not completely handling NSManagedObjectContextDidSave notifications.  Especially ones that could affect the SectionedFetchResults, and most importantly the order of the List Sections.

At a bare minimum, the Property Wrapper should perform a new fetch any time it receives a NSManagedObjectContextDidSave notification.  However, for performance reasons, it would be better to refresh the results only when it is absolutely necessary. The code in the workaround provided in the sample App attempts to do that by comparing each updated object to all of the objects in the current results that have a relationship to it.  Additional/Different tests may be needed for a completely optimal solution, like possibly using the SortDescriptor key-paths to help decide whether or not it's possible for an updated related object to affect the order of the sections.  Also, this sample workaround only handles "updated" objects.  A more general solution may also need to check other change notification types as well.

Once the workaround has determined that the fetched results should be refreshed, it uses a trick to cause the property wrapper to refetch its results by toggling a change to the nsPredicate dynamic property between two different values that always select all Attribute objects.  Of course, this achieves the desired results, but only works if nsPredicate is not being used for its intended purpose.  

It is very important that the @SectionedFetchRequest property wrapper properly keep its Fetched Results up to date and properly Publish any changes so the Views will correctly match the source of truth.  This is especially important when fetching from a Core Data store that is using an NSPersistentCloudKitContainer.
