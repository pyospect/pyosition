//
//  HomeView.swift
//  Pyosition
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var showDailyStatusSheet = false
    @State private var showDatePicker = false
    @State private var selectedDate = Date()
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var todayStatuses: [DailyStatus] {
        let today = Date().startOfDay()
        return dataStore.dailyStatuses.filter { status in
            Calendar.current.isDate(status.date, inSameDayAs: today)
        }
    }
    
    var currentWeekImportances: [WeeklyImportance] {
        return dataStore.getCurrentWeekImportances()
    }
    
    var highPriorityModules: [Module] {
        let weekStart = Date().startOfWeek()
        return dataStore.getActiveModules().filter { module in
            if let importance = dataStore.getWeeklyImportance(for: module.id, weekStartDate: weekStart) {
                return importance.importance == 3
            }
            return false
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 헤더
                headerSection
                
                // 이번 주 중요도
                weeklyImportanceSection
                
                // 오늘의 집중 모듈 (I=3) - 격자형
                if !highPriorityModules.isEmpty {
                    focusModulesGridSection
                }
                
                // 오늘의 상태 요약 - 격자형
                todayStatusGridSection
                
                // Quick Action 버튼
                quickActionsSection
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(formattedDate)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("삶을 통제 가능한 시스템으로")
                .font(.title2)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Weekly Importance Section
    
    private var weeklyImportanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("⭐ 이번 주 중요도")
                .font(.headline)
            
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(dataStore.getActiveModules()) { module in
                    let weekStart = Date().startOfWeek()
                    let importance = dataStore.getWeeklyImportance(for: module.id, weekStartDate: weekStart)?.importance ?? 1
                    
                    VStack(spacing: 8) {
                        Image(systemName: module.icon)
                            .font(.system(size: 24))
                            .foregroundColor(importanceColor(importance))
                        
                        Text(module.name)
                            .font(.caption)
                            .fontWeight(.medium)
                        
                        Text("I=\(importance)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(importanceColor(importance))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                }
            }
        }
    }
    
    private func importanceColor(_ value: Int) -> Color {
        switch value {
        case 3: return .orange
        case 2: return .green
        case 1: return .mint
        case 0: return .gray
        default: return .gray
        }
    }
    
    // MARK: - Focus Modules Grid Section
    
    private var focusModulesGridSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("🎯 이번 주 집중")
                .font(.headline)
            
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(highPriorityModules) { module in
                    VStack(spacing: 12) {
                        Image(systemName: module.icon)
                            .font(.system(size: 36))
                            .foregroundColor(.orange)
                        
                        Text(module.name)
                            .font(.headline)
                        
                        Text("I=3")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Color.orange)
                            .cornerRadius(12)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                }
            }
        }
    }
    
    // MARK: - Today Status Grid Section
    
    private var todayStatusGridSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("📊 오늘의 상태")
                .font(.headline)
            
            if todayStatuses.isEmpty {
                emptyStateView
            } else {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(todayStatuses) { status in
                        if let module = dataStore.modules.first(where: { $0.id == status.moduleId }) {
                            StatusGridCard(module: module, status: status)
                        }
                    }
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "pencil.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("아직 오늘의 기록이 없습니다")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("저녁에 5분만 투자하여\n오늘 하루를 기록해보세요")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Quick Actions
    
    private var quickActionsSection: some View {
        VStack(spacing: 12) {
            Button(action: {
                selectedDate = Date()
                showDailyStatusSheet = true
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                    Text("오늘 상태 기록하기")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
        }
        .sheet(isPresented: $showDailyStatusSheet) {
            CompactDailyStatusView(selectedDate: $selectedDate)
                .environmentObject(dataStore)
        }
    }
    
    // MARK: - Helpers
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 M월 d일 EEEE"
        return formatter.string(from: Date())
    }
}

// MARK: - Status Grid Card

struct StatusGridCard: View {
    let module: Module
    let status: DailyStatus
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: module.icon)
                .font(.system(size: 32))
                .foregroundColor(statusColor)
            
            Text(module.name)
                .font(.subheadline)
                .fontWeight(.semibold)
            
            Text(statusText)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(statusColor)
            
            if !status.memo.isEmpty {
                Text(status.memo)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    private var statusText: String {
        let value = status.statusValue
        if value > 0 {
            return "+\(value)"
        } else {
            return "\(value)"
        }
    }
    
    private var statusColor: Color {
        switch status.statusValue {
        case 2: return .green
        case 1: return .green.opacity(0.6)
        case 0: return .gray
        case -1: return .orange
        case -2: return .red
        default: return .gray
        }
    }
}

