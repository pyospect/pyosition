//
//  DailyStatus.swift
//  Pyosition
//

import Foundation

// 일일 상태 기록
struct DailyStatus: Identifiable, Codable, Equatable {
    let id: UUID
    let moduleId: UUID
    let date: Date
    var statusValue: Int // -2 ~ +2
    var memo: String
    var createdAt: Date
    
    init(
        id: UUID = UUID(),
        moduleId: UUID,
        date: Date = Date(),
        statusValue: Int = 0,
        memo: String = "",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.moduleId = moduleId
        self.date = date
        self.statusValue = statusValue
        self.memo = memo
        self.createdAt = createdAt
    }
    
    // 경고가 필요한지 체크
    var needsAlert: Bool {
        return abs(statusValue) == 2
    }
    
    // 상태값에 대한 색상
    var statusColor: String {
        switch statusValue {
        case 2: return "green"
        case 1: return "lightGreen"
        case 0: return "gray"
        case -1: return "lightRed"
        case -2: return "red"
        default: return "gray"
        }
    }
}

