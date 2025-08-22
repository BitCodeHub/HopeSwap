import SwiftUI
import PhotosUI

struct FreebiesFlow: View {
    @EnvironmentObject var dataManager: DataManager
    @Binding var selectedTab: Int
    @Environment(\.dismiss) var dismiss
    
    @State private var currentStep = 1
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var showingSuccessAlert = false
    @State private var showingCategorySelection = false
    
    // Item data
    @State private var title = ""
    @State private var description = ""
    @State private var selectedCategory: Category = .miscellaneous
    @State private var selectedCondition: Condition = .good
    @State private var location = ""
    @State private var selectedImages: [UIImage] = []
    
    // Pickup preferences
    @State private var pickupOnly = true
    @State private var canDeliver = false
    @State private var deliveryRadius = 5.0
    @State private var availableDays: Set<Weekday> = []
    @State private var availableTimeSlots: Set<TimeSlot> = []
    
    // Additional preferences
    @State private var reason = ""
    @State private var firstComeFirstServe = true
    @State private var requiresStory = false
    @State private var storyPrompt = ""
    
    // Listing fee and donation
    @State private var showListingFee = true
    @State private var donationAmount = 1.0
    @State private var selectedDonationOption = 0
    @State private var customDonationAmount = ""
    
    enum Weekday: String, CaseIterable {
        case monday = "Mon"
        case tuesday = "Tue"
        case wednesday = "Wed"
        case thursday = "Thu"
        case friday = "Fri"
        case saturday = "Sat"
        case sunday = "Sun"
    }
    
