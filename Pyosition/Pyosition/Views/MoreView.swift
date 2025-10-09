//
//  MoreView.swift
//  Pyosition
//
//  모듈 관리 + 설정 통합

import SwiftUI

struct MoreView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var showAddModule = false
    @State private var showOnboarding = false
    @State private var showAbout = false
    @State private var showResetAlert = false
    @State private var resetConfirmText = ""
    
    var body: some View {
        NavigationView {
            List {
                // 모듈 관리
                Section {
                    ForEach(dataStore.modules) { module in
                        NavigationLink(destination: ModuleEditView(module: module)) {
                            HStack(spacing: 12) {
                                Image(systemName: module.icon)
                                    .foregroundColor(.green)
                                    .frame(width: 24)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(module.name)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    
                                    Text(module.policy.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                if !module.isActive {
                                    Text("비활성")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.gray.opacity(0.1))
                                        .cornerRadius(4)
                                }
                            }
                        }
                    }
                    
                    Button(action: {
                        showAddModule = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.green)
                            Text("새 모듈 추가")
                                .foregroundColor(.primary)
                        }
                    }
                } header: {
                    Text("모듈 관리")
                } footer: {
                    Text("모듈을 추가, 수정, 비활성화할 수 있습니다.")
                }
                
                // 도움말
                Section {
                    NavigationLink(destination: HowToUseView()) {
                        Label("사용법", systemImage: "book")
                    }
                    
                    NavigationLink(destination: ConceptGuideView()) {
                        Label("개념 가이드", systemImage: "lightbulb")
                    }
                    
                    Button(action: {
                        showOnboarding = true
                    }) {
                        Label("온보딩 다시보기", systemImage: "arrow.clockwise")
                    }
                } header: {
                    Text("도움말")
                }
                
                // 정보
                Section {
                    Button(action: {
                        showAbout = true
                    }) {
                        Label("앱 정보", systemImage: "info.circle")
                    }
                } header: {
                    Text("정보")
                }
                
                // 데이터
                Section {
                    Button(role: .destructive, action: {
                        showResetAlert = true
                    }) {
                        Label("모든 데이터 초기화", systemImage: "trash.fill")
                    }
                } header: {
                    Text("데이터")
                } footer: {
                    Text("모든 기록이 삭제되며 복구할 수 없습니다.")
                }
            }
            .navigationTitle("더보기")
            .sheet(isPresented: $showAddModule) {
                ModuleAddView()
                    .environmentObject(dataStore)
            }
            .sheet(isPresented: $showOnboarding) {
                OnboardingView(isPresented: $showOnboarding)
            }
            .sheet(isPresented: $showAbout) {
                AboutView(isPresented: $showAbout)
            }
            .alert("모든 데이터 초기화", isPresented: $showResetAlert) {
                TextField("'초기화' 입력", text: $resetConfirmText)
                Button("취소", role: .cancel) {
                    resetConfirmText = ""
                }
                Button("초기화", role: .destructive) {
                    if resetConfirmText == "초기화" {
                        resetAllData()
                    }
                    resetConfirmText = ""
                }
            } message: {
                Text("모든 기록, 모듈, 설정이 삭제됩니다.\n정말 초기화하려면 '초기화'를 입력하세요.")
            }
        }
    }
    
    private func resetAllData() {
        dataStore.modules = Module.defaultModules
        dataStore.dailyStatuses = []
        dataStore.weeklyImportances = []
        dataStore.versionLogs = []
        
        dataStore.saveModules()
        dataStore.saveDailyStatuses()
        dataStore.saveWeeklyImportances()
        dataStore.saveVersionLogs()
        
        UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
    }
}

// MARK: - Module Edit View

struct ModuleEditView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.dismiss) var dismiss
    
    let module: Module
    @State private var name: String
    @State private var icon: String
    @State private var policy: InterpretationPolicy
    @State private var isActive: Bool
    @State private var showDeleteAlert = false
    
    init(module: Module) {
        self.module = module
        _name = State(initialValue: module.name)
        _icon = State(initialValue: module.icon)
        _policy = State(initialValue: module.policy)
        _isActive = State(initialValue: module.isActive)
    }
    
    var body: some View {
        Form {
            Section {
                TextField("모듈 이름", text: $name)
                
                HStack {
                    Text("아이콘")
                    Spacer()
                    Image(systemName: icon)
                        .foregroundColor(.green)
                }
                
                Picker("해석 정책", selection: $policy) {
                    ForEach(InterpretationPolicy.allCases, id: \.self) { p in
                        Text(p.description).tag(p)
                    }
                }
                
                Toggle("활성화", isOn: $isActive)
            }
            
            Section {
                Button("저장") {
                    saveModule()
                }
                .disabled(name.isEmpty)
            }
            
            Section {
                Button("모듈 삭제", role: .destructive) {
                    showDeleteAlert = true
                }
            }
        }
        .navigationTitle("모듈 수정")
        .navigationBarTitleDisplayMode(.inline)
        .alert("모듈 삭제", isPresented: $showDeleteAlert) {
            Button("취소", role: .cancel) { }
            Button("삭제", role: .destructive) {
                deleteModule()
            }
        } message: {
            Text("이 모듈과 관련된 모든 기록이 삭제됩니다.")
        }
    }
    
    private func saveModule() {
        var updated = module
        updated.name = name
        updated.icon = icon
        updated.policy = policy
        updated.isActive = isActive
        dataStore.updateModule(updated)
        dismiss()
    }
    
    private func deleteModule() {
        dataStore.deleteModule(module)
        dismiss()
    }
}

// MARK: - Module Add View

struct ModuleAddView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.dismiss) var dismiss
    
    @State private var name = ""
    @State private var icon = "star.fill"
    @State private var policy: InterpretationPolicy = .moreIsBetter
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("모듈 이름", text: $name)
                    
                    HStack {
                        Text("아이콘")
                        Spacer()
                        Image(systemName: icon)
                            .foregroundColor(.green)
                    }
                    
                    Picker("해석 정책", selection: $policy) {
                        ForEach(InterpretationPolicy.allCases, id: \.self) { p in
                            Text(p.description).tag(p)
                        }
                    }
                }
                
                Section {
                    Button("추가") {
                        addModule()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .navigationTitle("새 모듈")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("취소") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func addModule() {
        let newModule = Module(
            name: name,
            icon: icon,
            policy: policy
        )
        dataStore.addModule(newModule)
        dismiss()
    }
}
