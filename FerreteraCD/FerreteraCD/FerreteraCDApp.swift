//
//  FerreteraCDApp.swift
//  FerreteraCD
//
//  Created by Lina Arias on 10/11/26.
//

import SwiftUI
import CoreData

@main
struct FerreteraCDApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
