//
//  UserProfile.swift
//  Drona
//
//  Created by Yaduraj Singh on 19/03/25.
//

import Foundation

struct UserProfile: Codable, Identifiable {
    var id = UUID()
    var name: String
    var age: Int
    var educationLevel: EducationLevel
    var interests: [Interest]
    var preferredTopics: [DoubtCategory]
    var bio: String
    
    enum EducationLevel: String, Codable, CaseIterable {
        case highSchool = "High School"
        case undergrad = "Undergraduate"
        case postgrad = "Postgraduate"
        case other = "Other"
    }
    
    enum Interest: String, Codable, CaseIterable {
        case science = "Science"
        case technology = "Technology"
        case engineering = "Engineering"
        case mathematics = "Mathematics"
        case arts = "Arts"
        case literature = "Literature"
        case music = "Music"
        case sports = "Sports"
        case finance = "Finance"
        case other = "Other"
    }
    
    enum DoubtCategory: String, Codable, CaseIterable {
        case academic = "Academic"
        case personal = "Personal"
        case financial = "Financial"
        case social = "Social"
        case relational = "Relational"
        case career = "Career"
    }
} 