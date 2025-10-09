//
//  CompactDailyStatusView.swift
//  Pyosition
//
//  홈에서 바텀시트로 열리는 컴팩트한 상태 기록 화면

import SwiftUI

struct CompactDailyStatusView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.dismiss) var dismiss
    @Binding var selectedDate: Date
    
    @State private var showDatePicker = false
    @State private var statusValues: [UUID: Int] = [:]
    @State private var memos: [UUID: String] = [:]
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var activeModules: [Module] {
        return dataStore.getActiveModules()
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 날짜 선택 헤더 (컴팩트)
                dateHeader
                
                // 모듈 슬라이더 리스트
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(activeModules) { module in
                            CompactModuleEntry(
                                module: module,
                                statusValue: Binding(
                                    get: { statusValues[module.id] ?? 0 },
                                    set: { statusValues[module.id] = $0 }
                                ),
                                memo: Binding(
                                    get: { memos[module.id] ?? "" },
                                    set: { memos[module.id] = $0 }
                                )
                            )
                        }
                    }
                    .padding()
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("상태 기록")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("저장") {
                        saveStatuses()
                    }
                    .fontWeight(.semibold)
                }
            }
            .alert("알림", isPresented: $showAlert) {
                Button("확인", role: .cancel) {
                    dismiss()
                }
            } message: {
                Text(alertMessage)
            }
            .onAppear {
                loadExistingStatuses()
            }
        }
    }
    
    // MARK: - Date Header
    
    private var dateHeader: some View {
        Button(action: {
            showDatePicker = true
        }) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.green)
                
                Text(formattedDate)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Image(systemName: "chevron.down")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if Calendar.current.isDateInToday(selectedDate) {
                    Text("오늘")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green)
                        .cornerRadius(8)
                }
            }
            .padding()
            .background(Color(.systemBackground))
        }
        .sheet(isPresented: $showDatePicker) {
            DatePickerSheet(selectedDate: $selectedDate)
        }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일 (E)"
        return formatter.string(from: selectedDate)
    }
    
    // MARK: - Actions
    
    private func loadExistingStatuses() {
        for module in activeModules {
            if let existing = dataStore.getDailyStatus(for: module.id, on: selectedDate) {
                statusValues[module.id] = existing.statusValue
                memos[module.id] = existing.memo
            } else {
                statusValues[module.id] = 0
                memos[module.id] = ""
            }
        }
    }
    
    private func saveStatuses() {
        var alertCount = 0
        
        for module in activeModules {
            let value = statusValues[module.id] ?? 0
            let memo = memos[module.id] ?? ""
            
            if let existing = dataStore.getDailyStatus(for: module.id, on: selectedDate) {
                var updated = existing
                updated.statusValue = value
                updated.memo = memo
                dataStore.updateDailyStatus(updated)
            } else {
                let status = DailyStatus(
                    moduleId: module.id,
                    date: selectedDate,
                    statusValue: value,
                    memo: memo
                )
                dataStore.addDailyStatus(status)
            }
            
            if abs(value) == 2 {
                alertCount += 1
            }
        }
        
        if alertCount > 0 {
            alertMessage = "⚠️ \(alertCount)개 모듈이 극단적 상태입니다."
            showAlert = true
        } else {
            dismiss()
        }
    }
}

// MARK: - Date Picker Sheet

struct DatePickerSheet: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedDate: Date
    
    var body: some View {
        NavigationView {
            VStack {
                DatePicker(
                    "",
                    selection: $selectedDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .padding()
                
                Spacer()
            }
            .navigationTitle("날짜 선택")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("완료") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Compact Module Entry

struct CompactModuleEntry: View {
    let module: Module
    @Binding var statusValue: Int
    @Binding var memo: String
    @State private var showMemo = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: module.icon)
                    .foregroundColor(.green)
                
                Text(module.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text(statusText)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(statusColor)
                    .frame(minWidth: 40)
            }
            
            // 슬라이더
            HStack(spacing: 8) {
                Text("-2")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Slider(
                    value: Binding(
                        get: { Double(statusValue) },
                        set: { statusValue = Int($0.rounded()) }
                    ),
                    in: -2...2,
                    step: 1
                )
                .accentColor(statusColor)
                
                Text("+2")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            // 점 인디케이터
            HStack(spacing: 6) {
                ForEach(-2...2, id: \.self) { value in
                    Circle()
                        .fill(value == statusValue ? statusColor : Color.gray.opacity(0.2))
                        .frame(width: 8, height: 8)
                }
            }
            .frame(maxWidth: .infinity)
            
            // 메모 토글
            Button(action: {
                showMemo.toggle()
            }) {
                HStack {
                    Image(systemName: showMemo ? "note.text" : "note")
                        .font(.caption)
                    Text(memo.isEmpty ? "메모 추가" : "메모")
                        .font(.caption)
                    Spacer()
                }
                .foregroundColor(.secondary)
            }
            
            if showMemo {
                TextField("메모 입력...", text: $memo)
                    .textFieldStyle(.roundedBorder)
                    .font(.caption)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    private var statusText: String {
        if statusValue > 0 {
            return "+\(statusValue)"
        } else if statusValue == 0 {
            return "0"
        } else {
            return "\(statusValue)"
        }
    }
    
    private var statusColor: Color {
        let interpreted = module.policy.interpretScore(statusValue)
        switch interpreted {
        case 3.5...4.0: return .green
        case 2.5..<3.5: return .green.opacity(0.6)
        case 1.5..<2.5: return .gray
        case 0.5..<1.5: return .orange
        default: return .red
        }
    }
}