    enum TimeSlot: String, CaseIterable {
        case morning = "Morning (8am-12pm)"
        case afternoon = "Afternoon (12pm-5pm)"
        case evening = "Evening (5pm-8pm)"
        case flexible = "Flexible"
    }
    
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
            ImagePicker(images: $selectedImages, sourceType: .photoLibrary, maxCount: 6)
        }
        .sheet(isPresented: $showingCamera) {
            ImagePicker(images: $selectedImages, sourceType: .camera, maxCount: 6)
        }
        .alert("Success!", isPresented: $showingSuccessAlert) {
            Button("OK") {
                dismiss()
                selectedTab = 0
            }
        } message: {
            Text("Your free item has been posted! You'll be notified when someone is interested.")
        }
        .sheet(isPresented: $showingCategorySelection) {
            CategorySelectionView(selectedCategory: $selectedCategory)
        }
    }
    
    var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Give Away")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(Color.hopePurple)
                
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
    
    var stepOneContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Title section
            VStack(alignment: .leading, spacing: 12) {
                Label("What are you giving away?", systemImage: "gift")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                TextField("", text: $title)
                    .placeholder(when: title.isEmpty) {
                        Text("e.g., Sweet treats, Homemade cookies, etc.")
                            .foregroundColor(.gray)
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.hopeDarkSecondary)
                    )
            }
            
            // Description section
            VStack(alignment: .leading, spacing: 12) {
                Label("Tell us more about it", systemImage: "text.alignleft")
                    .font(.headline)
                    .foregroundColor(.white)
                
                TextEditor(text: $description)
                    .placeholder(when: description.isEmpty) {
                        Text("Describe the item, why you're giving it away, any defects...")
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
            }
            
            // Photos section
            VStack(alignment: .leading, spacing: 12) {
                Label("Add photos", systemImage: "camera")
                    .font(.headline)
                    .foregroundColor(.white)
                
                PhotoSelectionGrid(
                    selectedImages: $selectedImages,
                    showingImagePicker: $showingImagePicker,
                    showingCamera: $showingCamera
                )
            }
        }
    }
    
    var stepTwoContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Category section
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
                        let displayCategories = defaultCategories.contains(selectedCategory) ? defaultCategories : defaultCategories + [selectedCategory]
                        
                        ForEach(displayCategories, id: \.self) { cat in
                            FreebiesCategoryChip(
                                title: cat.rawValue,
                                isSelected: selectedCategory == cat,
                                action: { selectedCategory = cat }
                            )
                        }
                        
                        // More button with chevron
                        Button(action: { showingCategorySelection = true }) {
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
            
            // Condition section
            VStack(alignment: .leading, spacing: 8) {
                Text("Condition")
                    .font(.headline)
                    .foregroundColor(.white)
                
                VStack(spacing: 12) {
                    ForEach(Condition.allCases, id: \.self) { cond in
                        FreebiesConditionRow(
                            condition: cond,
                            isSelected: selectedCondition == cond,
                            action: { selectedCondition = cond }
                        )
                    }
                }
            }
            
            // Why giving away
            VStack(alignment: .leading, spacing: 8) {
                Text("Why are you giving this away?")
                    .font(.headline)
                    .foregroundColor(.white)
                
                VStack(spacing: 12) {
                    ReasonButton(
                        title: "Moving",
                        icon: "box.truck",
                        isSelected: reason == "Moving",
                        action: { reason = "Moving" }
                    )
                    
                    ReasonButton(
                        title: "Decluttering",
                        icon: "sparkles",
                        isSelected: reason == "Decluttering",
                        action: { reason = "Decluttering" }
                    )
                    
                    ReasonButton(
                        title: "Upgraded/Replaced",
                        icon: "arrow.up.circle",
                        isSelected: reason == "Upgraded/Replaced",
                        action: { reason = "Upgraded/Replaced" }
                    )
                    
                    ReasonButton(
                        title: "Just want to help",
                        icon: "hand.raised",
                        isSelected: reason == "Just want to help",
                        action: { reason = "Just want to help" }
                    )
                }
            }
        }
    }
    
    var stepThreeContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Pickup/Delivery preferences
            VStack(alignment: .leading, spacing: 12) {
                Label("How can people get this?", systemImage: "shippingbox")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                VStack(spacing: 16) {
                    // Pickup option
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Pickup only")
                                .font(.headline)
                                .foregroundColor(.white)
                            Text("People come to you")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        Toggle("", isOn: $pickupOnly)
                            .toggleStyle(SwitchToggleStyle(tint: Color.hopeGreen))
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.hopeDarkSecondary)
                    )
                    
                    // Delivery option
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Can deliver")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Text("You'll bring it to them")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            Toggle("", isOn: $canDeliver)
                                .toggleStyle(SwitchToggleStyle(tint: Color.hopeBlue))
                        }
                        
                        if canDeliver {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Delivery radius: \(Int(deliveryRadius)) miles")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                
                                Slider(value: $deliveryRadius, in: 1...20, step: 1)
                                    .accentColor(Color.hopeBlue)
                            }
                            .padding(.top, 8)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.hopeDarkSecondary)
                    )
                    .animation(.easeInOut, value: canDeliver)
                }
            }
            
            // Availability
            VStack(alignment: .leading, spacing: 12) {
                Label("When are you available?", systemImage: "calendar")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                // Days
                Text("Select days")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 8) {
                    ForEach(Weekday.allCases, id: \.self) { day in
                        FreebiesDayButton(
                            day: day.rawValue,
                            isSelected: availableDays.contains(day),
                            action: {
                                if availableDays.contains(day) {
                                    availableDays.remove(day)
                                } else {
                                    availableDays.insert(day)
                                }
                            }
                        )
                    }
                }
                
                // Time slots
                Text("Preferred time")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.top)
                
                VStack(spacing: 8) {
                    ForEach(TimeSlot.allCases, id: \.self) { slot in
                        FreebiesTimeSlotButton(
                            slot: slot.rawValue,
                            isSelected: availableTimeSlots.contains(slot),
                            action: {
                                if availableTimeSlots.contains(slot) {
                                    availableTimeSlots.remove(slot)
                                } else {
                                    availableTimeSlots.insert(slot)
                                }
                            }
                        )
                    }
                }
            }
        }
    }
    
    var stepFourContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Distribution method
            VStack(alignment: .leading, spacing: 12) {
                Label("How to choose recipient?", systemImage: "person.2")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                VStack(spacing: 16) {
                    // First come first serve
                    SelectionCard(
                        title: "First come, first served",
                        subtitle: "Fastest and easiest",
                        icon: "hare",
                        isSelected: firstComeFirstServe,
                        color: Color.hopeGreen,
                        action: { 
                            firstComeFirstServe = true
                            requiresStory = false
                        }
                    )
                    
                    // Choose recipient
                    SelectionCard(
                        title: "I'll choose recipient",
                        subtitle: "Review requests and pick",
                        icon: "hand.point.up",
                        isSelected: !firstComeFirstServe && !requiresStory,
                        color: Color.hopeBlue,
                        action: { 
                            firstComeFirstServe = false
                            requiresStory = false
                        }
                    )
                    
                    // Story-based
                    SelectionCard(
                        title: "Best story wins",
                        subtitle: "Ask why they need it",
                        icon: "text.bubble",
                        isSelected: requiresStory,
                        color: Color.hopePurple,
                        action: { 
                            firstComeFirstServe = false
                            requiresStory = true
                        }
                    )
                }
                
                if requiresStory {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("What question should they answer?")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        TextField("", text: $storyPrompt)
                            .placeholder(when: storyPrompt.isEmpty) {
                                Text("e.g., How would this help you?")
                                    .foregroundColor(.gray)
                            }
                            .foregroundColor(.white)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.hopeDarkSecondary)
                            )
                    }
                    .padding(.top)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            
            // Listing fee section
            VStack(alignment: .leading, spacing: 16) {
                // Header with icon
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.hopePink.opacity(0.2))
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: "heart.fill")
                            .font(.title2)
                            .foregroundColor(Color.hopePink)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Make a Difference")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Text("Support pediatric cancer research")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                }
                
                // Toggle section
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Listing fee")
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
                                    donationAmount = 1.0
                                    selectedDonationOption = 0
                                    customDonationAmount = ""
                                } else {
                                    donationAmount = 0
                                    selectedDonationOption = -1
                                    customDonationAmount = ""
                                }
                            }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.hopeDarkSecondary)
                    )
                    
                    // Additional donation section when listing fee is off
                    if !showListingFee {
                        VStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Consider making a donation")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                Text("Your generosity helps children fighting cancer")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            
                            // Donation options
                            HStack(spacing: 12) {
                                FreebiesDonationOption(
                                    amount: "$1",
                                    isSelected: selectedDonationOption == 0,
                                    action: {
                                        selectedDonationOption = 0
                                        donationAmount = 1.0
                                        customDonationAmount = ""
                                    }
                                )
                                
                                FreebiesDonationOption(
                                    amount: "$5",
                                    isSelected: selectedDonationOption == 1,
                                    action: {
                                        selectedDonationOption = 1
                                        donationAmount = 5.0
                                        customDonationAmount = ""
                                    }
                                )
                                
                                FreebiesDonationOption(
                                    amount: "$10",
                                    isSelected: selectedDonationOption == 2,
                                    action: {
                                        selectedDonationOption = 2
                                        donationAmount = 10.0
                                        customDonationAmount = ""
                                    }
                                )
                                
                                FreebiesDonationOption(
                                    amount: "Other",
                                    isSelected: selectedDonationOption == 3,
                                    action: {
                                        selectedDonationOption = 3
                                    }
                                )
                            }
                            
                            // Custom amount input
                            if selectedDonationOption == 3 {
                                HStack {
                                    Text("$")
                                        .foregroundColor(.gray)
                                    
                                    TextField("", text: $customDonationAmount)
                                        .placeholder(when: customDonationAmount.isEmpty) {
                                            Text("Enter amount")
                                                .foregroundColor(.gray)
                                        }
                                        .foregroundColor(.white)
                                        .keyboardType(.decimalPad)
                                        .onChange(of: customDonationAmount) { _, newValue in
                                            if let amount = Double(newValue) {
                                                donationAmount = amount
                                            }
                                        }
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.hopeDarkSecondary)
                                )
                                .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                            
                            // Learn more link
                            Link(destination: URL(string: "https://www.hyundaihopeonwheels.org")!) {
                                HStack {
                                    Text("Learn about Hyundai Hope on Wheels")
                                        .font(.caption)
                                        .foregroundColor(Color.hopePink)
                                    Image(systemName: "arrow.up.right")
                                        .font(.caption2)
                                        .foregroundColor(Color.hopePink)
                                }
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.hopePink.opacity(0.1), Color.hopePurple.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
            }
            .animation(.easeInOut, value: showListingFee)
            
            // Summary card
            VStack(alignment: .leading, spacing: 16) {
                Label("Ready to post!", systemImage: "checkmark.circle.fill")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.hopeGreen)
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "gift")
                            .foregroundColor(Color.hopePink)
                        Text(title.isEmpty ? "Your item" : title)
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    
                    HStack {
                        Image(systemName: "location")
                            .foregroundColor(Color.hopeOrange)
                        Text(location.isEmpty ? "Your location" : location)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        Image(systemName: pickupOnly && !canDeliver ? "house" : "truck.box")
                            .foregroundColor(Color.hopeBlue)
                        Text(pickupOnly && !canDeliver ? "Pickup only" : canDeliver && !pickupOnly ? "Delivery only" : "Pickup or delivery")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        Image(systemName: "dollarsign.circle")
                            .foregroundColor(Color.hopeGreen)
                        Text(donationAmount > 0 ? String(format: "$%.2f", donationAmount) : "FREE")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text(donationAmount > 0 ? (showListingFee ? "listing fee" : "donation") : "")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.hopeDarkSecondary)
                )
            }
        }
    }
    
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
                        (showListingFee ? "Post Item ($1 fee)" : 
                            (donationAmount > 0 ? "Donate $\(String(format: "%.0f", donationAmount)) & Post" : "Post for Free")
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
                        .fill(canProceed() ? Color.hopePurple : Color.gray.opacity(0.3))
                )
            }
            .disabled(!canProceed())
        }
        .padding(.horizontal)
        .padding(.bottom, 30)
    }
    
    private func canProceed() -> Bool {
        switch currentStep {
        case 1:
            return !title.isEmpty && !description.isEmpty
        case 2:
            return !reason.isEmpty
        case 3:
            return (pickupOnly || canDeliver) && !availableDays.isEmpty && !availableTimeSlots.isEmpty
        default:
            return true
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
    
    private func postItem() {
        // Process donation if applicable
        if donationAmount > 0 {
            // In a real app, this would process the payment through Stripe or similar
            print("Processing donation of $\(donationAmount) to Hyundai Hope on Wheels")
        }
        
        // Create the item
        let newItem = Item(
            title: title,
            description: description,
            category: selectedCategory,
            condition: selectedCondition,
            userId: UUID(), // In real app, use actual user ID
            location: location.isEmpty ? "Current Location" : location,
            price: 0, // Free item
            priceIsFirm: true,
            images: selectedImages.compactMap { $0.jpegData(compressionQuality: 0.8)?.base64EncodedString() }.map { "data:image/jpeg;base64,\($0)" },
            listingType: .giveAway
        )
        
        dataManager.addItem(newItem)
        showingSuccessAlert = true
    }
}

// MARK: - Supporting Views

struct ReasonButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.headline)
                    .foregroundColor(isSelected ? Color.hopeDarkBg : .white)
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(isSelected ? Color.hopeDarkBg : .white)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color.hopeDarkBg)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.hopePink : Color.hopeDarkSecondary)
            )
        }
    }
}

