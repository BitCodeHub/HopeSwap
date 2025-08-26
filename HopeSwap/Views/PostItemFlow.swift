import SwiftUI
import PhotosUI
import UIKit
import AVFoundation
import UniformTypeIdentifiers
import CoreTransferable
import MapKit

// Helper struct for drag and drop
struct IndexedImage: Identifiable, Equatable, Codable, Transferable {
    let id: UUID
    let index: Int
    
    init(index: Int) {
        self.id = UUID()
        self.index = index
    }
    
    static func == (lhs: IndexedImage, rhs: IndexedImage) -> Bool {
        return lhs.id == rhs.id
    }
    
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .text)
    }
}

struct PostItemFlow: View {
    @EnvironmentObject var dataManager: DataManager
    var selectedTab: Binding<Int>?
    var isTradeItem: Bool = false
    var editingItem: Item? = nil
    
    init(selectedTab: Binding<Int>? = nil, isTradeItem: Bool = false, editingItem: Item? = nil) {
        self.selectedTab = selectedTab
        self.isTradeItem = isTradeItem
        self.editingItem = editingItem
    }
    
    @State private var currentStep = 1
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var showingSuccessAlert = false
    @State private var showingAuthAlert = false
    
    // Item data
    @State private var title = ""
    @State private var description = ""
    @State private var selectedCategory: Category = .miscellaneous
    @State private var selectedCondition: Condition = .good
    @State private var location = ""
    @State private var selectedImages: [UIImage] = []
    @State private var price = ""
    @State private var priceIsFirm = false
    
    // Trade preferences
    @State private var lookingFor = ""
    @State private var acceptableItems = ""
    @State private var tradeSuggestions = ""
    @State private var openToOffers = false
    
    // Donation preferences
    @State private var showListingFee = true
    @State private var donationAmount: Double = 1.0
    @State private var selectedDonationOption = 0 // 0: $1, 1: $5, 2: $10, 3: Custom
    @State private var customDonationAmount = ""
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.hopeDarkBg
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    headerView
                    
