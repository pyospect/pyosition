//
//  OnboardingView.swift
//  Pyosition
//

import SwiftUI

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @State private var currentPage = 0
    
    let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "chart.line.uptrend.xyaxis",
            title: "Pyosition에 오신 걸 환영합니다",
            description: "삶을 통제 가능한 시스템으로 설계하세요.\n매일 기록하고, 주간 계획하고, 꾸준히 개선합니다.",
            color: .green
        ),
        OnboardingPage(
            icon: "slider.horizontal.3",
            title: "Daily S (상태 기록)",
            description: "매일 저녁, 각 모듈의 상태를 -2~+2로 기록하세요.\n\n-2: 매우 나쁨\n-1: 조금 나쁨\n 0: 보통\n+1: 조금 좋음\n+2: 매우 좋음",
            color: .blue
        ),
        OnboardingPage(
            icon: "star.fill",
            title: "Weekly I (중요도 배정)",
            description: "매주 일요일, 다음 주에 집중할 모듈을 선택하세요.\n\n0: 관심 없음\n1: 약간 중요\n2: 중요\n3: 최우선 (최대 2개)",
            color: .orange
        ),
        OnboardingPage(
            icon: "square.grid.2x2",
            title: "모듈은 자유롭게",
            description: "기본 7개 모듈(건강, 음식, 수면, 돈, 관계, 일, 취미)로 시작하되,\n\n언제든 추가하거나 삭제할 수 있습니다.\n당신의 삶에 맞게 커스터마이징하세요.",
            color: .green
        )
    ]
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 페이지 컨텐츠
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // 하단 컨트롤
                VStack(spacing: 20) {
                    // 페이지 인디케이터
                    HStack(spacing: 8) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            Circle()
                                .fill(currentPage == index ? Color.green : Color.gray.opacity(0.3))
                                .frame(width: 8, height: 8)
                                .animation(.easeInOut, value: currentPage)
                        }
                    }
                    
                    // 버튼
                    HStack(spacing: 16) {
                        if currentPage > 0 {
                            Button(action: {
                                withAnimation {
                                    currentPage -= 1
                                }
                            }) {
                                Text("이전")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.gray.opacity(0.2))
                                    .foregroundColor(.primary)
                                    .cornerRadius(12)
                            }
                        }
                        
                        Button(action: {
                            if currentPage < pages.count - 1 {
                                withAnimation {
                                    currentPage += 1
                                }
                            } else {
                                UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                                isPresented = false
                            }
                        }) {
                            Text(currentPage < pages.count - 1 ? "다음" : "시작하기")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                    
                    // 건너뛰기
                    if currentPage < pages.count - 1 {
                        Button(action: {
                            UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                            isPresented = false
                        }) {
                            Text("건너뛰기")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .interactiveDismissDisabled()
    }
}

struct OnboardingPage {
    let icon: String
    let title: String
    let description: String
    let color: Color
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // 아이콘
            Image(systemName: page.icon)
                .font(.system(size: 80))
                .foregroundColor(page.color)
                .padding(.bottom, 20)
            
            // 제목
            Text(page.title)
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // 설명
            Text(page.description)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .lineSpacing(8)
            
            Spacer()
            Spacer()
        }
    }
}

