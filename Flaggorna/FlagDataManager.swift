//
//  FlagDataManager.swift
//  Flaggorna
//
//  Created by Mikael Mattsson on 2023-06-28.
//

import SwiftUI
import CoreData

struct FlagDataManager {
    
    static func loadDataAndUpdateFlagData(completion: @escaping ([Country]) -> Void) {
        #if FLAGGORNA
        let file = Bundle.main.path(forResource: "countries", ofType: "json")!
        #elseif TEAM_LOGO_QUIZ
        let file = Bundle.main.path(forResource: "teams", ofType: "json")!
        #endif
        
        let data = try! Data(contentsOf: URL(fileURLWithPath: file))
        let decoder = JSONDecoder()
        let countries = try! decoder.decode([Country].self, from: data)
        
        updateFlagData(countries: countries)
        
        completion(countries)
    }
    
    private static func updateFlagData(countries: [Country]) {
        let managedObjectContext = PersistenceController.shared.container.viewContext
        
        // Fetch existing flag data
        let fetchRequest: NSFetchRequest<FlagData> = FlagData.fetchRequest()
        var existingFlagData: [FlagData] = []
        
        do {
            existingFlagData = try managedObjectContext.fetch(fetchRequest)
        } catch {
            // Handle Core Data fetch error
            print("Error fetching flag data: \(error)")
        }
        
        // Create a dictionary of existing flag data by country name
        var existingFlagDataDict: [String: FlagData] = [:]
        for flagData in existingFlagData {
            if let countryName = flagData.country_name {
                existingFlagDataDict[countryName] = flagData
            }
        }
        
        // Update or create flag data for each country
        for country in countries {
            if let existingFlagData = existingFlagDataDict[country.name] {
                // Update existing flag data
                existingFlagData.flag = country.flag
            } else {
                // Create new flag data
                let flagData = FlagData(context: managedObjectContext)
                flagData.country_name = country.name
                flagData.flag = country.flag
                flagData.impressions = 0
                flagData.right_answers = 0
            }
        }
        
        // Save the changes to Core Data
        do {
            try managedObjectContext.save()
        } catch {
            // Handle Core Data saving error
            print("Error saving flag entities: \(error)")
        }
    }
}

