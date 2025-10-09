//
//  Module.swift
//  Pyosition
//

import Foundation
import SwiftUI

// 해석 정책 타입
enum InterpretationPolicy: String, Codable, CaseIterable {
    case optimal = "최적대역형"
    case lessIsBetter = "적을수록 좋음"
    case moreIsBetter = "많을수록 좋음"
    
    var description: String {
        return self.rawValue
    }
    
    // 점수를 해석 정책에 따라 변환 (-2~+2 → 실제 점수)
    func interpretScore(_ rawScore: Int) -> Double {
        switch self {
        case .optimal:
            // 최적대역형: 0에 가까울수록 좋음 (절대값이 작을수록 높은 점수)
            return Double(2 - abs(rawScore))
        case .lessIsBetter:
            // 적을수록 좋음: -2가 최고, +2가 최악
            return Double(2 - rawScore) // -2→4, -1→3, 0→2, 1→1, 2→0
        case .moreIsBetter:
            // 많을수록 좋음: +2가 최고, -2가 최악
            return Double(rawScore + 2) // -2→0, -1→1, 0→2, 1→3, 2→4
        }
    }
    
    // 점수 컬러 (정책 고려)
    func scoreColor(_ rawScore: Int) -> String {
        let interpreted = interpretScore(rawScore)
        switch interpreted {
        case 3.5...4.0: return "green"      // 매우 좋음
        case 2.5..<3.5: return "lightGreen" // 좋음
        case 1.5..<2.5: return "gray"       // 보통
        case 0.5..<1.5: return "orange"     // 나쁨
        default: return "red"                // 매우 나쁨
        }
    }
}

// 모듈 모델
struct Module: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var icon: String
    var policy: InterpretationPolicy
    var currentImportance: Int // 0~3
    var isActive: Bool
    var createdAt: Date
    
    init(
        id: UUID = UUID(),
        name: String,
        icon: String,
        policy: InterpretationPolicy = .optimal,
        currentImportance: Int = 1,
        isActive: Bool = true,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.policy = policy
        self.currentImportance = currentImportance
        self.isActive = isActive
        self.createdAt = createdAt
    }
    
    // 기본 제공 모듈들
    static let defaultModules: [Module] = [
        Module(name: "건강", icon: "heart.fill"),
        Module(name: "음식", icon: "fork.knife"),
        Module(name: "수면", icon: "moon.fill"),
        Module(name: "돈", icon: "dollarsign.circle.fill"),
        Module(name: "관계", icon: "person.2.fill"),
        Module(name: "일", icon: "briefcase.fill"),
        Module(name: "취미", icon: "star.fill")
    ]
}

