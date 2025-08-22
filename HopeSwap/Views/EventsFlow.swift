import SwiftUI
import MapKit
import PhotosUI

struct EventsFlow: View {
    @EnvironmentObject var dataManager: DataManager
    @Binding var selectedTab: Int
    @Environment(\.dismiss) var dismiss
    
    @State private var currentStep = 1
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var showingSuccessAlert = false
    
    // Event basics
    @State private var eventTitle = ""
    @State private var eventDescription = ""
    @State private var eventType: EventType = .community
    @State private var eventCategory: Set<EventCategory> = []
    @State private var selectedImages: [UIImage] = []
    
    // Date and time
    @State private var eventDate = Date()
    @State private var startTime = Date()
    @State private var endTime = Date().addingTimeInterval(3600)
    @State private var isRecurring = false
    @State private var recurringFrequency: RecurringFrequency = .weekly
    @State private var recurringEndDate = Date().addingTimeInterval(86400 * 30)
    
    // Location
    @State private var venue = ""
    @State private var address = ""
    @State private var isVirtual = false
    @State private var virtualLink = ""
    @State private var parkingInfo = ""
    @State private var accessibilityInfo = ""
    
    // Details and requirements
    @State private var maxAttendees = ""
    @State private var isTicketed = false
    @State private var ticketPrice = ""
    @State private var registrationLink = ""
    @State private var ageRestriction: AgeRestriction = .allAges
    @State private var whatToBring = ""
    @State private var hostName = ""
    @State private var hostContact = ""
    @State private var additionalInfo = ""
    
    // Listing fee and donation
    @State private var showListingFee = true
    @State private var donationAmount = 1.0
    @State private var selectedDonationOption = 0
    @State private var customDonationAmount = ""
    
    enum EventType: String, CaseIterable {
        case community = "Community"
        case social = "Social"
        case educational = "Educational"
        case fundraiser = "Fundraiser"
        case sports = "Sports & Fitness"
        case arts = "Arts & Culture"
        case networking = "Networking"
        case volunteer = "Volunteer"
        
        var icon: String {
            switch self {
            case .community: return "person.3"
            case .social: return "party.popper"
            case .educational: return "graduationcap"
            case .fundraiser: return "heart.circle"
            case .sports: return "sportscourt"
            case .arts: return "paintpalette"
            case .networking: return "network"
            case .volunteer: return "hands.sparkles"
            }
        }
        
        var color: Color {
            switch self {
            case .community: return Color.hopeGreen
            case .social: return Color.hopePink
            case .educational: return Color.hopeBlue
            case .fundraiser: return Color.red
            case .sports: return Color.hopeOrange
            case .arts: return Color.hopePurple
            case .networking: return Color.indigo
            case .volunteer: return Color.mint
            }
        }
    }
    
    enum EventCategory: String, CaseIterable {
        case familyFriendly = "Family Friendly"
        case adults = "Adults Only"
        case kids = "Kids Activity"
        case outdoor = "Outdoor"
        case indoor = "Indoor"
        case workshop = "Workshop"
        case class_ = "Class"
        case meetup = "Meetup"
        case festival = "Festival"
        case market = "Market"
        case performance = "Performance"
        case exhibition = "Exhibition"
        
        var icon: String {
            switch self {
            case .familyFriendly: return "figure.2.and.child.holdinghands"
            case .adults: return "person.2"
            case .kids: return "figure.and.child.holdinghands"
            case .outdoor: return "sun.max"
            case .indoor: return "house"
            case .workshop: return "hammer"
            case .class_: return "book"
            case .meetup: return "bubble.left.and.bubble.right"
            case .festival: return "sparkles"
            case .market: return "basket"
            case .performance: return "music.mic"
            case .exhibition: return "photo.on.rectangle"
            }
        }
    }
    
    enum RecurringFrequency: String, CaseIterable {
        case daily = "Daily"
        case weekly = "Weekly"
        case biweekly = "Bi-weekly"
        case monthly = "Monthly"
        
        var description: String {
            switch self {
            case .daily: return "Every day"
            case .weekly: return "Every week"
            case .biweekly: return "Every 2 weeks"
            case .monthly: return "Every month"
            }
        }
    }
    
