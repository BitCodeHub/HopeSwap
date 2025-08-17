import SwiftUI
import PhotosUI
import UIKit

struct PostItemFlow: View {
    @EnvironmentObject var dataManager: DataManager
    @Binding var selectedTab: Int
    @State private var currentStep = 1
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var showingSuccessAlert = false
    
    // Item data
    @State private var title = ""
    @State private var description = ""
    @State private var selectedCategory: Category = .other
    @State private var selectedCondition: Condition = .good
    @State private var location = ""
    @State private var selectedImage: UIImage?
    @State private var selectedImages: [UIImage] = []
    @FocusState private var isInputActive: Bool
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "0A1929")
                    .ignoresSafeArea()
                    .onTapGesture {
                        isInputActive = false
                    }
                
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Spacer()
                        Text("Post an Item")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .overlay(alignment: .trailing) {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.title3)
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                        }
                    }
                    .padding()
                    
                    // Content based on step
                    Group {
                        switch currentStep {
                        case 1:
                            StepOneView(
                                title: $title,
                                description: $description,
                                selectedImage: $selectedImage,
                                showingImagePicker: $showingImagePicker,
                                showingCamera: $showingCamera
                            )
                        case 2:
                            StepTwoView(
                                category: $selectedCategory,
                                condition: $selectedCondition,
                                location: $location
                            )
                        case 3:
                            StepThreeView()
                        case 4:
                            StepFourView(
                                title: title,
                                description: description,
                                category: selectedCategory,
                                condition: selectedCondition,
                                location: location,
                                image: selectedImage,
                                onPost: postItem
                            )
                        default:
                            EmptyView()
                        }
                    }
                    
                    Spacer()
                    
                    // Progress and Next button
                    VStack(spacing: 20) {
                        ProgressIndicator(currentStep: currentStep)
                        
                        Button(action: nextStep) {
                            Text(currentStep == 4 ? "Post Item" : "Next")
                                .font(.headline)
                                .foregroundColor(Color(hex: "0A1929"))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(canProceed ? Color(hex: "00D9B1") : Color.gray.opacity(0.3))
                                )
                        }
                        .disabled(!canProceed)
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 30)
                }
            }
            .navigationBarHidden(true)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        isInputActive = false
                    }
                    .foregroundColor(Color(hex: "00D9B1"))
                }
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $selectedImage, sourceType: .photoLibrary)
        }
        .sheet(isPresented: $showingCamera) {
            ImagePicker(image: $selectedImage, sourceType: .camera)
        }
        .alert("Item Posted!", isPresented: $showingSuccessAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Your item has been listed successfully. Thank you for your $1 donation to pediatric cancer research!")
        }
    }
    
    var canProceed: Bool {
        switch currentStep {
        case 1:
            return !title.isEmpty && selectedImage != nil
        case 2:
            return !location.isEmpty
        case 3:
            return true
        case 4:
            return true
        default:
            return false
        }
    }
    
    func nextStep() {
        if currentStep < 4 {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep += 1
            }
        } else {
            postItem()
        }
    }
    
    func postItem() {
        let newItem = Item(
            title: title,
            description: description,
            category: selectedCategory,
            condition: selectedCondition,
            userId: dataManager.currentUser.id,
            location: location
        )
        
        dataManager.addItem(newItem)
        showingSuccessAlert = true
    }
}

struct StepOneView: View {
    @Binding var title: String
    @Binding var description: String
    @Binding var selectedImage: UIImage?
    @Binding var showingImagePicker: Bool
    @Binding var showingCamera: Bool
    @FocusState private var isInputActive: Bool
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Photo section
                VStack(spacing: 16) {
                    if let image = selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                Button(action: { selectedImage = nil }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                        .background(Circle().fill(Color.black.opacity(0.6)))
                                }
                                .padding(8),
                                alignment: .topTrailing
                            )
                    } else {
                        VStack(spacing: 16) {
                            Button(action: { showingCamera = true }) {
                                HStack {
                                    Image(systemName: "camera.fill")
                                        .font(.title3)
                                    Text("Take photo")
                                        .font(.body)
                                        .fontWeight(.medium)
                                }
                                .foregroundColor(Color(hex: "00D9B1"))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                                .background(
                                    RoundedRectangle(cornerRadius: 30)
                                        .stroke(Color(hex: "00D9B1"), lineWidth: 2)
                                )
                            }
                            
                            Button(action: { showingImagePicker = true }) {
                                HStack {
                                    Image(systemName: "photo.fill")
                                        .font(.title3)
                                    Text("Select photo")
                                        .font(.body)
                                        .fontWeight(.medium)
                                }
                                .foregroundColor(Color(hex: "00D9B1"))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                                .background(
                                    RoundedRectangle(cornerRadius: 30)
                                        .stroke(Color(hex: "00D9B1"), lineWidth: 2)
                                )
                            }
                            
                            Text("Add your cover photo first.")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                // Title field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Title")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    TextField("", text: $title)
                        .placeholder(when: title.isEmpty) {
                            Text("For example: Brand, model, color, and size.")
                                .foregroundColor(.gray)
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .focused($isInputActive)
                }
                
                // Description field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description (optional)")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    ZStack(alignment: .topLeading) {
                        if description.isEmpty {
                            Text("Items with a detailed description sell faster!")
                                .foregroundColor(.gray)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 20)
                                .allowsHitTesting(false)
                        }
                        
                        TextEditor(text: $description)
                            .foregroundColor(.white)
                            .scrollContentBackground(.hidden)
                            .padding(12)
                            .frame(minHeight: 150)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                            .focused($isInputActive)
                    }
                }
            }
            .padding()
            .onTapGesture {
                isInputActive = false
            }
        }
    }
}

