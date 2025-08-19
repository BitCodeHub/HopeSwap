import SwiftUI
import PhotosUI

// MARK: - Category Grid for Freebies/Need Help flows

struct CategoryGrid: View {
    @Binding var selectedCategory: Category
    
    let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(Category.allCases, id: \.self) { category in
                Button(action: { selectedCategory = category }) {
                    Text(category.rawValue)
                        .font(.caption)
                        .foregroundColor(selectedCategory == category ? Color.hopeDarkBg : .white)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedCategory == category ? Color.hopeOrange : Color.hopeDarkSecondary)
                        )
                }
            }
        }
    }
}

// MARK: - Condition Picker for Freebies flow

struct ConditionPicker: View {
    @Binding var selectedCondition: Condition
    var showPrice: Bool = true
    
    var body: some View {
        VStack(spacing: 8) {
            ForEach(Condition.allCases, id: \.self) { condition in
                Button(action: { selectedCondition = condition }) {
                    HStack {
                        Circle()
                            .fill(conditionColor(condition))
                            .frame(width: 12, height: 12)
                        
                        Text(condition.rawValue)
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        if selectedCondition == condition {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(conditionColor(condition))
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(selectedCondition == condition ? conditionColor(condition).opacity(0.2) : Color.hopeDarkSecondary)
                    )
                }
            }
        }
    }
    
    func conditionColor(_ condition: Condition) -> Color {
        switch condition {
        case .new: return Color.hopeGreen
        case .likeNew: return Color.hopeBlue
        case .good: return Color.hopeOrange
        case .fair: return Color.yellow
        case .poor: return Color.red
        }
    }
}

// MARK: - Progress Bar

struct ProgressBar: View {
    let currentStep: Int
    let totalSteps: Int
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 8)
                
                // Progress
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.hopeOrange, Color.hopePink]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(
                        width: (geometry.size.width / CGFloat(totalSteps)) * CGFloat(currentStep),
                        height: 8
                    )
                    .animation(.easeInOut(duration: 0.3), value: currentStep)
            }
        }
        .frame(height: 8)
    }
}

// MARK: - Photo Selection Grid

struct PhotoSelectionGrid: View {
    @Binding var selectedImages: [UIImage]
    @Binding var showingImagePicker: Bool
    @Binding var showingCamera: Bool
    
    let maxImages = 6
    let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(0..<maxImages, id: \.self) { index in
                if index < selectedImages.count {
                    // Show selected image
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: selectedImages[index])
                            .resizable()
                            .scaledToFill()
                            .frame(height: 100)
                            .clipped()
                            .cornerRadius(8)
                        
                        // Remove button
                        Button(action: {
                            selectedImages.remove(at: index)
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title3)
                                .foregroundColor(.white)
                                .background(Circle().fill(Color.black.opacity(0.5)))
                        }
                        .padding(4)
                    }
                } else if index == selectedImages.count && index < maxImages {
                    // Add photo button
                    Menu {
                        Button(action: { showingImagePicker = true }) {
                            Label("Choose from Library", systemImage: "photo")
                        }
                        
                        Button(action: { showingCamera = true }) {
                            Label("Take Photo", systemImage: "camera")
                        }
                    } label: {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.hopeDarkSecondary)
                            .frame(height: 100)
                            .overlay(
                                VStack(spacing: 4) {
                                    Image(systemName: "camera.fill")
                                        .font(.title2)
                                        .foregroundColor(.gray)
                                    Text("Add")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [5]))
                                    .foregroundColor(.gray)
                            )
                    }
                } else {
                    // Empty slot
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.hopeDarkSecondary.opacity(0.5))
                        .frame(height: 100)
                }
            }
        }
    }
}