    enum AgeRestriction: String, CaseIterable {
        case allAges = "All Ages"
        case eighteenPlus = "18+"
        case twentyOnePlus = "21+"
        case kidsOnly = "Kids Only"
        case custom = "Custom"
        
        var icon: String {
            switch self {
            case .allAges: return "person.3"
            case .eighteenPlus: return "18.circle"
            case .twentyOnePlus: return "21.circle"
            case .kidsOnly: return "figure.and.child.holdinghands"
            case .custom: return "pencil.circle"
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
        .alert("Event Posted!", isPresented: $showingSuccessAlert) {
            Button("OK") {
                dismiss()
                selectedTab = 0
            }
        } message: {
            Text("Your event has been posted successfully! People can now discover and RSVP to your event.")
        }
    }
    
    var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Create Event")
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
            // Event title and description
            VStack(alignment: .leading, spacing: 12) {
                Label("What's happening?", systemImage: "calendar.badge.plus")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                TextField("", text: $eventTitle)
                    .placeholder(when: eventTitle.isEmpty) {
                        Text("Event title (e.g., Community BBQ, Yoga in the Park)")
                            .foregroundColor(.gray)
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.hopeDarkSecondary)
                    )
                
                TextEditor(text: $eventDescription)
                    .placeholder(when: eventDescription.isEmpty) {
                        Text("Describe your event, what to expect, who should attend...")
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
            
            // Event type
            VStack(alignment: .leading, spacing: 12) {
                Label("Event type", systemImage: "tag")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(EventType.allCases, id: \.self) { type in
                        EventTypeCard(
                            type: type,
                            isSelected: eventType == type,
                            action: { eventType = type }
                        )
                    }
                }
            }
            
            // Event categories
            VStack(alignment: .leading, spacing: 12) {
                Label("Categories", systemImage: "square.grid.2x2")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text("Select all that apply")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(EventCategory.allCases, id: \.self) { category in
                        EventCategoryTag(
                            category: category,
                            isSelected: eventCategory.contains(category),
                            action: {
                                if eventCategory.contains(category) {
                                    eventCategory.remove(category)
                                } else {
                                    eventCategory.insert(category)
                                }
                            }
                        )
                    }
                }
            }
            
