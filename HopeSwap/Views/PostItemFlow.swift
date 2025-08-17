import SwiftUI
import PhotosUI
import UIKit
import AVFoundation
import UniformTypeIdentifiers
import CoreTransferable

// Helper struct for drag and drop
struct IndexedImage: Identifiable, Equatable, Codable, Transferable {
    let id = UUID()
    let index: Int
    
    static func == (lhs: IndexedImage, rhs: IndexedImage) -> Bool {
        return lhs.id == rhs.id
    }
    
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .text)
    }
}

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
    @State private var selectedImages: [UIImage] = []
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "0A1929")
                    .ignoresSafeArea()
                
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
                                selectedImages: $selectedImages,
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
                                images: selectedImages,
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
        }
        .sheet(isPresented: $showingImagePicker) {
            PhotoLibraryPicker(images: $selectedImages, maxCount: 10)
        }
        .sheet(isPresented: $showingCamera) {
            ImagePicker(images: $selectedImages, sourceType: .camera, maxCount: 10)
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
            return !title.isEmpty && !selectedImages.isEmpty
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
    @Binding var selectedImages: [UIImage]
    @Binding var showingImagePicker: Bool
    @Binding var showingCamera: Bool
    @FocusState private var isInputActive: Bool
    @State private var showingPermissionAlert = false
    @State private var showingAddPhotoOptions = false
    @State private var draggedItem: IndexedImage?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                photoSection
                titleSection
                descriptionSection
            }
            .padding()
            .onTapGesture {
                isInputActive = false
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    isInputActive = false
                }
                .foregroundColor(Color(hex: "00D9B1"))
            }
        }
        .confirmationDialog("Add Photo", isPresented: $showingAddPhotoOptions, titleVisibility: .visible) {
            Button("Take Photo") {
                checkCameraPermission()
            }
            Button("Choose from Library") {
                showingImagePicker = true
            }
            Button("Cancel", role: .cancel) { }
        }
        .alert("Camera Access Required", isPresented: $showingPermissionAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Please enable camera access in Settings to take photos.")
        }
    }
    
    // MARK: - View Components
    
    var photoSection: some View {
        VStack(spacing: 16) {
            photoGrid
            photoStatusText
            if selectedImages.isEmpty {
                Text("First photo will be used as cover photo")
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .italic()
            }
        }
    }
    
    @ViewBuilder
    var photoGrid: some View {
        let columns = [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ]
        
        if selectedImages.isEmpty {
            // Center the Add Photo button when no photos
            HStack {
                Spacer()
                addPhotoButton
                    .frame(width: 110, height: 110)
                Spacer()
            }
            .padding(.horizontal, 4)
        } else {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(0..<selectedImages.count, id: \.self) { index in
                    photoGridCell(at: index)
                }
                if selectedImages.count < 10 {
                    addPhotoButton
                }
            }
            .padding(.horizontal, 4)
        }
    }
    
    @ViewBuilder
    func photoGridCell(at index: Int) -> some View {
        let image = selectedImages[index]
        
        if index == 0 {
            // Cover photo (not draggable)
            PhotoGridItem(
                image: image,
                index: index,
                isBeingDragged: false,
                onDelete: {
                    deletePhoto(at: index)
                }
            )
        } else {
            // Draggable photos
            PhotoGridItem(
                image: image,
                index: index,
                isBeingDragged: false,
                onDelete: {
                    deletePhoto(at: index)
                }
            )
            .draggable(IndexedImage(index: index)) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .opacity(0.8)
            }
            .dropDestination(for: IndexedImage.self) { items, location in
                guard let item = items.first,
                      item.index > 0 else {
                    return false
                }
                
                movePhoto(from: item.index, to: index)
                return true
            }
        }
    }
    
    func deletePhoto(at index: Int) {
        withAnimation(.easeInOut(duration: 0.2)) {
            _ = selectedImages.remove(at: index)
        }
    }
    
    func movePhoto(from sourceIndex: Int, to destinationIndex: Int) {
        guard sourceIndex != destinationIndex,
              sourceIndex > 0, // Can't move cover photo
              destinationIndex > 0 else { // Can't move to cover position
            return
        }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            let movedImage = selectedImages.remove(at: sourceIndex)
            var insertIndex = destinationIndex
            
            if sourceIndex < destinationIndex {
                insertIndex = destinationIndex - 1
            }
            
            selectedImages.insert(movedImage, at: insertIndex)
        }
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    @ViewBuilder
    var addPhotoButton: some View {
        if selectedImages.count < 10 {
            Button(action: {
                showingAddPhotoOptions = true
            }) {
                VStack(spacing: 8) {
                    Image(systemName: "camera.fill")
                        .font(.title2)
                        .foregroundColor(Color(hex: "00D9B1"))
                    Text("Add Photo")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(Color(hex: "00D9B1"))
                }
                .frame(height: 110)
                .frame(maxWidth: .infinity)
                .background(addPhotoButtonBackground)
                .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    var addPhotoButtonBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color(hex: "0A1929"))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [5]))
                    .foregroundColor(Color(hex: "00D9B1"))
            )
    }
    
    var photoStatusText: some View {
        VStack(spacing: 8) {
            Text("\(selectedImages.count)/10 photos")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
            
            if selectedImages.count > 1 {
                Text("Hold and drag photos 2-10 to reorder")
                    .font(.caption2)
                    .foregroundColor(.gray)
                Text("First photo is the cover and cannot be moved")
                    .font(.caption2)
                    .foregroundColor(Color(hex: "00D9B1"))
                    .italic()
            }
        }
    }
    
    var titleSection: some View {
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
    }
    
    var descriptionSection: some View {
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
    
    // MARK: - Helper Functions
    
    func checkCameraPermission() {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let status = AVCaptureDevice.authorizationStatus(for: .video)
            switch status {
            case .authorized:
                showingCamera = true
            case .notDetermined:
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    DispatchQueue.main.async {
                        if granted {
                            showingCamera = true
                        } else {
                            showingPermissionAlert = true
                        }
                    }
                }
            case .denied, .restricted:
                showingPermissionAlert = true
            @unknown default:
                showingPermissionAlert = true
            }
        } else {
            // Fallback to photo library if camera not available
            showingImagePicker = true
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
    let images: [UIImage]
    let onPost: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Review Your Listing")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                if !images.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(Array(images.enumerated()), id: \.offset) { _, image in
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }
                    .frame(height: 100)
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
                    
                    VStack(spacing: 2) {
                        Text("\(step)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(step <= currentStep ? Color(hex: "00D9B1") : Color.gray)
                        
                        Text(steps[step - 1])
                            .font(.system(size: 10))
                            .fontWeight(.medium)
                            .foregroundColor(step <= currentStep ? Color(hex: "00D9B1") : Color.gray)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
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

// Photo grid item component
struct PhotoGridItem: View {
    let image: UIImage
    let index: Int
    let isBeingDragged: Bool
    let onDelete: () -> Void
    
    var body: some View {
        ZStack {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(height: 110)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
                .opacity(isBeingDragged ? 0.5 : 1.0)
                .scaleEffect(isBeingDragged ? 0.85 : 1.0)
                .rotation3DEffect(
                    .degrees(isBeingDragged ? 10 : 0),
                    axis: (x: 0, y: 1, z: 0)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(hex: "00D9B1"), lineWidth: 3)
                        .opacity(isBeingDragged ? 1.0 : 0.0)
                )
                .animation(.easeInOut(duration: 0.2), value: isBeingDragged)
            
            // Photo number indicator
            VStack {
                HStack {
                    Circle()
                        .fill(Color.black.opacity(0.6))
                        .frame(width: 24, height: 24)
                        .overlay(
                            Text("\(index + 1)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        )
                        .padding(6)
                    Spacer()
                }
                Spacer()
            }
            
            // Cover label for first photo or drag indicator
            VStack {
                Spacer()
                if index == 0 {
                    Text("Cover")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color(hex: "00D9B1"))
                        .cornerRadius(6)
                        .padding(6)
                } else {
                    HStack {
                        Spacer()
                        Image(systemName: "hand.draw.fill")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                            .padding(6)
                            .background(Circle().fill(Color.black.opacity(0.5)))
                            .padding(4)
                    }
                }
            }
            
            // Delete button
            VStack {
                HStack {
                    Spacer()
                    Button(action: onDelete) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(.white)
                            .background(Circle().fill(Color.black.opacity(0.6)))
                    }
                    .padding(6)
                }
                Spacer()
            }
        }
        .frame(height: 110)
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
    @Binding var images: [UIImage]
    let sourceType: UIImagePickerController.SourceType
    let maxCount: Int
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        
        // Configure camera for simple photo capture
        if sourceType == .camera {
            picker.cameraCaptureMode = .photo
            picker.allowsEditing = false
            picker.showsCameraControls = true
            picker.cameraFlashMode = .off
            
            // Use only basic rear camera to avoid triple camera issues
            if UIImagePickerController.isCameraDeviceAvailable(.rear) {
                picker.cameraDevice = .rear
            } else if UIImagePickerController.isCameraDeviceAvailable(.front) {
                picker.cameraDevice = .front
            }
        }
        
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
                if parent.images.count < parent.maxCount {
                    parent.images.append(image)
                }
            }
            DispatchQueue.main.async { [weak self] in
                self?.parent.presentationMode.wrappedValue.dismiss()
            }
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

struct PhotoLibraryPicker: UIViewControllerRepresentable {
    @Binding var images: [UIImage]
    let maxCount: Int
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.selectionLimit = maxCount - images.count
        config.filter = .images
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoLibraryPicker
        
        init(_ parent: PhotoLibraryPicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.presentationMode.wrappedValue.dismiss()
            
            for result in results {
                if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                    result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
                        if let image = image as? UIImage {
                            DispatchQueue.main.async {
                                if self?.parent.images.count ?? 0 < self?.parent.maxCount ?? 0 {
                                    self?.parent.images.append(image)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}