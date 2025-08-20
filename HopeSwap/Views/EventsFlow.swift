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
            Button(action: { 
                if currentStep > 1 {
                    currentStep -= 1
                } else {
                    dismiss()
                }
            }) {
                Image(systemName: currentStep > 1 ? "chevron.left" : "xmark")
                    .font(.title3)
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
            }
            
            Spacer()
            
            VStack(spacing: 4) {
                Text("Create Event")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("Step \(currentStep) of 4")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Placeholder for alignment
            Color.clear
                .frame(width: 44, height: 44)
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
            if currentStep < 4 {
                Button(action: { currentStep += 1 }) {
                    HStack {
                        Text("Continue")
                            .font(.headline)
                        Image(systemName: "arrow.right")
                            .font(.headline)
                    }
                    .foregroundColor(Color.hopeDarkBg)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(canProceed() ? Color.hopeOrange : Color.gray)
                    )
                }
                .disabled(!canProceed())
            } else {
                Button(action: postEvent) {
                    HStack {
                        Image(systemName: "calendar.badge.plus")
                            .font(.headline)
                        Text("Post Event")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(Color.hopeDarkBg)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.hopeOrange)
                    )
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 20)
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
    
    private func postEvent() {
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
            images: selectedImages.compactMap { $0.jpegData(compressionQuality: 0.8)?.base64EncodedString() }.map { "data:image/jpeg;base64,\($0)" }
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

#Preview {
    EventsFlow(selectedTab: .constant(0))
        .environmentObject(DataManager.shared)
}