            // Event photos
            VStack(alignment: .leading, spacing: 12) {
                Label("Add photos", systemImage: "camera")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("Help people visualize your event")
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
            // Date and time
            VStack(alignment: .leading, spacing: 16) {
                Label("When is it?", systemImage: "clock")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                // Event date
                VStack(alignment: .leading, spacing: 8) {
                    Text("Event date")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    DatePicker("", selection: $eventDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .accentColor(Color.hopeOrange)
                        .colorScheme(.dark)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.hopeDarkSecondary)
                )
                
                // Time
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Start time")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        DatePicker("", selection: $startTime, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .accentColor(Color.hopeGreen)
                            .colorScheme(.dark)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.hopeDarkSecondary)
                    )
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("End time")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        DatePicker("", selection: $endTime, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .accentColor(Color.hopePink)
                            .colorScheme(.dark)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.hopeDarkSecondary)
                    )
                }
            }
            
            // Recurring event
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Recurring event")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("Repeats on a schedule")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $isRecurring)
                        .toggleStyle(SwitchToggleStyle(tint: Color.hopeBlue))
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.hopeDarkSecondary)
                )
                
                if isRecurring {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Frequency")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        ForEach(RecurringFrequency.allCases, id: \.self) { frequency in
                            EventFrequencyButton(
                                frequency: frequency,
                                isSelected: recurringFrequency == frequency,
                                action: { recurringFrequency = frequency }
                            )
                        }
                        
                        Text("Ends on")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding(.top)
                        
                        DatePicker("", selection: $recurringEndDate, displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .accentColor(Color.hopeOrange)
                            .colorScheme(.dark)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.hopeDarkSecondary)
                            )
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .animation(.easeInOut, value: isRecurring)
        }
    }
    
    var stepThreeContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Location
            VStack(alignment: .leading, spacing: 16) {
                Label("Where is it?", systemImage: "location")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                // Virtual event option
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Virtual event")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("Online only")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $isVirtual)
                        .toggleStyle(SwitchToggleStyle(tint: Color.hopePurple))
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.hopeDarkSecondary)
                )
                
                if isVirtual {
                    TextField("", text: $virtualLink)
                        .placeholder(when: virtualLink.isEmpty) {
                            Text("Meeting link (Zoom, Teams, etc.)")
                                .foregroundColor(.gray)
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.hopeDarkSecondary)
                        )
                        .transition(.opacity.combined(with: .move(edge: .top)))
                } else {
                    VStack(spacing: 12) {
                        TextField("", text: $venue)
                            .placeholder(when: venue.isEmpty) {
                                Text("Venue name")
                                    .foregroundColor(.gray)
                            }
                            .foregroundColor(.white)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.hopeDarkSecondary)
                            )
                        
                        TextField("", text: $address)
                            .placeholder(when: address.isEmpty) {
                                Text("Street address")
                                    .foregroundColor(.gray)
                            }
                            .foregroundColor(.white)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.hopeDarkSecondary)
                            )
                        
                        TextField("", text: $parkingInfo)
                            .placeholder(when: parkingInfo.isEmpty) {
                                Text("Parking information (optional)")
                                    .foregroundColor(.gray)
                            }
                            .foregroundColor(.white)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.hopeDarkSecondary)
                            )
                        
                        TextField("", text: $accessibilityInfo)
                            .placeholder(when: accessibilityInfo.isEmpty) {
                                Text("Accessibility information (optional)")
                                    .foregroundColor(.gray)
                            }
                            .foregroundColor(.white)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.hopeDarkSecondary)
                            )
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .animation(.easeInOut, value: isVirtual)
            
            // Map preview (for physical events)
            if !isVirtual && !address.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Location preview")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.hopeDarkSecondary)
                        .frame(height: 200)
                        .overlay(
                            VStack {
                                Image(systemName: "map")
                                    .font(.largeTitle)
                                    .foregroundColor(.gray)
                                Text("Map preview")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        )
                }
            }
        }
    }
    
    var stepFourContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Capacity and ticketing
            VStack(alignment: .leading, spacing: 16) {
                Label("Event details", systemImage: "person.3")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                // Max attendees
                HStack {
                    Text("Maximum attendees")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    TextField("", text: $maxAttendees)
                        .placeholder(when: maxAttendees.isEmpty) {
                            Text("Unlimited")
                                .foregroundColor(.gray)
                        }
                        .foregroundColor(.white)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.hopeDarkSecondary)
                        )
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.hopeDarkSecondary)
                )
                
                // Ticketed event
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Ticketed event")
                                .font(.headline)
                                .foregroundColor(.white)
                            Text("Requires ticket or registration")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: $isTicketed)
                            .toggleStyle(SwitchToggleStyle(tint: Color.hopeGreen))
                    }
                    
                    if isTicketed {
                        HStack(spacing: 12) {
                            TextField("", text: $ticketPrice)
                                .placeholder(when: ticketPrice.isEmpty) {
                                    Text("Price (or 'Free')")
                                        .foregroundColor(.gray)
                                }
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.hopeDarkSecondary)
                                )
                            
                            TextField("", text: $registrationLink)
                                .placeholder(when: registrationLink.isEmpty) {
                                    Text("Registration link")
                                        .foregroundColor(.gray)
                                }
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.hopeDarkSecondary)
                                )
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.hopeDarkSecondary)
                )
                .animation(.easeInOut, value: isTicketed)
                
                // Age restriction
                VStack(alignment: .leading, spacing: 8) {
                    Text("Age restriction")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(AgeRestriction.allCases, id: \.self) { restriction in
                            EventAgeButton(
                                restriction: restriction,
                                isSelected: ageRestriction == restriction,
                                action: { ageRestriction = restriction }
                            )
                        }
                    }
                }
            }
            
            // Additional information
            VStack(alignment: .leading, spacing: 12) {
                Label("More details", systemImage: "info.circle")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                TextField("", text: $whatToBring)
                    .placeholder(when: whatToBring.isEmpty) {
                        Text("What to bring (optional)")
                            .foregroundColor(.gray)
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.hopeDarkSecondary)
                    )
                
                TextField("", text: $hostName)
                    .placeholder(when: hostName.isEmpty) {
                        Text("Host/Organizer name")
                            .foregroundColor(.gray)
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.hopeDarkSecondary)
                    )
                
                TextField("", text: $hostContact)
                    .placeholder(when: hostContact.isEmpty) {
                        Text("Contact info (email/phone)")
                            .foregroundColor(.gray)
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.hopeDarkSecondary)
                    )
                
                TextEditor(text: $additionalInfo)
                    .placeholder(when: additionalInfo.isEmpty) {
                        Text("Any other important information...")
                            .foregroundColor(.gray)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 8)
                    }
                    .foregroundColor(.white)
                    .padding(8)
                    .frame(minHeight: 80)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.hopeDarkSecondary)
                    )
                    .scrollContentBackground(.hidden)
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
                                EventsDonationOption(
                                    amount: "$1",
                                    isSelected: selectedDonationOption == 0,
                                    action: {
                                        selectedDonationOption = 0
                                        donationAmount = 1.0
                                        customDonationAmount = ""
                                    }
                                )
                                
                                EventsDonationOption(
                                    amount: "$5",
                                    isSelected: selectedDonationOption == 1,
                                    action: {
                                        selectedDonationOption = 1
                                        donationAmount = 5.0
                                        customDonationAmount = ""
                                    }
                                )
                                
                                EventsDonationOption(
                                    amount: "$10",
                                    isSelected: selectedDonationOption == 2,
                                    action: {
                                        selectedDonationOption = 2
                                        donationAmount = 10.0
                                        customDonationAmount = ""
                                    }
                                )
                                
                                EventsDonationOption(
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
            
            // Event summary
            EventSummaryCard(
                title: eventTitle,
                type: eventType,
                date: eventDate,
                time: startTime,
                location: isVirtual ? "Virtual Event" : venue.isEmpty ? address : venue,
                isTicketed: isTicketed,
                price: ticketPrice
            )
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
                        (showListingFee ? "Create Event ($1 fee)" : 
                            (donationAmount > 0 ? "Donate $\(String(format: "%.0f", donationAmount)) & Post" : "Create Event")
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
        .background(
            Color.hopeDarkBg
                .shadow(color: .black.opacity(0.3), radius: 10, y: -5)
        )
    }
    
    private func canProceed() -> Bool {
        switch currentStep {
        case 1:
            return !eventTitle.isEmpty && !eventDescription.isEmpty && !eventCategory.isEmpty
        case 2:
            return true
        case 3:
            return isVirtual ? !virtualLink.isEmpty : (!venue.isEmpty || !address.isEmpty)
        case 4:
            return !hostName.isEmpty
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
            postEvent()
        }
    }
    
    func previousStep() {
        if currentStep > 1 {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep -= 1
            }
        }
    }
    
    private func postEvent() {
        // Process donation if applicable
        if donationAmount > 0 {
            // In a real app, this would process the payment through Stripe or similar
            print("Processing donation of $\(donationAmount) to Hyundai Hope on Wheels")
        }
        
        // Create formatted description
        var description = "📅 Event\n\n"
        description += "**Event:** \(eventDescription.isEmpty ? "Not specified" : eventDescription)\n\n"
        
        description += "**Type:** \(eventType.rawValue)\n"
        description += "**Categories:** \(eventCategory.map { $0.rawValue }.joined(separator: ", "))\n\n"
        
        // Date and time formatting
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE, MMMM d, yyyy"
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        
        description += "**Date:** \(dateFormatter.string(from: eventDate))\n"
        description += "**Time:** \(timeFormatter.string(from: startTime)) - \(timeFormatter.string(from: endTime))\n"
        
        if isRecurring {
            description += "**Recurring:** \(recurringFrequency.description) until \(dateFormatter.string(from: recurringEndDate))\n"
        }
        
        description += "\n**Location:** "
        if isVirtual {
            description += "Virtual Event\n"
            if !virtualLink.isEmpty {
                description += "**Meeting link:** \(virtualLink)\n"
            }
        } else {
            if !venue.isEmpty {
                description += "\(venue)\n"
            }
            if !address.isEmpty {
                description += "**Address:** \(address)\n"
            }
            if !parkingInfo.isEmpty {
                description += "**Parking:** \(parkingInfo)\n"
            }
            if !accessibilityInfo.isEmpty {
                description += "**Accessibility:** \(accessibilityInfo)\n"
            }
        }
        
        description += "\n**Details:**\n"
        if !maxAttendees.isEmpty {
            description += "- Max attendees: \(maxAttendees)\n"
        } else {
            description += "- Max attendees: Unlimited\n"
        }
        
        if isTicketed {
            description += "- Ticketed event: \(ticketPrice.isEmpty ? "Price TBD" : ticketPrice)\n"
            if !registrationLink.isEmpty {
                description += "- Registration: \(registrationLink)\n"
            }
        } else {
            description += "- Free event\n"
        }
        
        description += "- Age restriction: \(ageRestriction.rawValue)\n"
        
        if !whatToBring.isEmpty {
            description += "\n**What to bring:** \(whatToBring)\n"
        }
        
        description += "\n**Host:** \(hostName.isEmpty ? "Not specified" : hostName)\n"
        if !hostContact.isEmpty {
            description += "**Contact:** \(hostContact)\n"
        }
        
        if !additionalInfo.isEmpty {
            description += "\n**Additional info:** \(additionalInfo)"
        }
        
        // Create the item
        let newItem = Item(
            title: eventTitle.isEmpty ? "Community Event" : eventTitle,
            description: description,
            category: .miscellaneous,
            condition: .new,
            userId: UUID(),
            location: isVirtual ? "Virtual Event" : (venue.isEmpty ? address : venue),
            price: 0,
            priceIsFirm: true,
            images: selectedImages.compactMap { $0.jpegData(compressionQuality: 0.8)?.base64EncodedString() }.map { "data:image/jpeg;base64,\($0)" },
            listingType: .event
        )
        
        dataManager.addItem(newItem)
        showingSuccessAlert = true
    }
}

