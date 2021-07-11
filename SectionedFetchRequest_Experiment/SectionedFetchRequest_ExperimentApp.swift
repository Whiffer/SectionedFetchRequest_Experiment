//
//  SectionedFetchRequest_ExperimentApp.swift
//  SectionedFetchRequest_Experiment
//
//  Created by Chuck Hartman on 6/28/21.
//

import SwiftUI

@main
struct SectionedFetchRequest_ExperimentApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
        }
    }
}