                    // Progress bar
                    ProgressBar(currentStep: currentStep, totalSteps: 4)
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    
                    // Content
                    ScrollView {
                        VStack(spacing: 20) {
                            switch currentStep {
                            case 1:
                                stepOneContent
                            case 2:
                                stepTwoContent
                            case 3:
                                stepThreeContent
                            case 4:
                                stepFourContent
                            default:
                                EmptyView()
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 100)
                    }
                    
                    // Bottom navigation
                    bottomNavigation
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
        .alert(editingItem != nil ? "Item Updated!" : "Item Posted!", isPresented: $showingSuccessAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text(editingItem != nil ?
                "Your item has been updated successfully." :
                (isTradeItem ? 
                    "Your trade item has been listed successfully. Happy swapping!" :
                    (showListingFee ? 
                        "Your item has been listed successfully. Thank you for your $1 donation to pediatric cancer research!" :
                    (donationAmount > 0 ? 
                        "Your item has been listed successfully for free. Thank you for your $\(String(format: "%.0f", donationAmount)) donation to pediatric cancer research!" :
                        "Your item has been listed successfully for free.")))
        }
        .alert("Sign In Required", isPresented: $showingAuthAlert) {
            Button("OK") {}
        } message: {
            Text("Please sign in with Google or Apple to post items. This helps keep our community safe.")
        }
        .onAppear {
            if let item = editingItem {
                // Populate fields for editing
                title = item.title
                description = item.description
                selectedCategory = item.category
                selectedCondition = item.condition
                location = item.location
                
                // Set price
                if let itemPrice = item.price {
                    price = String(format: "%.0f", itemPrice)
                } else {
                    price = ""
                }
                
                // Set trade preferences
                lookingFor = item.lookingFor ?? ""
                acceptableItems = item.acceptableItems ?? ""
                openToOffers = item.openToOffers
                
                // Note: For editing, we can't restore the original images from URLs
                // The user will need to re-upload images if they want to change them
            }
        }
    }
    
    // MARK: - Header View
    var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(editingItem != nil ? "Edit Item" : (isTradeItem ? "Trade Item" : "Sell Item"))
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(editingItem != nil ? Color.hopeOrange : (isTradeItem ? Color.hopeBlue : Color.hopeGreen))
                
                Text("Step \(currentStep) of 4")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.title3)
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color.hopeDarkSecondary))
            }
        }
        .padding()
    }
    
    // MARK: - Bottom Navigation
    var bottomNavigation: some View {
        HStack(spacing: 16) {
            if currentStep > 1 {
                Button(action: previousStep) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.hopeDarkSecondary)
                    )
                }
            }
            
            Button(action: nextStep) {
                HStack {
                    Text(currentStep == 4 ? 
                        (editingItem != nil ? "Update Item" :
                            (isTradeItem ? "Post Trade" : 
                                (showListingFee ? "Post Item ($1 fee)" : 
                                    (donationAmount > 0 ? "Donate $\(String(format: "%.0f", donationAmount)) & Post" : "Post for Free")
                                )
                            )
                        ) : "Next")
                    if currentStep < 4 {
                        Image(systemName: "chevron.right")
                    }
                }
                .font(.headline)
                .foregroundColor(Color.hopeDarkBg)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(canProceed ? (isTradeItem ? Color.hopeBlue : Color.hopeGreen) : Color.gray.opacity(0.3))
                )
            }
            .disabled(!canProceed)
        }
        .padding(.horizontal)
        .padding(.bottom, 30)
    }
    
    // MARK: - Step Content Views
    var stepOneContent: some View {
        StepOneView(
            title: $title,
            description: $description,
            selectedImages: $selectedImages,
            showingImagePicker: $showingImagePicker,
            showingCamera: $showingCamera
        )
    }
    
    var stepTwoContent: some View {
        StepTwoView(
            category: $selectedCategory,
            condition: $selectedCondition,
            location: $location
        )
    }
    
    var stepThreeContent: some View {
        StepThreeView(
            isTradeItem: isTradeItem,
            price: $price,
            priceIsFirm: $priceIsFirm,
            lookingFor: $lookingFor,
            acceptableItems: $acceptableItems,
            tradeSuggestions: $tradeSuggestions,
            openToOffers: $openToOffers
        )
    }
    
    var stepFourContent: some View {
        StepFourView(
            title: title,
            description: description,
            category: selectedCategory,
            condition: selectedCondition,
            location: location,
            images: selectedImages,
            price: isTradeItem ? nil : Double(price),
            priceIsFirm: priceIsFirm,
            isTradeItem: isTradeItem,
            lookingFor: lookingFor,
            acceptableItems: acceptableItems,
            tradeSuggestions: tradeSuggestions,
            openToOffers: openToOffers,
            showListingFee: $showListingFee,
            donationAmount: $donationAmount,
            selectedDonationOption: $selectedDonationOption,
            customDonationAmount: $customDonationAmount,
            onPost: postItem
        )
    }
    
    var canProceed: Bool {
        switch currentStep {
        case 1:
            return !title.isEmpty && !selectedImages.isEmpty
        case 2:
            return !location.isEmpty
        case 3:
            if isTradeItem {
                return true
            } else {
                // For sales, require a valid price
                return !price.isEmpty && Double(price) != nil && Double(price)! > 0
            }
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
    
    func previousStep() {
        if currentStep > 1 {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep -= 1
            }
        }
    }
    
    func postItem() {
        // Get the actual authenticated user ID from Firebase
        guard let currentUserId = AuthenticationManager.shared.currentUserId else {
            print("Error: No authenticated user found")
            return
        }
        
        // Prevent anonymous users from posting
        if AuthenticationManager.shared.user?.isAnonymous ?? true {
            print("Error: Anonymous users cannot post items")
            showingAuthAlert = true
            return
        }
        
        if let existingItem = editingItem {
            // Update existing item
            var updatedItem = existingItem
            updatedItem.title = title
            updatedItem.description = description
            updatedItem.category = selectedCategory
            updatedItem.condition = selectedCondition
            updatedItem.location = location
            updatedItem.price = isTradeItem ? nil : Double(price)
            updatedItem.priceIsFirm = priceIsFirm
            updatedItem.isTradeItem = isTradeItem
            updatedItem.lookingFor = isTradeItem ? lookingFor : nil
            updatedItem.acceptableItems = isTradeItem ? acceptableItems : nil
            updatedItem.tradeSuggestions = isTradeItem ? tradeSuggestions : nil
            updatedItem.openToOffers = isTradeItem ? openToOffers : false
            updatedItem.listingType = isTradeItem ? .trade : .sell
            
            Task {
                await dataManager.updateItem(updatedItem, newImages: selectedImages)
                showingSuccessAlert = true
            }
        } else {
            // Create new item
            let userIdUUID = UUID(uuidString: currentUserId) ?? UUID()
            
            let newItem = Item(
                title: title,
                description: description,
                category: selectedCategory,
                condition: selectedCondition,
                userId: userIdUUID,
                location: location,
                price: isTradeItem ? nil : Double(price),
                priceIsFirm: priceIsFirm,
                isTradeItem: isTradeItem,
                lookingFor: isTradeItem ? lookingFor : nil,
                acceptableItems: isTradeItem ? acceptableItems : nil,
                tradeSuggestions: isTradeItem ? tradeSuggestions : nil,
                openToOffers: isTradeItem ? openToOffers : false,
                images: [], // Empty initially, will be populated by Firebase
                listingType: isTradeItem ? .trade : .sell
            )
            
            Task {
                await dataManager.addItem(newItem, images: selectedImages)
                showingSuccessAlert = true
            }
        }
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
        VStack(spacing: 24) {
            photoSection
            titleSection
            descriptionSection
        }
        .onTapGesture {
            isInputActive = false
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    isInputActive = false
                }
                .foregroundColor(Color.hopeOrange)
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
                        .foregroundColor(Color.hopeOrange)
                    Text("Add Photo")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(Color.hopeOrange)
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
            .fill(Color.hopeDarkBg)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [5]))
                    .foregroundColor(Color.hopeOrange)
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
                    .foregroundColor(Color.hopeOrange)
                    .italic()
            }
        }
    }
    
    var titleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("What are you selling?", systemImage: "tag")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            TextField("", text: $title)
                .placeholder(when: title.isEmpty) {
                    Text("e.g., iPhone 12 Pro, Vintage Leather Jacket")
                        .foregroundColor(.gray)
                }
                .foregroundColor(.white)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.hopeDarkSecondary)
                )
                .focused($isInputActive)
        }
    }
    
    var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Tell us more about it", systemImage: "text.alignleft")
                .font(.headline)
                .foregroundColor(.white)
            
            TextEditor(text: $description)
                .placeholder(when: description.isEmpty) {
                    Text("Describe the item condition, features, reason for selling...")
                        .foregroundColor(.gray)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 8)
                }
                .foregroundColor(.white)
                .padding(8)
                .frame(minHeight: 120)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.hopeDarkSecondary)
                )
                .scrollContentBackground(.hidden)
                .focused($isInputActive)
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
    @StateObject private var locationSearchCompleter = LocationSearchCompleter()
    @State private var searchResults: [MKLocalSearchCompletion] = []
    @State private var isSearching = false
    @State private var showCategorySelection = false
    
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
                            // Default categories to show
                            let defaultCategories: [Category] = [
                                .electronics,
                                .furniture,
                                .homeKitchen,
                                .sportingGoods,
                                .toysGames
                            ]
                            
                            // Include selected category if it's not in the default list
                            let displayCategories = defaultCategories.contains(category) ? defaultCategories : defaultCategories + [category]
                            
                            ForEach(displayCategories, id: \.self) { cat in
                                CategoryChip(
                                    title: cat.rawValue,
                                    isSelected: category == cat,
                                    action: { category = cat }
                                )
                            }
                            
                            // More button with chevron
                            Button(action: { showCategorySelection = true }) {
                                HStack(spacing: 4) {
                                    Text("More")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 12, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.gray.opacity(0.3))
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
                    
                    VStack(spacing: 0) {
                        HStack {
                            TextField("", text: $location)
                                .placeholder(when: location.isEmpty) {
                                    Text("Search city, address, or business")
                                        .foregroundColor(.gray)
                                }
                                .foregroundColor(.white)
                                .focused($isInputActive)
                                .onChange(of: location) { _, newValue in
                                    locationSearchCompleter.searchQuery = newValue
                                    isSearching = !newValue.isEmpty
                                }
                            
                            // Clear button
                            if !location.isEmpty {
                                Button(action: {
                                    location = ""
                                    isSearching = false
                                    searchResults = []
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.body)
                                        .foregroundColor(.gray)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: isSearching && !searchResults.isEmpty ? [.topLeft, .topRight] : [.allCorners], radius: 16)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        
                        // Search results dropdown
                        if isSearching && !searchResults.isEmpty {
                            VStack(spacing: 0) {
                                ForEach(searchResults.prefix(5), id: \.self) { result in
                                    Button(action: {
                                        selectLocation(result)
                                    }) {
                                        HStack {
                                            Image(systemName: getIconForResult(result))
                                                .font(.body)
                                                .foregroundColor(.gray)
                                                .frame(width: 20)
                                            
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(result.title)
                                                    .font(.body)
                                                    .foregroundColor(.white)
                                                    .lineLimit(1)
                                                if !result.subtitle.isEmpty {
                                                    Text(result.subtitle)
                                                        .font(.caption)
                                                        .foregroundColor(.gray)
                                                        .lineLimit(1)
                                                }
                                            }
                                            Spacer()
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    
                                    if result != searchResults.prefix(5).last {
                                        Divider()
                                            .background(Color.gray.opacity(0.2))
                                            .padding(.horizontal, 16)
                                    }
                                }
                            }
                            .background(
                                RoundedRectangle(cornerRadius: [.bottomLeft, .bottomRight], radius: 16)
                                    .fill(Color.hopeDarkSecondary)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: [.bottomLeft, .bottomRight], radius: 16)
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                            )
                        }
                    }
                }
            }
            .padding()
            .onTapGesture {
                if !searchResults.isEmpty {
                    isSearching = false
                    searchResults = []
                }
                isInputActive = false
            }
        }
        .onAppear {
            // Set up the search completer
            locationSearchCompleter.delegate = LocationSearchCompleterDelegate { results in
                searchResults = results
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    isInputActive = false
                }
                .foregroundColor(Color.hopeOrange)
            }
        }
        .sheet(isPresented: $showCategorySelection) {
            CategorySelectionView(selectedCategory: $category)
        }
    }
    
    // Helper functions
    func selectLocation(_ result: MKLocalSearchCompletion) {
        // Format the location based on the result
        var formattedLocation = result.title
        
        // If subtitle contains additional info, append it
        if !result.subtitle.isEmpty && !result.title.contains(result.subtitle) {
            // Remove "United States" from subtitle
            let cleanedSubtitle = result.subtitle
                .replacingOccurrences(of: ", United States", with: "")
                .replacingOccurrences(of: "United States", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Only append if there's meaningful content left
            if !cleanedSubtitle.isEmpty && cleanedSubtitle != "," {
                formattedLocation = "\(result.title), \(cleanedSubtitle)"
            }
        }
        
        location = formattedLocation
        isSearching = false
        searchResults = []
        isInputActive = false
    }
    
    func getIconForResult(_ result: MKLocalSearchCompletion) -> String {
        let title = result.title.lowercased()
        let subtitle = result.subtitle.lowercased()
        
        // Check for business types
        if title.contains("starbucks") || title.contains("coffee") {
            return "cup.and.saucer.fill"
        } else if title.contains("costco") || title.contains("walmart") || title.contains("target") || title.contains("store") {
            return "cart.fill"
        } else if title.contains("restaurant") || title.contains("pizza") || title.contains("burger") {
            return "fork.knife"
        } else if title.contains("park") {
            return "tree.fill"
        } else if title.contains("hospital") || title.contains("medical") {
            return "cross.fill"
        } else if title.contains("school") || title.contains("university") || title.contains("college") {
            return "graduationcap.fill"
        } else if subtitle.contains("street") || subtitle.contains("avenue") || subtitle.contains("road") || subtitle.contains("drive") {
            return "house.fill"
        } else {
            return "location.fill"
        }
    }
}

