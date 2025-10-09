//
//  VersionLog.swift
//  Pyosition
//

import Foundation

// 버전 로그 (패치노트 형식)
struct VersionLog: Identifiable, Codable, Equatable {
    let id: UUID
    let date: Date
    var version: String // "v25.08.20" 형식
    var statusChanges: [String] // S 변경사항들
    var importanceSettings: [String] // I 설정사항들
    var improvements: [String] // 개선사항
    var createdAt: Date
    
    init(
        id: UUID = UUID(),
        date: Date = Date(),
        version: String = "",
        statusChanges: [String] = [],
        importanceSettings: [String] = [],
        improvements: [String] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.date = date
        self.version = version
        self.statusChanges = statusChanges
        self.importanceSettings = importanceSettings
        self.improvements = improvements
        self.createdAt = createdAt
    }
    
    // 자동으로 버전 문자열 생성
    static func generateVersion(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yy.MM.dd"
        return "v\(formatter.string(from: date))"
    }
}

