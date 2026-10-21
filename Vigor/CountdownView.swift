//
//  CountdownView.swift
//  Vigor
//
//  Created by Alp Rüzgar on 15.10.2026.
//

import SwiftUI

/// Aktivite başlamadan önce tam ekran 3-2-1-GO geri sayımı.
/// Geri sayım bitince `onFinish`, iptal edilirse `onCancel` çağrılır.
struct CountdownView: View {
    private let from = 3
    let onFinish: () -> Void
    let onCancel: () -> Void

    @State private var count: Int? = 3   // nil = "GO"

    var body: some View {
        ZStack {
            Color.coldBlack
                .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                Text(count.map(String.init) ?? "GO")
                    .font(.spaceGroteskBold(size: 160))
                    .foregroundStyle(count == nil ? Color.electricLime : .white)
                    .contentTransition(.numericText(countsDown: true))
                    .id(count) // her sayı yeni görünüm olsun ki geçiş animasyonu çalışsın
                    .transition(.scale(scale: 1.6).combined(with: .opacity))

                Spacer()

                Button("Cancel") {
                    onCancel()
                }
                .buttonStyle(.neon(foregroundColor: .coldBlack, backgroundColor: .voltRed))
                .padding()
            }
        }
        .sensoryFeedback(.impact(weight: .heavy), trigger: count)
        .task {
            // View kaldırılırsa (iptal) Task.sleep hata fırlatır ve onFinish çağrılmaz
            do {
                for n in stride(from: from, through: 1, by: -1) {
                    withAnimation(.spring(duration: 0.4)) { count = n }
                    try await Task.sleep(for: .seconds(1))
                }
                withAnimation(.spring(duration: 0.4)) { count = nil }
                try await Task.sleep(for: .seconds(0.6))
                onFinish()
            } catch {
                return
            }
        }
    }
}

#Preview {
    CountdownView(onFinish: {}, onCancel: {})
}
