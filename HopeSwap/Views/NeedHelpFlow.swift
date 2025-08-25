import SwiftUI
import PhotosUI

struct NeedHelpFlow: View {
    @EnvironmentObject var dataManager: DataManager
    @Binding var selectedTab: Int
    @Environment(\.dismiss) var dismiss
    
    @State private var currentStep = 1
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var showingSuccessAlert = false
    
    // Help request data
    @State private var title = ""
    @State private var description = ""
    @State private var selectedHelpType: HelpType = .moving
    @State private var urgency: Urgency = .flexible
    @State private var location = ""
    @State private var selectedImages: [UIImage] = []
    @State private var helpLocation: HelpLocation = .none
    @State private var workLocation = ""
    
    // Timing preferences
    @State private var needByDate = Date()
    @State private var duration = ""
    @State private var peopleNeeded = 1
    @State private var skillsRequired = ""
    
    // What can offer
    @State private var canOfferMeal = false
    @State private var canOfferGas = false
    @State private var canOfferPayment = false
    @State private var paymentAmount = ""
    @State private var canTradeService = false
    @State private var tradeServiceDetails = ""
    @State private var canWriteReview = false
    
    // Additional properties
    @State private var specificItemNeeded = ""
    @State private var timeAvailability = ""
    @State private var canPickUp = false
    @State private var canMeetPublic = false
    @State private var story = ""
    @State private var additionalInfo = ""
    
    // Listing fee and donation
    @State private var showListingFee = true
    @State private var donationAmount = 1.0
    @State private var selectedDonationOption = 0
    @State private var customDonationAmount = ""
    
    enum HelpType: String, CaseIterable {
        case moving = "Moving"
        case repair = "Repair"
        case transportation = "Transportation"
        case technology = "Technology"
        case yard = "Yard Work"
        case cleaning = "Cleaning"
        case petCare = "Pet Care"
        case childCare = "Child Care"
        case shopping = "Shopping"
        case other = "Other"
        
        var icon: String {
            switch self {
            case .moving: return "box.truck"
            case .repair: return "wrench.and.screwdriver"
            case .transportation: return "car"
            case .technology: return "desktopcomputer"
            case .yard: return "leaf"
            case .cleaning: return "sparkles"
            case .petCare: return "pawprint"
            case .childCare: return "figure.and.child.holdinghands"
            case .shopping: return "cart"
            case .other: return "questionmark.circle"
            }
        }
        
        var color: Color {
            switch self {
            case .moving: return Color.hopeBlue
            case .repair: return Color.hopeOrange
            case .transportation: return Color.hopePurple
            case .technology: return Color.hopeGreen
            case .yard: return Color.mint
            case .cleaning: return Color.hopePink
            case .petCare: return Color.brown
            case .childCare: return Color.yellow
            case .shopping: return Color.red
            case .other: return Color.gray
            }
        }
    }
    
    enum HelpLocation: String, CaseIterable {
        case none = "None"
        case atHome = "At Home"
        case atWork = "At Work"
        
        var icon: String {
            switch self {
            case .none: return ""
            case .atHome: return "house"
            case .atWork: return "building.2"
            }
        }
    }
    
    enum Urgency: String, CaseIterable {
        case urgent = "Urgent (Today)"
        case soon = "This Week"
        case flexible = "Flexible"
        case planned = "Planning Ahead"
        
        var color: Color {
            switch self {
            case .urgent: return Color.red
            case .soon: return Color.hopeOrange
            case .flexible: return Color.hopeGreen
            case .planned: return Color.hopeBlue
            }
        }
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
        .alert("Help Request Posted!", isPresented: $showingSuccessAlert) {
            Button("OK") {
                dismiss()
                selectedTab = 0
            }
        } message: {
            Text("Your request has been posted! Community members will be notified and can offer to help.")
        }
    }
    