struct StepThreeView: View {
    let isTradeItem: Bool
    @Binding var price: String
    @Binding var priceIsFirm: Bool
    @Binding var lookingFor: String
    @Binding var acceptableItems: String
    @Binding var tradeSuggestions: String
    @Binding var openToOffers: Bool
    @FocusState private var isInputActive: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            if isTradeItem {
                // Trade content
                VStack(spacing: 24) {
                    // Title
                    VStack(spacing: 8) {
                        Text("Trade Preferences")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Tell us what you're looking to trade for")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                            
                    // What I'm looking for section
                    VStack(alignment: .leading, spacing: 12) {
                        Label("What I'm looking for", systemImage: "magnifyingglass")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        TextEditor(text: $lookingFor)
                            .placeholder(when: lookingFor.isEmpty) {
                                Text("Describe items you'd like to trade for (e.g., electronics, books, toys)")
                                    .foregroundColor(.gray)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 8)
                            }
                            .foregroundColor(.white)
                            .padding(8)
                            .frame(minHeight: 100)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.hopeDarkSecondary)
                            )
                            .scrollContentBackground(.hidden)
                            .focused($isInputActive)
                    }
                            
                    // What's acceptable section
                    VStack(alignment: .leading, spacing: 12) {
                        Label("What's acceptable", systemImage: "checkmark.circle")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        TextEditor(text: $acceptableItems)
                            .placeholder(when: acceptableItems.isEmpty) {
                                Text("List specific items or categories you're willing to accept")
                                    .foregroundColor(.gray)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 8)
                            }
                            .foregroundColor(.white)
                            .padding(8)
                            .frame(minHeight: 100)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.hopeDarkSecondary)
                            )
                            .scrollContentBackground(.hidden)
                            .focused($isInputActive)
                    }
                            
                    // Trade suggestions section
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Other trade suggestions", systemImage: "lightbulb")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        TextEditor(text: $tradeSuggestions)
                            .placeholder(when: tradeSuggestions.isEmpty) {
                                Text("Any creative trade ideas or flexible options?")
                                    .foregroundColor(.gray)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 8)
                            }
                            .foregroundColor(.white)
                            .padding(8)
                            .frame(minHeight: 100)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.hopeDarkSecondary)
                            )
                            .scrollContentBackground(.hidden)
                            .focused($isInputActive)
                    }
                            
                    // Trade flexibility toggle
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Open to all offers")
                                .font(.body)
                                .foregroundColor(.white)
                            Text("Let people know you're flexible")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: $openToOffers)
                            .toggleStyle(SwitchToggleStyle(tint: Color.hopeBlue))
                            .labelsHidden()
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.hopeDarkSecondary)
                    )
                            
                    // Helper text
                    VStack(spacing: 8) {
                        Image(systemName: "info.circle")
                            .font(.title3)
                            .foregroundColor(Color.hopeBlue)
                        
                        Text("Be specific about what you want to increase your chances of a successful trade!")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 20)
                }
                } else {
                    // Sale content
                    VStack(spacing: 24) {
                        // Title
                        VStack(spacing: 8) {
                            Text("Pricing Details")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Set a competitive price for your item")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        
                        // Price input section
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Item price", systemImage: "dollarsign.circle")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            HStack {
                                Text("$")
                                    .font(.title2)
                                    .foregroundColor(Color.hopeGreen)
                                
                                TextField("0", text: $price)
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .keyboardType(.decimalPad)
                                    .focused($isInputActive)
                                    .onChange(of: price) { _, newValue in
                                        // Allow only valid price format
                                        let filtered = newValue.filter { "0123456789.".contains($0) }
                                        if filtered.filter({ $0 == "." }).count > 1 {
                                            price = String(filtered.dropLast())
                                        } else {
                                            price = filtered
                                        }
                                    }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.hopeDarkSecondary)
                            )
                        }
                        
                        // Price is firm toggle
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Price is firm")
                                    .font(.body)
                                    .foregroundColor(.white)
                                Text("I'm not accepting lower offers")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                            
                            Toggle("", isOn: $priceIsFirm)
                                .toggleStyle(SwitchToggleStyle(tint: Color.hopeGreen))
                                .labelsHidden()
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.hopeDarkSecondary)
                        )
                        
                        if priceIsFirm {
                            Text("Buyers will see that your price is non-negotiable")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        
                    }
            }
        }
        .onTapGesture {
            isInputActive = false
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    isInputActive = false
                }
                .foregroundColor(Color.hopeOrange)
            }
        }
    }
}

