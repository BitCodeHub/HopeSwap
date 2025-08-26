import SwiftUI

struct ListingMenuSheet: View {
    let item: Item
    let isOwnItem: Bool
    @Environment(\.dismiss) var dismiss
    @Binding var showingEditFlow: Bool
    @Binding var showingDeleteAlert: Bool
    @Binding var showingInsights: Bool
    
    var body: some View {
        ZStack {
            Color.hopeDarkBg
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Drag indicator
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.gray.opacity(0.5))
                    .frame(width: 40, height: 5)
                    .padding(.top, 12)
                
                // Menu options
                VStack(spacing: 0) {
                    if isOwnItem {
                        MenuOption(
                            icon: "pencil",
                            title: "Edit listing",
                            action: {
                                dismiss()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    showingEditFlow = true
                                }
                            }
                        )
                        
                        Divider()
                            .background(Color.gray.opacity(0.2))
                        
                        MenuOption(
                            icon: "trash",
                            title: "Delete listing",
                            textColor: .red,
                            iconColor: .red,
                            action: {
                                dismiss()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    showingDeleteAlert = true
                                }
                            }
                        )
                        
                        Divider()
                            .background(Color.gray.opacity(0.2))
                    }
                    
                    MenuOption(
                        icon: "chart.bar",
                        title: "Marketplace insights",
                        action: {
                            dismiss()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                showingInsights = true
                            }
                        }
                    )
                    
                    Divider()
                        .background(Color.gray.opacity(0.2))
                    
                    MenuOption(
                        icon: "square.and.arrow.up",
                        title: "Share",
                        action: {
                            // TODO: Implement share functionality
                            dismiss()
                        }
                    )
                    
                    if !isOwnItem {
                        Divider()
                            .background(Color.gray.opacity(0.2))
                        
                        MenuOption(
                            icon: "flag",
                            title: "Report",
                            textColor: .red,
                            iconColor: .red,
                            action: {
                                // TODO: Implement report functionality
                                dismiss()
                            }
                        )
                    }
                }
                .padding(.vertical, 20)
                
                // Cancel button
                Button(action: { dismiss() }) {
                    Text("Cancel")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.hopeDarkSecondary)
                        .cornerRadius(12)
                }
                .padding()
            }
        }
    }
}

struct MenuOption: View {
    let icon: String
    let title: String
    var textColor: Color = .white
    var iconColor: Color = .white
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(iconColor)
                    .frame(width: 24)
                
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(textColor)
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
    }
}