    var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("I Need Help")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(Color.hopeOrange)
                
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
                Label("What do you need help with?", systemImage: "hand.raised")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                TextField("", text: $title)
                    .placeholder(when: title.isEmpty) {
                        Text("e.g., Help moving furniture, Fix leaky faucet...")
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
                Label("Tell us more details", systemImage: "text.alignleft")
                    .font(.headline)
                    .foregroundColor(.white)
                
                TextEditor(text: $description)
                    .placeholder(when: description.isEmpty) {
                        Text("Describe what you need help with, any specific requirements, tools needed...")
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
            
            // Location selection
            VStack(alignment: .leading, spacing: 12) {
                Label("Where do you need help?", systemImage: "location")
                    .font(.headline)
                    .foregroundColor(.white)
                
                HStack(spacing: 12) {
                    ForEach([HelpLocation.atHome, HelpLocation.atWork], id: \.self) { loc in
                        Button(action: { helpLocation = loc }) {
                            HStack {
                                Image(systemName: loc.icon)
                                    .font(.body)
                                Text(loc.rawValue)
                                    .font(.body)
                            }
                            .foregroundColor(helpLocation == loc ? Color.hopeDarkBg : .white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(helpLocation == loc ? Color.hopeOrange : Color.hopeDarkSecondary)
                            )
                        }
                    }
                }
                
                // Show appropriate content based on selection
                if helpLocation == .atHome {
                    HStack(spacing: 12) {
                        Image(systemName: "info.circle.fill")
                            .font(.title3)
                            .foregroundColor(Color.hopeOrange)
                        
                        Text("For privacy, you'll discuss specific location details directly with helpers after they accept.")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.leading)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.hopeOrange.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.hopeOrange.opacity(0.3), lineWidth: 1)
                            )
                    )
                } else if helpLocation == .atWork {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Work location")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        TextField("", text: $workLocation)
                            .placeholder(when: workLocation.isEmpty) {
                                Text("e.g., Downtown office, Retail store...")
                                    .foregroundColor(.gray)
                            }
                            .foregroundColor(.white)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.hopeDarkSecondary)
                            )
                    }
                }
            }
            
            // Photos section (optional)
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Add photos", systemImage: "camera")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("(optional)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Text("Show what needs to be done")
                    .font(.caption)
                    .foregroundColor(.gray)
                
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
            // Help type section
            VStack(alignment: .leading, spacing: 12) {
                Label("Type of help needed", systemImage: "square.grid.3x3")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(HelpType.allCases, id: \.self) { type in
                        HelpTypeButton(
                            type: type,
                            isSelected: selectedHelpType == type,
                            action: { selectedHelpType = type }
                        )
                    }
                }
            }
            
            // Urgency section
            VStack(alignment: .leading, spacing: 12) {
                Label("How urgent is this?", systemImage: "clock")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                VStack(spacing: 8) {
                    ForEach(Urgency.allCases, id: \.self) { urgencyLevel in
                        UrgencyButton(
                            urgency: urgencyLevel,
                            isSelected: urgency == urgencyLevel,
                            action: { urgency = urgencyLevel }
                        )
                    }
                }
            }
            
            // Skills required
            VStack(alignment: .leading, spacing: 12) {
                Label("Any specific skills needed?", systemImage: "hammer")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                TextField("", text: $skillsRequired)
                    .placeholder(when: skillsRequired.isEmpty) {
                        Text("e.g., Plumbing experience, Strong for lifting...")
                            .foregroundColor(.gray)
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.hopeDarkSecondary)
                    )
            }
        }
    }
    
    var stepThreeContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            // When section
            VStack(alignment: .leading, spacing: 12) {
                Label("When do you need help?", systemImage: "calendar")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                if urgency != .flexible && urgency != .planned {
                    // Date picker for urgent/soon
                    DatePicker(
                        "Need by",
                        selection: $needByDate,
                        in: Date()...,
                        displayedComponents: urgency == .urgent ? [.hourAndMinute] : [.date]
                    )
                    .datePickerStyle(.compact)
                    .accentColor(Color.hopeOrange)
                    .colorScheme(.dark)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.hopeDarkSecondary)
                    )
                } else {
                    Text("You selected flexible timing")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.hopeDarkSecondary)
                        )
                }
            }
            
            // Duration and people needed
            VStack(alignment: .leading, spacing: 12) {
                Label("Help details", systemImage: "person.2")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                // Duration
                VStack(alignment: .leading, spacing: 8) {
                    Text("Estimated duration")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    TextField("", text: $duration)
                        .placeholder(when: duration.isEmpty) {
                            Text("e.g., 2 hours, Half day...")
                                .foregroundColor(.gray)
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.hopeDarkSecondary)
                        )
                }
                
                // People needed
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("People needed: \(peopleNeeded)")
                            .font(.subheadline)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Stepper("", value: $peopleNeeded, in: 1...10)
                            .labelsHidden()
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.hopeDarkSecondary)
                    )
                }
            }
            
            // Location
            VStack(alignment: .leading, spacing: 12) {
                Label("Where do you need help?", systemImage: "location")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                TextField("", text: $location)
                    .placeholder(when: location.isEmpty) {
                        Text("Enter address or general area")
                            .foregroundColor(.gray)
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.hopeDarkSecondary)
                    )
            }
        }
    }
    
    var stepFourContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            // What can you offer
            VStack(alignment: .leading, spacing: 12) {
                Label("What can you offer in return?", systemImage: "gift")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text("Let helpers know how you can thank them")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                VStack(spacing: 12) {
                    // Meal option
                    OfferToggle(
                        title: "Provide a meal",
                        subtitle: "Home cooked or takeout",
                        icon: "fork.knife",
                        isOn: $canOfferMeal,
                        color: Color.hopeOrange
                    )
                    
                    // Gas money
                    OfferToggle(
                        title: "Gas money",
                        subtitle: "For transportation help",
                        icon: "fuelpump",
                        isOn: $canOfferGas,
                        color: Color.hopeGreen
                    )
                    
                    // Payment
                    VStack(spacing: 8) {
                        OfferToggle(
                            title: "Cash payment",
                            subtitle: "Fair compensation",
                            icon: "dollarsign.circle",
                            isOn: $canOfferPayment,
                            color: Color.hopeBlue
                        )
                        
                        if canOfferPayment {
                            TextField("", text: $paymentAmount)
                                .placeholder(when: paymentAmount.isEmpty) {
                                    Text("Enter amount (e.g., $20/hour)")
                                        .foregroundColor(.gray)
                                }
                                .foregroundColor(.white)
                                .keyboardType(.decimalPad)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.hopeDarkSecondary)
                                )
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    
                    // Trade service
                    VStack(spacing: 8) {
                        OfferToggle(
                            title: "Trade a service",
                            subtitle: "Exchange help",
                            icon: "arrow.left.arrow.right",
                            isOn: $canTradeService,
                            color: Color.hopePurple
                        )
                        
                        if canTradeService {
                            TextField("", text: $tradeServiceDetails)
                                .placeholder(when: tradeServiceDetails.isEmpty) {
                                    Text("What service can you offer?")
                                        .foregroundColor(.gray)
                                }
                                .foregroundColor(.white)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.hopeDarkSecondary)
                                )
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    
                    // Review
                    OfferToggle(
                        title: "Write a great review",
                        subtitle: "Build their reputation",
                        icon: "star",
                        isOn: $canWriteReview,
                        color: Color.yellow
                    )
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
                                NeedHelpDonationOption(
                                    amount: "$1",
                                    isSelected: selectedDonationOption == 0,
                                    action: {
                                        selectedDonationOption = 0
                                        donationAmount = 1.0
                                        customDonationAmount = ""
                                    }
                                )
                                
                                NeedHelpDonationOption(
                                    amount: "$5",
                                    isSelected: selectedDonationOption == 1,
                                    action: {
                                        selectedDonationOption = 1
                                        donationAmount = 5.0
                                        customDonationAmount = ""
                                    }
                                )
                                
                                NeedHelpDonationOption(
                                    amount: "$10",
                                    isSelected: selectedDonationOption == 2,
                                    action: {
                                        selectedDonationOption = 2
                                        donationAmount = 10.0
                                        customDonationAmount = ""
                                    }
                                )
                                
                                NeedHelpDonationOption(
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
                        Image(systemName: "hand.raised.fill")
                            .foregroundColor(Color.hopeOrange)
                        Text(title.isEmpty ? "Your help request" : title)
                            .font(.headline)
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }
                    
                    HStack {
                        Image(systemName: selectedHelpType.icon)
                            .foregroundColor(selectedHelpType.color)
                        Text(selectedHelpType.rawValue)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(urgency.color)
                        Text(urgency.rawValue)
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
                        (showListingFee ? "Post Request ($1 fee)" : 
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
                        .fill(canProceed() ? Color.hopeOrange : Color.gray.opacity(0.3))
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
            return true // All have defaults
        case 3:
            return !duration.isEmpty && !location.isEmpty
        case 4:
            return true // At least offer gratitude
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
            postHelpRequest()
        }
    }
    
    func previousStep() {
        if currentStep > 1 {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep -= 1
            }
        }
    }
    
    private func postHelpRequest() {
        // Process donation if applicable
        if donationAmount > 0 {
            // In a real app, this would process the payment through Stripe or similar
            print("Processing donation of $\(donationAmount) to Hyundai Hope on Wheels")
        }
        
        // Create formatted description
        var description = "🙏 Need Help Request\n\n"
        description += "**What I need help with:** \(self.description.isEmpty ? "Not specified" : self.description)\n\n"
        
        description += "**Help type:** \(selectedHelpType.rawValue)\n"
        if !specificItemNeeded.isEmpty {
            description += "**Specific item needed:** \(specificItemNeeded)\n"
        }
        
        description += "**Urgency:** \(urgency.rawValue)\n"
        if urgency == .urgent || urgency == .soon {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            description += "**Needed by:** \(formatter.string(from: needByDate))\n"
        }
        
        // Add location info
        if helpLocation == .atHome {
            description += "\n**Location:** At Home (Details to be discussed privately)\n"
        } else if helpLocation == .atWork {
            description += "\n**Location:** At Work - \(workLocation.isEmpty ? "Not specified" : workLocation)\n"
        } else {
            description += "\n**Location:** \(location.isEmpty ? "Not specified" : location)\n"
        }
        
        if selectedHelpType == .other {
            if !timeAvailability.isEmpty {
                description += "**Available times:** \(timeAvailability)\n"
            }
        }
        
        if canPickUp || canMeetPublic {
            description += "\n**Meeting options:**\n"
            if canPickUp { description += "- Can pick up\n" }
            if canMeetPublic { description += "- Can meet in public\n" }
        }
        
        if !story.isEmpty {
            description += "\n**My story:** \(story)\n"
        }
        
        if !additionalInfo.isEmpty {
            description += "\n**Additional info:** \(additionalInfo)"
        }
        
        // Create the item
        let newItem = Item(
            title: title.isEmpty ? "Need Help" : title,
            description: description,
            category: .miscellaneous,
            condition: .new,
            userId: UUID(),
            location: helpLocation == .atHome ? "At Home - Private" : helpLocation == .atWork ? (workLocation.isEmpty ? "At Work" : workLocation) : (location.isEmpty ? "Current Location" : location),
            price: 0,
            priceIsFirm: true,
            images: [], // Empty initially, will be populated by Firebase
            listingType: .needHelp
        )
        
        Task {
            await dataManager.addItem(newItem, images: selectedImages)
            showingSuccessAlert = true
        }
    }
}