struct StepFourView: View {
    let title: String
    let description: String
    let category: Category
    let condition: Condition
    let location: String
    let images: [UIImage]
    let price: Double?
    let priceIsFirm: Bool
    let isTradeItem: Bool
    let lookingFor: String
    let acceptableItems: String
    let tradeSuggestions: String
    let openToOffers: Bool
    @Binding var showListingFee: Bool
    @Binding var donationAmount: Double
    @Binding var selectedDonationOption: Int
    @Binding var customDonationAmount: String
    let onPost: () -> Void
    
    @FocusState private var isCustomAmountFocused: Bool
    
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
                
                // Listing details
                VStack(alignment: .leading, spacing: 16) {
                    PostDetailRow(label: "Title", value: title)
                    if !description.isEmpty {
                        PostDetailRow(label: "Description", value: description)
                    }
                    PostDetailRow(label: "Category", value: category.rawValue)
                    PostDetailRow(label: "Condition", value: condition.rawValue)
                    PostDetailRow(label: "Location", value: location)
                    
                    if let price = price {
                        HStack {
                            PostDetailRow(label: "Price", value: "$\(String(format: "%.2f", price))")
                            if priceIsFirm {
                                Text("FIRM")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color.hopeBlue)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color.hopeBlue.opacity(0.2))
                                    )
                            }
                        }
                    }
                    
                    // Trade preferences
                    if isTradeItem {
                        if !lookingFor.isEmpty {
                            PostDetailRow(label: "Looking for", value: lookingFor)
                        }
                        if !acceptableItems.isEmpty {
                            PostDetailRow(label: "Will accept", value: acceptableItems)
                        }
                        if !tradeSuggestions.isEmpty {
                            PostDetailRow(label: "Trade ideas", value: tradeSuggestions)
                        }
                        if openToOffers {
                            HStack {
                                Text("Open to offers")
                                    .foregroundColor(.gray)
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Color.hopeGreen)
                            }
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.05))
                )
                
                // Donation Section - Only show for non-trade items
                if !isTradeItem {
                    VStack(spacing: 20) {
                        // Header with heart icon
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color(red: 0.91, green: 0.29, blue: 0.39))
                                    .frame(width: 80, height: 80)
                                
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(Color.hopeDarkBg)
                            }
                            
                            Text("Make a Difference")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("100% of listing fees support pediatric cancer research")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        
                        // Toggle for listing fee
                        VStack(spacing: 16) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Listing Fee")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    Text(showListingFee ? "$1 donation to charity" : "List for free")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                
                                Spacer()
                                
                                Toggle("", isOn: $showListingFee)
                                    .toggleStyle(SwitchToggleStyle(tint: Color.hopeGreen))
                                    .scaleEffect(0.9)
                                    .onChange(of: showListingFee) { _, newValue in
                                        if newValue {
                                            // Reset donation when turning listing fee back on
                                            donationAmount = 1.0
                                            selectedDonationOption = 0
                                            customDonationAmount = ""
                                        } else {
                                            // Reset donation to 0 when making it free
                                            donationAmount = 0
                                            selectedDonationOption = -1
                                            customDonationAmount = ""
                                        }
                                    }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.05))
                            )
                            
                            // Donation options when toggle is OFF (free listing)
                            if !showListingFee {
                                VStack(spacing: 12) {
                                    // Encourage donation when listing for free
                                    VStack(spacing: 8) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "gift.fill")
                                                .font(.title2)
                                                .foregroundColor(Color.hopePink)
                                            
                                            Text("Consider making a donation")
                                                .font(.headline)
                                                .foregroundColor(.white)
                                        }
                                        
                                        Text("Your generosity helps children fighting cancer")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                            .multilineTextAlignment(.center)
                                    }
                                    .padding(.bottom, 8)
                                    
                                    // Donation amount buttons
                                    HStack(spacing: 12) {
                                        DonationButton(
                                            amount: "$1",
                                            isSelected: selectedDonationOption == 0,
                                            action: {
                                                selectedDonationOption = 0
                                                donationAmount = 1.0
                                                isCustomAmountFocused = false
                                            }
                                        )
                                        
                                        DonationButton(
                                            amount: "$5",
                                            isSelected: selectedDonationOption == 1,
                                            action: {
                                                selectedDonationOption = 1
                                                donationAmount = 5.0
                                                isCustomAmountFocused = false
                                            }
                                        )
                                        
                                        DonationButton(
                                            amount: "$10",
                                            isSelected: selectedDonationOption == 2,
                                            action: {
                                                selectedDonationOption = 2
                                                donationAmount = 10.0
                                                isCustomAmountFocused = false
                                            }
                                        )
                                        
                                        // Custom amount
                                        Button(action: {
                                            selectedDonationOption = 3
                                            isCustomAmountFocused = true
                                        }) {
                                            if selectedDonationOption == 3 {
                                                HStack(spacing: 4) {
                                                    Text("$")
                                                        .foregroundColor(.white)
                                                    TextField("0", text: $customDonationAmount)
                                                        .keyboardType(.decimalPad)
                                                        .foregroundColor(.white)
                                                        .multilineTextAlignment(.center)
                                                        .frame(width: 40)
                                                        .focused($isCustomAmountFocused)
                                                        .onChange(of: customDonationAmount) { _, newValue in
                                                            if let amount = Double(newValue), amount > 0 {
                                                                donationAmount = amount
                                                            }
                                                        }
                                                }
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 12)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .fill(Color.hopeGreen)
                                                )
                                            } else {
                                                Text("Other")
                                                    .font(.subheadline)
                                                    .fontWeight(.medium)
                                                    .foregroundColor(.white)
                                                    .padding(.horizontal, 16)
                                                    .padding(.vertical, 12)
                                                    .background(
                                                        RoundedRectangle(cornerRadius: 12)
                                                            .fill(Color.gray.opacity(0.3))
                                                    )
                                            }
                                        }
                                    }
                                    
                                    // 100% donation message
                                    HStack(spacing: 8) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.body)
                                            .foregroundColor(Color.hopeGreen)
                                        
                                        Text("100% of fees donated")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(Color.hopeGreen)
                                    }
                                    .padding(.top, 8)
                                    
                                    // Hyundai Hope on Wheels with link
                                    VStack(spacing: 8) {
                                        Text("Hyundai Hope on Wheels")
                                            .font(.footnote)
                                            .foregroundColor(.gray)
                                            .italic()
                                        
                                        Link(destination: URL(string: "https://hyundaihopeonwheels.org/our-story/")!) {
                                            HStack(spacing: 4) {
                                                Text("Learn more about our mission")
                                                    .font(.caption)
                                                    .foregroundColor(Color.hopeBlue)
                                                    .underline()
                                                
                                                Image(systemName: "arrow.up.right.square")
                                                    .font(.caption)
                                                    .foregroundColor(Color.hopeBlue)
                                            }
                                        }
                                    }
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.hopePink.opacity(0.1), 
                                                Color.hopePurple.opacity(0.1)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(Color.hopePink.opacity(0.3), lineWidth: 1)
                                        )
                                )
                                .transition(.opacity.combined(with: .move(edge: .top)).combined(with: .scale))
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.05))
                        )
                    }
                    .animation(.easeInOut, value: showListingFee)
                }
                
                // Final summary
                VStack(spacing: 12) {
                    Divider()
                        .background(Color.gray.opacity(0.3))
                    
                    HStack {
                        Text("Total")
                            .font(.headline)
                            .foregroundColor(.white)
                        Spacer()
                        if isTradeItem {
                            Text("FREE")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(Color.hopeGreen)
                        } else {
                            Text(showListingFee ? "$1.00" : (donationAmount > 0 ? "$\(String(format: "%.2f", donationAmount)) donation" : "FREE"))
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(showListingFee ? Color.hopeBlue : Color.hopeGreen)
                        }
                    }
                    
                    if !isTradeItem {
                        if showListingFee {
                            Text("Goes to pediatric cancer research")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        } else if donationAmount > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "heart.fill")
                                    .font(.caption)
                                    .foregroundColor(Color.hopePink)
                                Text("Thank you for your generous donation!")
                                    .font(.caption)
                                    .foregroundColor(Color.hopePink)
                            }
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        }
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
        .onTapGesture {
            isCustomAmountFocused = false
        }
    }
}