struct StepTwoView: View {
    @Binding var category: Category
    @Binding var condition: Condition
    @Binding var location: String
    @FocusState private var isInputActive: Bool
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Category
                VStack(alignment: .leading, spacing: 8) {
                    Text("Category")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(Category.allCases, id: \.self) { cat in
                                CategoryChip(
                                    title: cat.rawValue,
                                    isSelected: category == cat,
                                    action: { category = cat }
                                )
                            }
                        }
                    }
                }
                
                // Condition
                VStack(alignment: .leading, spacing: 8) {
                    Text("Condition")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    VStack(spacing: 12) {
                        ForEach(Condition.allCases, id: \.self) { cond in
                            ConditionRow(
                                condition: cond,
                                isSelected: condition == cond,
                                action: { condition = cond }
                            )
                        }
                    }
                }
                
                // Location
                VStack(alignment: .leading, spacing: 8) {
                    Text("Location")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    TextField("", text: $location)
                        .placeholder(when: location.isEmpty) {
                            Text("City, State")
                                .foregroundColor(.gray)
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .focused($isInputActive)
                }
            }
            .padding()
            .onTapGesture {
                isInputActive = false
            }
        }
    }
}

struct StepThreeView: View {
    var body: some View {
        VStack(spacing: 40) {
            Image(systemName: "heart.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(Color(hex: "00D9B1"))
            
            VStack(spacing: 16) {
                Text("Support a Great Cause")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Your $1 listing fee goes directly to pediatric cancer research")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.gray)
                    .padding(.horizontal)
                
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color(hex: "00D9B1"))
                    Text("100% of fees donated")
                        .foregroundColor(.white)
                }
                .font(.subheadline)
            }
        }
        .padding()
    }
}

struct StepFourView: View {
    let title: String
    let description: String
    let category: Category
    let condition: Condition
    let location: String
    let image: UIImage?
    let onPost: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Review Your Listing")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    DetailRow(label: "Title", value: title)
                    if !description.isEmpty {
                        DetailRow(label: "Description", value: description)
                    }
                    DetailRow(label: "Category", value: category.rawValue)
                    DetailRow(label: "Condition", value: condition.rawValue)
                    DetailRow(label: "Location", value: location)
                    
                    Divider()
                        .background(Color.gray.opacity(0.3))
                    
                    HStack {
                        Text("Listing Fee")
                            .foregroundColor(.gray)
                        Spacer()
                        Text("$1.00")
                            .font(.headline)
                            .foregroundColor(Color(hex: "00D9B1"))
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.05))
                )
            }
            .padding()
        }
    }
}

struct ProgressIndicator: View {
    let currentStep: Int
    let steps = ["Post", "Details", "Price", "Finish"]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(1...4, id: \.self) { step in
                HStack(spacing: 0) {
                    if step > 1 {
                        Rectangle()
                            .fill(step <= currentStep ? Color(hex: "00D9B1") : Color.gray.opacity(0.3))
                            .frame(height: 2)
                    }
                    
                    VStack(spacing: 4) {
                        Text("\(step)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(step <= currentStep ? Color(hex: "00D9B1") : Color.gray)
                        
                        Text(steps[step - 1])
                            .font(.caption2)
                            .foregroundColor(step <= currentStep ? Color(hex: "00D9B1") : Color.gray)
                    }
                    
                    if step < 4 {
                        Rectangle()
                            .fill(step < currentStep ? Color(hex: "00D9B1") : Color.gray.opacity(0.3))
                            .frame(height: 2)
                    }
                }
            }
        }
        .padding(.horizontal)
    }
}

struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? Color(hex: "0A1929") : .white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? Color(hex: "00D9B1") : Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(isSelected ? Color.clear : Color.gray.opacity(0.3), lineWidth: 1)
                        )
                )
        }
    }
}

struct ConditionRow: View {
    let condition: Condition
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(condition.rawValue)
                    .foregroundColor(.white)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color(hex: "00D9B1"))
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color(hex: "00D9B1").opacity(0.1) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color(hex: "00D9B1") : Color.gray.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .foregroundColor(.white)
                .lineLimit(2)
                .multilineTextAlignment(.trailing)
        }
    }
}

// Helper extensions
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {

        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    let sourceType: UIImagePickerController.SourceType
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}