struct FreebiesDayButton: View {
    let day: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(day)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? Color.hopeDarkBg : .white)
                .frame(width: 60, height: 40)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? Color.hopeOrange : Color.hopeDarkSecondary)
                )
        }
    }
}

struct FreebiesTimeSlotButton: View {
    let slot: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(slot)
                    .font(.subheadline)
                    .foregroundColor(isSelected ? Color.hopeDarkBg : .white)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color.hopeDarkBg)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.hopeBlue : Color.hopeDarkSecondary)
            )
        }
    }
}

struct SelectionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? color : .gray)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.hopeDarkSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? color : Color.clear, lineWidth: 2)
                    )
            )
        }
    }
}

// MARK: - Components

struct FreebiesCategoryChip: View {
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
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isSelected ? categoryColor : Color.gray.opacity(0.3))
                )
        }
    }
}

struct FreebiesConditionRow: View {
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

struct FreebiesDonationOption: View {
    let amount: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(amount)
                    .font(.headline)
                    .foregroundColor(isSelected ? Color.hopeDarkBg : .white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isSelected ? Color.hopePink : Color.hopeDarkSecondary)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(isSelected ? Color.hopePink : Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    )
            }
        }
    }
}

#Preview {
    FreebiesFlow(selectedTab: .constant(0))
        .environmentObject(DataManager.shared)
}