struct DonationButton: View {
    let amount: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(amount)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .white)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? Color.hopeGreen : Color.gray.opacity(0.3))
                )
        }
    }
}

struct ProgressIndicator: View {
    let currentStep: Int
    let isTradeItem: Bool
    
    var steps: [String] {
        isTradeItem ? ["Post", "Details", "Trade", "Finish"] : ["Post", "Details", "Price", "Finish"]
    }
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(1...4, id: \.self) { step in
                HStack(spacing: 0) {
                    if step > 1 {
                        Rectangle()
                            .fill(step <= currentStep ? (step == 1 ? Color.hopeOrange : step == 2 ? Color.hopeGreen : step == 3 ? Color.hopeBlue : Color.hopePink) : Color.gray.opacity(0.3))
                            .frame(height: 2)
                    }
                    
                    VStack(spacing: 2) {
                        Text("\(step)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(step <= currentStep ? (step == 1 ? Color.hopeOrange : step == 2 ? Color.hopeGreen : step == 3 ? Color.hopeBlue : Color.hopePink) : Color.gray)
                        
                        Text(steps[step - 1])
                            .font(.system(size: 10))
                            .fontWeight(.medium)
                            .foregroundColor(step <= currentStep ? (step == 1 ? Color.hopeOrange : step == 2 ? Color.hopeGreen : step == 3 ? Color.hopeBlue : Color.hopePink) : Color.gray)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    
                    if step < 4 {
                        Rectangle()
                            .fill(step < currentStep ? (step == 1 ? Color.hopeOrange : step == 2 ? Color.hopeGreen : step == 3 ? Color.hopeBlue : Color.hopePink) : Color.gray.opacity(0.3))
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
    
    var categoryColor: Color {
        // Match colors with the categories we're displaying
        switch title {
        case "Electronics": return Color.hopeBlue
        case "Furniture": return Color.brown
        case "Home & Kitchen": return Color.hopeGreen
        case "Sporting Goods": return Color.red
        case "Toys & Games": return Color.hopeOrange
        case "Books, Movies & Music": return Color.hopePurple
        case "Menswear", "Womenswear", "Kidswear & Baby": return Color.hopePink
        case "Vehicles", "Auto Parts": return Color.orange
        case "Health & Beauty": return Color.pink
        case "Pet Supplies": return Color.yellow
        case "Arts & Crafts": return Color.purple
        case "Jewelry & Watches": return Color.cyan
        case "Musical Instruments": return Color.indigo
        case "Patio & Garden": return Color.hopeGreen
        case "Home Improvement": return Color.hopeGreen
        default: return Color.gray
        }
    }
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? Color.hopeDarkBg : .white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? categoryColor : Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(isSelected ? Color.clear : categoryColor.opacity(0.5), lineWidth: 1)
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
                        .foregroundColor(Color.hopeGreen)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.hopeGreen.opacity(0.1) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.hopeGreen : Color.gray.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
}

struct PostDetailRow: View {
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
                        .stroke(Color.hopeOrange, lineWidth: 3)
                        .opacity(isBeingDragged ? 1.0 : 0.0)
                )
                .animation(.easeInOut(duration: 0.2), value: isBeingDragged)
            
            // Photo number indicator
            VStack {
                HStack {
                    Circle()
                        .fill(index == 0 ? Color.hopeOrange.opacity(0.9) : 
                              index == 1 ? Color.hopeGreen.opacity(0.9) : 
                              index == 2 ? Color.hopeBlue.opacity(0.9) : 
                              index == 3 ? Color.hopePink.opacity(0.9) : 
                              Color.hopeOrange.opacity(0.9))
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
                        .background(Color.hopeOrange)
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



// Helper extensions removed - using ColorTheme.swift instead


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

// Add this extension for corner radius
extension RoundedRectangle {
    init(cornerRadius corners: UIRectCorner, radius: CGFloat) {
        if corners == [.allCorners] {
            self.init(cornerRadius: radius)
        } else if corners == [.topLeft, .topRight] {
            self.init(cornerRadius: radius)
        } else if corners == [.bottomLeft, .bottomRight] {
            self.init(cornerRadius: radius)
        } else {
            self.init(cornerRadius: radius)
        }
    }
}