// MARK: - Supporting Views

struct HelpTypeButton: View {
    let type: NeedHelpFlow.HelpType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isSelected ? type.color : type.color.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: type.icon)
                        .font(.title3)
                        .foregroundColor(isSelected ? Color.hopeDarkBg : type.color)
                }
                
                Text(type.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.hopeDarkSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? type.color : Color.clear, lineWidth: 2)
                    )
            )
        }
    }
}

struct UrgencyButton: View {
    let urgency: NeedHelpFlow.Urgency
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Circle()
                    .fill(urgency.color)
                    .frame(width: 12, height: 12)
                
                Text(urgency.rawValue)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(urgency.color)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? urgency.color.opacity(0.2) : Color.hopeDarkSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? urgency.color : Color.clear, lineWidth: 2)
                    )
            )
        }
    }
}

struct OfferToggle: View {
    let title: String
    let subtitle: String
    let icon: String
    @Binding var isOn: Bool
    let color: Color
    
    var body: some View {
        HStack {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: color))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.hopeDarkSecondary)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isOn ? color.opacity(0.5) : Color.clear, lineWidth: 1)
                )
        )
        .animation(.easeInOut(duration: 0.2), value: isOn)
    }
}

struct NeedHelpDonationOption: View {
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
    NeedHelpFlow(selectedTab: .constant(0))
        .environmentObject(DataManager.shared)
}