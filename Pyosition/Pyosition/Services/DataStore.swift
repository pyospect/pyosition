//
//  DataStore.swift
//  Pyosition
//

import Foundation
import Combine

// 데이터 관리 서비스
class DataStore: ObservableObject {
    static let shared = DataStore()
    
    @Published var modules: [Module] = []
    @Published var dailyStatuses: [DailyStatus] = []
    @Published var weeklyImportances: [WeeklyImportance] = []
    @Published var versionLogs: [VersionLog] = []
    
    private let modulesKey = "modules"
    private let dailyStatusesKey = "dailyStatuses"
    private let weeklyImportancesKey = "weeklyImportances"
    private let versionLogsKey = "versionLogs"
    
    private init() {
        loadData()
        
        // 초기 설정: 모듈이 없으면 기본 모듈 추가
        if modules.isEmpty {
            modules = Module.defaultModules
            saveModules()
        }
    }
    
    // MARK: - Load/Save
    
    private func loadData() {
        modules = load([Module].self, forKey: modulesKey) ?? []
        dailyStatuses = load([DailyStatus].self, forKey: dailyStatusesKey) ?? []
        weeklyImportances = load([WeeklyImportance].self, forKey: weeklyImportancesKey) ?? []
        versionLogs = load([VersionLog].self, forKey: versionLogsKey) ?? []
    }
    
    private func load<T: Decodable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
    
    private func save<T: Encodable>(_ object: T, forKey key: String) {
        guard let data = try? JSONEncoder().encode(object) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
    
    // MARK: - Modules
    
    func saveModules() {
        save(modules, forKey: modulesKey)
    }
    
    func addModule(_ module: Module) {
        modules.append(module)
        saveModules()
    }
    
    func updateModule(_ module: Module) {
        if let index = modules.firstIndex(where: { $0.id == module.id }) {
            modules[index] = module
            saveModules()
        }
    }
    
    func deleteModule(_ module: Module) {
        modules.removeAll { $0.id == module.id }
        saveModules()
    }
    
    func getActiveModules() -> [Module] {
        return modules.filter { $0.isActive }
    }
    
    // MARK: - Daily Status
    
    func saveDailyStatuses() {
        save(dailyStatuses, forKey: dailyStatusesKey)
    }
    
    func addDailyStatus(_ status: DailyStatus) {
        dailyStatuses.append(status)
        saveDailyStatuses()
    }
    
    func updateDailyStatus(_ status: DailyStatus) {
        if let index = dailyStatuses.firstIndex(where: { $0.id == status.id }) {
            dailyStatuses[index] = status
            saveDailyStatuses()
        }
    }
    
    func getDailyStatus(for moduleId: UUID, on date: Date) -> DailyStatus? {
        let calendar = Calendar.current
        return dailyStatuses.first { status in
            status.moduleId == moduleId &&
            calendar.isDate(status.date, inSameDayAs: date)
        }
    }
    
    func getWeeklyStatuses(for moduleId: UUID, weekStartDate: Date) -> [DailyStatus] {
        let calendar = Calendar.current
        let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStartDate)!
        
        return dailyStatuses.filter { status in
            status.moduleId == moduleId &&
            status.date >= weekStartDate &&
            status.date <= weekEnd
        }.sorted { $0.date < $1.date }
    }
    
    func getQuarterlyStatuses(for moduleId: UUID, quarterStartDate: Date) -> [DailyStatus] {
        let calendar = Calendar.current
        let quarterEnd = calendar.date(byAdding: .month, value: 3, to: quarterStartDate)!
        
        return dailyStatuses.filter { status in
            status.moduleId == moduleId &&
            status.date >= quarterStartDate &&
            status.date < quarterEnd
        }.sorted { $0.date < $1.date }
    }
    
    // MARK: - Weekly Importance
    
    func saveWeeklyImportances() {
        save(weeklyImportances, forKey: weeklyImportancesKey)
    }
    
    func addWeeklyImportance(_ importance: WeeklyImportance) {
        weeklyImportances.append(importance)
        saveWeeklyImportances()
    }
    
    func updateWeeklyImportance(_ importance: WeeklyImportance) {
        if let index = weeklyImportances.firstIndex(where: { $0.id == importance.id }) {
            weeklyImportances[index] = importance
            saveWeeklyImportances()
        }
    }
    
    func getWeeklyImportance(for moduleId: UUID, weekStartDate: Date) -> WeeklyImportance? {
        let calendar = Calendar.current
        return weeklyImportances.first { importance in
            importance.moduleId == moduleId &&
            calendar.isDate(importance.weekStartDate, inSameDayAs: weekStartDate)
        }
    }
    
    func getCurrentWeekImportances() -> [WeeklyImportance] {
        let weekStart = Date().startOfWeek()
        return weeklyImportances.filter { importance in
            Calendar.current.isDate(importance.weekStartDate, inSameDayAs: weekStart)
        }
    }
    
    // MARK: - Version Logs
    
    func saveVersionLogs() {
        save(versionLogs, forKey: versionLogsKey)
    }
    
    func addVersionLog(_ log: VersionLog) {
        versionLogs.append(log)
        versionLogs.sort { $0.date > $1.date }
        saveVersionLogs()
    }
}

// MARK: - Date Extensions

extension Date {
    func startOfWeek() -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return calendar.date(from: components) ?? self
    }
    
    func endOfWeek() -> Date {
        let calendar = Calendar.current
        return calendar.date(byAdding: .day, value: 6, to: startOfWeek()) ?? self
    }
    
    func startOfDay() -> Date {
        return Calendar.current.startOfDay(for: self)
    }
    
    func startOfQuarter() -> Date {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: self)
        let year = calendar.component(.year, from: self)
        
        // 분기 시작 월: 1, 4, 7, 10
        let quarterStartMonth = ((month - 1) / 3) * 3 + 1
        
        var components = DateComponents()
        components.year = year
        components.month = quarterStartMonth
        components.day = 1
        
        return calendar.date(from: components) ?? self
    }
}

