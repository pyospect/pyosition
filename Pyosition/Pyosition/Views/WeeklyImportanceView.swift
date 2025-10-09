//
//  WeeklyImportanceView.swift
//  Pyosition
//

import SwiftUI
import Charts

struct WeeklyImportanceView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var selectedWeekStart = Date().startOfWeek()
    @State private var importanceValues: [UUID: Int] = [:]
    @State private var showSaveAlert = false
    
    var activeModules: [Module] {
        return dataStore.getActiveModules()
    }
    
    var maxImportanceThreeCount: Int {
        return importanceValues.values.filter { $0 == 3 }.count
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 주 선택
            weekPickerSection
                .padding()
                .background(Color(.systemBackground))
            
            ScrollView {
                VStack(spacing: 20) {
                    // 지난 주 리포트 (캐러셀)
                    weeklyReportCarousel
                    
                    // 중요도 배정 (컴팩트)
                    compactImportanceSection
                    
                    // 저장 버튼
                    saveButton
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
        }
        .onAppear {
            loadImportanceValues()
        }
        .alert("저장 완료", isPresented: $showSaveAlert) {
            Button("확인", role: .cancel) { }
        } message: {
            Text("이번 주 중요도가 저장되었습니다")
        }
    }
    
    // MARK: - Week Picker
    
    private var weekPickerSection: some View {
        VStack(spacing: 12) {
            HStack {
                Button(action: {
                    selectedWeekStart = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: selectedWeekStart) ?? selectedWeekStart
                    loadImportanceValues()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                }
                
                Spacer()
                
                VStack(spacing: 4) {
                    Text(weekRangeText)
                        .font(.headline)
                    Text("Weekly I 배정")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: {
                    selectedWeekStart = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: selectedWeekStart) ?? selectedWeekStart
                    loadImportanceValues()
                }) {
                    Image(systemName: "chevron.right")
                        .font(.title3)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Weekly Report Carousel
    
    private var weeklyReportCarousel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("📊 지난 주 평균")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(activeModules) { module in
                        let weekStatuses = dataStore.getWeeklyStatuses(for: module.id, weekStartDate: selectedWeekStart)
                        let average = weekStatuses.isEmpty ? 0.0 : Double(weekStatuses.map { $0.statusValue }.reduce(0, +)) / Double(weekStatuses.count)
                        
                        CompactWeeklyCard(
                            module: module,
                            average: average
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Compact Importance Setting
    
    private var compactImportanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("⚖️ 이번 주 중요도")
                    .font(.headline)
                
                Spacer()
                
                Text("I=3: \(maxImportanceThreeCount)/2")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(maxImportanceThreeCount > 2 ? .red : .green)
            }
            
            // 컴팩트 슬라이더
            ForEach(activeModules) { module in
                CompactImportanceSlider(
                    module: module,
                    importance: Binding(
                        get: { importanceValues[module.id] ?? 1 },
                        set: { newValue in
                            if newValue == 3 && maxImportanceThreeCount >= 2 {
                                let currentValue = importanceValues[module.id] ?? 1
                                if currentValue != 3 {
                                    return
                                }
                            }
                            importanceValues[module.id] = newValue
                        }
                    )
                )
            }
            
            if maxImportanceThreeCount > 2 {
                Text("⚠️ I=3는 최대 2개까지")
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(8)
                    .frame(maxWidth: .infinity)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
            }
        }
    }
    
    // MARK: - Save Button
    
    private var saveButton: some View {
        Button(action: {
            saveImportances()
        }) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                Text("이번 주 중요도 저장")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(maxImportanceThreeCount <= 2 ? Color.green : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(maxImportanceThreeCount > 2)
    }
    
    // MARK: - Helpers
    
    private var weekRangeText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M/d"
        
        let start = selectedWeekStart
        let end = selectedWeekStart.endOfWeek()
        
        return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
    }
    
    private func loadImportanceValues() {
        for module in activeModules {
            if let importance = dataStore.getWeeklyImportance(for: module.id, weekStartDate: selectedWeekStart) {
                importanceValues[module.id] = importance.importance
            } else {
                importanceValues[module.id] = 1
            }
        }
    }
    
    private func saveImportances() {
        guard maxImportanceThreeCount <= 2 else { return }
        
        for module in activeModules {
            let value = importanceValues[module.id] ?? 1
            
            if let existing = dataStore.getWeeklyImportance(for: module.id, weekStartDate: selectedWeekStart) {
                var updated = existing
                updated.importance = value
                dataStore.updateWeeklyImportance(updated)
            } else {
                let importance = WeeklyImportance(
                    moduleId: module.id,
                    weekStartDate: selectedWeekStart,
                    importance: value
                )
                dataStore.addWeeklyImportance(importance)
            }
            
            // 모듈의 currentImportance도 업데이트
            var updatedModule = module
            updatedModule.currentImportance = value
            dataStore.updateModule(updatedModule)
        }
        
        showSaveAlert = true
    }
}

// MARK: - Weekly Report Card

struct WeeklyReportCard: View {
    let module: Module
    let statuses: [DailyStatus]
    let average: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: module.icon)
                    .font(.headline)
                    .foregroundColor(.green)
                
                Text(module.name)
                    .font(.headline)
                
                Spacer()
                
                Text(String(format: "평균: %.1f", average))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // 간단한 그래프
            HStack(spacing: 4) {
                ForEach(0..<7) { index in
                    VStack(spacing: 4) {
                        if index < statuses.count {
                            let value = statuses[index].statusValue
                            statusBar(value: value)
                        } else {
                            statusBar(value: 0, isEmpty: true)
                        }
                        
                        Text(dayLabel(index: index))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    private func statusBar(value: Int, isEmpty: Bool = false) -> some View {
        let height = isEmpty ? 20.0 : CGFloat((value + 2) * 10 + 20)
        let color = isEmpty ? Color.gray.opacity(0.2) : statusColor(value: value)
        
        return RoundedRectangle(cornerRadius: 4)
            .fill(color)
            .frame(height: height)
    }
    
    private func statusColor(value: Int) -> Color {
        switch value {
        case 2: return .green
        case 1: return .green.opacity(0.6)
        case 0: return .gray
        case -1: return .orange
        case -2: return .red
        default: return .gray
        }
    }
    
    private func dayLabel(index: Int) -> String {
        ["일", "월", "화", "수", "목", "금", "토"][index]
    }
}

// MARK: - Compact Weekly Card

struct CompactWeeklyCard: View {
    let module: Module
    let average: Double
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: module.icon)
                .font(.system(size: 28))
                .foregroundColor(averageColor)
            
            Text(module.name)
                .font(.caption)
                .fontWeight(.medium)
            
            Text(String(format: "%.1f", average))
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(averageColor)
        }
        .frame(width: 100)
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

// MARK: - Compact Importance Slider

struct CompactImportanceSlider: View {
    let module: Module
    @Binding var importance: Int
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: module.icon)
                .foregroundColor(importanceColor)
                .frame(width: 24)
            
            Text(module.name)
                .font(.subheadline)
                .frame(width: 60, alignment: .leading)
            
            Spacer()
            
            HStack(spacing: 8) {
                ForEach(0...3, id: \.self) { value in
                    Circle()
                        .fill(value == importance ? importanceColor : Color.gray.opacity(0.2))
                        .frame(width: 24, height: 24)
                        .overlay(
                            Text("\(value)")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(value == importance ? .white : .secondary)
                        )
                        .onTapGesture {
                            importance = value
                        }
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemBackground))
        .cornerRadius(10)
    }
    
    private var importanceColor: Color {
        switch importance {
        case 3: return .orange
        case 2: return .green
        case 1: return .mint
        case 0: return .gray
        default: return .gray
        }
    }
}

// MARK: - Importance Slider Card

struct ImportanceSliderCard: View {
    let module: Module
    @Binding var importance: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: module.icon)
                    .font(.headline)
                    .foregroundColor(importanceColor)
                    .frame(width: 32, height: 32)
                    .background(importanceColor.opacity(0.1))
                    .cornerRadius(6)
                
                Text(module.name)
                    .font(.headline)
                
                Spacer()
                
                Text("I=\(importance)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(importanceColor)
            }
            
            HStack(spacing: 12) {
                Text("0")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Slider(
                    value: Binding(
                        get: { Double(importance) },
                        set: { importance = Int($0.rounded()) }
                    ),
                    in: 0...3,
                    step: 1
                )
                .accentColor(importanceColor)
                
                Text("3")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 8) {
                ForEach(0...3, id: \.self) { value in
                    Circle()
                        .fill(value == importance ? importanceColor : Color.gray.opacity(0.2))
                        .frame(width: 12, height: 12)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    private var importanceColor: Color {
        switch importance {
        case 3: return .orange
        case 2: return .green
        case 1: return .mint
        case 0: return .gray
        default: return .gray
        }
    }
}