// MARK: - Supporting Views

struct EventTypeCard: View {
    let type: EventsFlow.EventType
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
                    .multilineTextAlignment(.center)
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

struct EventCategoryTag: View {
    let category: EventsFlow.EventCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.caption)
                    .foregroundColor(isSelected ? Color.hopeDarkBg : .white)
                
                Text(category.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? Color.hopeDarkBg : .white)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.hopeOrange : Color.hopeDarkSecondary)
            )
        }
    }
}

struct EventFrequencyButton: View {
    let frequency: EventsFlow.RecurringFrequency
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(frequency.rawValue)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(frequency.description)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color.hopeBlue)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.hopeDarkSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? Color.hopeBlue : Color.clear, lineWidth: 2)
                    )
            )
        }
    }
}

struct EventAgeButton: View {
    let restriction: EventsFlow.AgeRestriction
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: restriction.icon)
                    .font(.caption)
                    .foregroundColor(isSelected ? Color.hopeDarkBg : .white)
                
                Text(restriction.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? Color.hopeDarkBg : .white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.hopePurple : Color.hopeDarkSecondary)
            )
        }
    }
}

struct EventSummaryCard: View {
    let title: String
    let type: EventsFlow.EventType
    let date: Date
    let time: Date
    let location: String
    let isTicketed: Bool
    let price: String
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Event preview", systemImage: "eye")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(Color.hopeGreen)
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: type.icon)
                        .foregroundColor(type.color)
                    Text(title.isEmpty ? "Your Event" : title)
                        .font(.headline)
                        .foregroundColor(.white)
                        .lineLimit(1)
                }
                
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(Color.hopeOrange)
                    Text(dateFormatter.string(from: date))
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(Color.hopeBlue)
                    Text(timeFormatter.string(from: time))
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                HStack {
                    Image(systemName: "location")
                        .foregroundColor(Color.hopePink)
                    Text(location.isEmpty ? "Location TBD" : location)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
                
                if isTicketed {
                    HStack {
                        Image(systemName: "ticket")
                            .foregroundColor(Color.hopeGreen)
                        Text(price.isEmpty ? "Ticketed Event" : price)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
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

struct EventsDonationOption: View {
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
    EventsFlow(selectedTab: .constant(0))
        .environmentObject(DataManager.shared)
}