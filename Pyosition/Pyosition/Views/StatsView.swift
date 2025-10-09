//
//  StatsView.swift
//  Pyosition
//
//  통계 - 리포트 + 히스토리 통합

import SwiftUI

struct StatsView: View {
    @EnvironmentObject var dataStore: DataStore
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 리포트 섹션
                    ReportSection()
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // 히스토리 섹션
                    HistorySection()
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("통계")
        }
    }
}

// MARK: - Report Section

struct ReportSection: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var selectedPeriod = 0 // 0: 주간, 1: 분기
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("📊 리포트")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Picker("", selection: $selectedPeriod) {
                    Text("주간").tag(0)
                    Text("분기").tag(1)
                }
                .pickerStyle(.segmented)
                .frame(width: 140)
            }
            
            if selectedPeriod == 0 {
                WeeklyReportContent()
            } else {
                QuarterlyReportContent()
            }
        }
    }
}

// MARK: - Weekly Report Content

struct WeeklyReportContent: View {
    @EnvironmentObject var dataStore: DataStore
    
    var weekStart: Date {
        Date().startOfWeek()
    }
    
    var activeModules: [Module] {
        dataStore.getActiveModules()
    }
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach(activeModules) { module in
                let weekStatuses = dataStore.getWeeklyStatuses(for: module.id, weekStartDate: weekStart)
                let average = weekStatuses.isEmpty ? 0.0 : Double(weekStatuses.map { $0.statusValue }.reduce(0, +)) / Double(weekStatuses.count)
                
                WeeklyModuleCard(module: module, average: average, statusCount: weekStatuses.count)
            }
        }
    }
}

struct WeeklyModuleCard: View {
    let module: Module
    let average: Double
    let statusCount: Int
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: module.icon)
                .font(.title2)
                .foregroundColor(averageColor)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(module.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("평균: \(String(format: "%.1f", average))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("\(statusCount)일")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    private var averageColor: Color {
        switch average {
        case 1.5...2.0: return .green
        case 0.5..<1.5: return .mint
        case -0.5..<0.5: return .gray
        case -1.5..<(-0.5): return .orange
        default: return .red
        }
    }
}

// MARK: - Quarterly Report Content

struct QuarterlyReportContent: View {
    @EnvironmentObject var dataStore: DataStore
    
    var quarterStart: Date {
        Date().startOfQuarter()
    }
    
    var activeModules: [Module] {
        dataStore.getActiveModules()
    }
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach(activeModules) { module in
                let quarterStatuses = dataStore.getQuarterlyStatuses(for: module.id, quarterStartDate: quarterStart)
                let average = quarterStatuses.isEmpty ? 0.0 : Double(quarterStatuses.map { $0.statusValue }.reduce(0, +)) / Double(quarterStatuses.count)
                let extremeCount = quarterStatuses.filter { abs($0.statusValue) == 2 }.count
                
                QuarterlyModuleCard(
                    module: module,
                    average: average,
                    statusCount: quarterStatuses.count,
                    extremeCount: extremeCount
                )
            }
        }
    }
}

struct QuarterlyModuleCard: View {
    let module: Module
    let average: Double
    let statusCount: Int
    let extremeCount: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: module.icon)
                    .font(.title2)
                    .foregroundColor(averageColor)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(module.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("평균: \(String(format: "%.1f", average))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(statusCount)일")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if extremeCount > 0 {
                        Text("⚠️ \(extremeCount)회")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    private var averageColor: Color {
        switch average {
        case 1.5...2.0: return .green
        case 0.5..<1.5: return .mint
        case -0.5..<0.5: return .gray
        case -1.5..<(-0.5): return .orange
        default: return .red
        }
    }
}

// MARK: - History Section

struct HistorySection: View {
    @EnvironmentObject var dataStore: DataStore
    
    var recentActivities: [(date: Date, type: String, details: String)] {
        var activities: [(Date, String, String)] = []
        
        let recentStatuses = dataStore.dailyStatuses
            .sorted { $0.createdAt > $1.createdAt }
            .prefix(10)
        
        for status in recentStatuses {
            if let module = dataStore.modules.first(where: { $0.id == status.moduleId }) {
                let valueText = status.statusValue > 0 ? "+\(status.statusValue)" : "\(status.statusValue)"
                activities.append((
                    status.createdAt,
                    "상태 기록",
                    "\(module.name) \(valueText)"
                ))
            }
        }
        
        let recentImportances = dataStore.weeklyImportances
            .sorted { $0.createdAt > $1.createdAt }
            .prefix(5)
        
        for importance in recentImportances {
            if let module = dataStore.modules.first(where: { $0.id == importance.moduleId }) {
                activities.append((
                    importance.createdAt,
                    "중요도 배정",
                    "\(module.name) I=\(importance.importance)"
                ))
            }
        }
        
        return activities.sorted { $0.0 > $1.0 }.prefix(15).map { $0 }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("🕐 최근 활동")
                .font(.title2)
                .fontWeight(.bold)
            
            if recentActivities.isEmpty {
                EmptyHistoryView()
            } else {
                ForEach(Array(recentActivities.enumerated()), id: \.offset) { index, activity in
                    CompactActivityCard(
                        date: activity.date,
                        type: activity.type,
                        details: activity.details
                    )
                }
            }
        }
    }
}

struct EmptyHistoryView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock")
                .font(.system(size: 40))
                .foregroundColor(.gray)
            
            Text("기록이 없습니다")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct CompactActivityCard: View {
    let date: Date
    let type: String
    let details: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: type == "상태 기록" ? "pencil.circle.fill" : "star.circle.fill")
                .foregroundColor(type == "상태 기록" ? .green : .orange)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(details)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(timeAgo)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemBackground))
        .cornerRadius(10)
    }
    
    private var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
