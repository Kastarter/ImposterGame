//
//  PrimaryButton.swift
//  ImpostorGame
//
//  Created by Khalid Sh on 1/2/26.
//

import SwiftUI

struct PrimaryButton: View {
    let title: String
    let icon: String?
    let style: ButtonStyleType
    let action: () -> Void
    
    @State private var isPressed = false
    
    enum ButtonStyleType {
        case primary
        case secondary
        case destructive
        case ghost
        
        var backgroundColor: Color {
            switch self {
            case .primary:
                return .accentColor
            case .secondary:
                return Color(.systemGray5)
            case .destructive:
                return .red
            case .ghost:
                return .clear
            }
        }
        
        var foregroundColor: Color {
            switch self {
            case .primary, .destructive:
                return .white
            case .secondary:
                return .primary
            case .ghost:
                return .accentColor
            }
        }
    }
    
    init(
        _ title: String,
        icon: String? = nil,
        style: ButtonStyleType = .primary,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.action = action
    }
    
    var body: some View {
        Button {
            hapticFeedback(.medium)
            action()
        } label: {
            HStack(spacing: 12) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.title3.weight(.semibold))
                }
                
                Text(title)
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(style.backgroundColor)
            .foregroundStyle(style.foregroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay {
                if style == .ghost {
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.accentColor, lineWidth: 2)
                }
            }
            .scaleEffect(isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
    
    private func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
}

// MARK: - Icon Button
struct IconButton: View {
    let icon: String
    let size: CGFloat
    let color: Color
    let action: () -> Void
    
    init(
        icon: String,
        size: CGFloat = 24,
        color: Color = .primary,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.size = size
        self.color = color
        self.action = action
    }
    
    var body: some View {
        Button {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            action()
        } label: {
            Image(systemName: icon)
                .font(.system(size: size, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        PrimaryButton("لعبة جديدة", icon: "plus.circle.fill") {
            print("Tapped")
        }
        
        PrimaryButton("انضم للعبة", icon: "person.2.fill", style: .secondary) {
            print("Tapped")
        }
        
        PrimaryButton("طرد", style: .destructive) {
            print("Tapped")
        }
        
        PrimaryButton("إلغاء", style: .ghost) {
            print("Tapped")
        }
    }
    .padding()
    .rtl()
}

