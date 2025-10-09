//
//  WeeklyImportance.swift
//  Pyosition
//

import Foundation

// 주간 중요도 배정
struct WeeklyImportance: Identifiable, Codable, Equatable {
    let id: UUID
    let moduleId: UUID
    let weekStartDate: Date // 주의 시작일 (일요일)
    var importance: Int // 0~3
    var notes: String
    var createdAt: Date
    
    init(
        id: UUID = UUID(),
        moduleId: UUID,
        weekStartDate: Date,
        importance: Int = 1,
        notes: String = "",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.moduleId = moduleId
        self.weekStartDate = weekStartDate
        self.importance = importance
        self.notes = notes
        self.createdAt = createdAt
    }
}

