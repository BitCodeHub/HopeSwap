import SwiftUI
import MapKit

struct CarpoolFlow: View {
    @EnvironmentObject var dataManager: DataManager
    @Binding var selectedTab: Int
    @Environment(\.dismiss) var dismiss
    
    @State private var currentStep = 1
    @State private var showingSuccessAlert = false
    
    // Trip details
    @State private var tripType: TripType = .regular
    @State private var origin = ""
    @State private var destination = ""
    @State private var tripDate = Date()
    @State private var departureTime = Date()
    @State private var isFlexibleTime = false
    @State private var flexibleMinutes = 15.0
    
    // Preferences
    @State private var frequency: Frequency = .oneTime
    @State private var selectedDays: Set<Weekday> = []
    @State private var smokingAllowed = false
    @State private var petsAllowed = false
    @State private var musicPreference: MusicPreference = .driverChoice
    @State private var conversationLevel: ConversationLevel = .moderate
    @State private var detourWilling = false
    @State private var maxDetourMinutes = 10.0
    
    // Vehicle/Passenger details
    @State private var isDriver = true
    @State private var vehicleMake = ""
    @State private var vehicleModel = ""
    @State private var vehicleColor = ""
    @State private var availableSeats = 1
    @State private var luggageSpace: LuggageSpace = .small
    @State private var hasChildSeat = false
    @State private var wheelchairAccessible = false
    
    // Cost sharing
    @State private var costSharingType: CostSharing = .splitGas
    @State private var estimatedCost = ""
    @State private var paymentMethod: PaymentMethod = .cash
    @State private var notes = ""
    
    // Additional missing properties
    @State private var startLocation = ""
    @State private var headline = ""
    @State private var preferredDays: [Weekday] = []
    @State private var rideType: RideType = .driver
    @State private var seatsAvailable = 1
    @State private var conversationPreference: ConversationLevel = .moderate
    @State private var lookingForDriver = false
    @State private var lookingForRiders = false
    @State private var commuteType: CommuteType = .occasional
    @State private var vehicleType: VehicleType = .sedan
    @State private var costPerRide: Double = 0.0
    @State private var costSharingMethod: CostMethod = .perRide
    @State private var carpoolRules = ""
    @State private var additionalNotes = ""
    @State private var maxDetour: Double = 5.0
    
    // Listing fee and donation
    @State private var showListingFee = true
    @State private var donationAmount = 1.0
    @State private var selectedDonationOption = 0
    @State private var customDonationAmount = ""
    
    enum TripType: String, CaseIterable {
        case regular = "Regular Commute"
        case oneWay = "One Way Trip"
        case roundTrip = "Round Trip"
        case airport = "Airport"
        case shopping = "Shopping/Errands"
        case event = "Event/Concert"
        
        var icon: String {
            switch self {
            case .regular: return "arrow.triangle.2.circlepath"
            case .oneWay: return "arrow.right"
            case .roundTrip: return "arrow.left.arrow.right"
            case .airport: return "airplane"
            case .shopping: return "cart"
            case .event: return "ticket"
            }
        }
        
        var color: Color {
            switch self {
            case .regular: return Color.hopeBlue
            case .oneWay: return Color.hopeGreen
            case .roundTrip: return Color.hopeOrange
            case .airport: return Color.hopePurple
            case .shopping: return Color.hopePink
            case .event: return Color.yellow
            }
        }
    }
    
    enum Frequency: String, CaseIterable {
        case oneTime = "One Time"
        case daily = "Daily"
        case weekly = "Weekly"
        case custom = "Custom Days"
    }
    
    enum MusicPreference: String, CaseIterable {
        case driverChoice = "Driver's Choice"
        case noMusic = "No Music"
        case passenger = "Open to Suggestions"
        case anything = "Anything Goes"
    }
    
    enum ConversationLevel: String, CaseIterable {
        case quiet = "Quiet Ride"
        case moderate = "Some Chat"
        case talkative = "Love to Talk"
        case flexible = "Go with the Flow"
    }
    
    enum LuggageSpace: String, CaseIterable {
        case none = "No Space"
        case small = "Small Bag"
        case medium = "Suitcase"
        case large = "Multiple Bags"
    }
    
    enum CostSharing: String, CaseIterable {
        case free = "Free Ride"
        case splitGas = "Split Gas"
        case fixedAmount = "Fixed Amount"
        case donation = "Donation Based"
    }
    
    enum PaymentMethod: String, CaseIterable {
        case cash = "Cash"
        case venmo = "Venmo"
        case paypal = "PayPal"
        case zelle = "Zelle"
        case other = "Other"
    }
    
    enum Weekday: String, CaseIterable {
        case monday = "Mon"
        case tuesday = "Tue"
        case wednesday = "Wed"
        case thursday = "Thu"
        case friday = "Fri"
        case saturday = "Sat"
        case sunday = "Sun"
    }
    
    enum RideType: String, CaseIterable {
        case driver = "Driver"
        case passenger = "Passenger"
    }
    
    enum CommuteType: String, CaseIterable {
        case daily = "Daily"
        case occasional = "Occasional"
    }
    
    enum VehicleType: String, CaseIterable {
        case sedan = "Sedan"
        case suv = "SUV"
        case truck = "Truck"
        case van = "Van"
        case other = "Other"
    }
    
    enum CostMethod: String, CaseIterable {
        case perRide = "Per Ride"
        case perWeek = "Per Week"
        case perMonth = "Per Month"
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
        .alert("Carpool Posted!", isPresented: $showingSuccessAlert) {
            Button("OK") {
                dismiss()
                selectedTab = 0
            }
        } message: {
            Text("Your carpool has been posted! You'll be notified when someone is interested in sharing a ride.")
        }
    }
    
    var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Carpool")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(Color.hopeBlue)
                
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
            // Trip type
            VStack(alignment: .leading, spacing: 12) {
                Label("What kind of trip?", systemImage: "car.fill")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(TripType.allCases, id: \.self) { type in
                        TripTypeCard(
                            type: type,
                            isSelected: tripType == type,
                            action: { tripType = type }
                        )
                    }
                }
            }
            
            // Origin and destination
            VStack(alignment: .leading, spacing: 16) {
                Label("Trip details", systemImage: "map")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                // Info note for regular commute
                if tripType == .regular {
                    HStack(spacing: 12) {
                        Image(systemName: "info.circle.fill")
                            .font(.title3)
                            .foregroundColor(Color.hopeBlue)
                        
                        Text("For privacy, you'll arrange specific meeting points directly with your carpool partner after matching.")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.leading)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.hopeBlue.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.hopeBlue.opacity(0.3), lineWidth: 1)
                            )
                    )
                } else {
                    // Only show origin/destination for one-time trips
                    // Origin
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "location.circle.fill")
                                .foregroundColor(Color.hopeGreen)
                            Text("Starting from")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        
                        TextField("", text: $origin)
                            .placeholder(when: origin.isEmpty) {
                                Text("Enter pickup location")
                                    .foregroundColor(.gray)
                            }
                            .foregroundColor(.white)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.hopeDarkSecondary)
                            )
                    }
                    
                    // Destination
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundColor(Color.hopeOrange)
                            Text("Going to")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        
                        TextField("", text: $destination)
                            .placeholder(when: destination.isEmpty) {
                                Text("Enter destination")
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
            
            // Date and time
            VStack(alignment: .leading, spacing: 16) {
                Label("When?", systemImage: "calendar")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                if tripType == .regular {
                    // Frequency selection
                    VStack(alignment: .leading, spacing: 8) {
                        Text("How often?")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        Picker("Frequency", selection: $frequency) {
                            ForEach(Frequency.allCases, id: \.self) { freq in
                                Text(freq.rawValue).tag(freq)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .colorScheme(.dark)
                    }
                    
                    if frequency == .custom {
                        Text("Select days")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding(.top)
                        
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 8) {
                            ForEach(Weekday.allCases, id: \.self) { day in
                                CarpoolDayButton(
                                    day: day.rawValue,
                                    isSelected: selectedDays.contains(day),
                                    action: {
                                        if selectedDays.contains(day) {
                                            selectedDays.remove(day)
                                        } else {
                                            selectedDays.insert(day)
                                        }
                                    }
                                )
                            }
                        }
                    }
                } else {
                    // One-time trip date
                    DatePicker(
                        "Trip date",
                        selection: $tripDate,
                        in: Date()...,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.compact)
                    .accentColor(Color.hopeOrange)
                    .colorScheme(.dark)
                }
                
                // Time selection
                VStack(alignment: .leading, spacing: 12) {
                    DatePicker(
                        "Departure time",
                        selection: $departureTime,
                        displayedComponents: .hourAndMinute
                    )
                    .datePickerStyle(.compact)
                    .accentColor(Color.hopeOrange)
                    .colorScheme(.dark)
                    
                    // Flexible time toggle
                    Toggle(isOn: $isFlexibleTime) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Flexible timing")
                                .font(.headline)
                                .foregroundColor(.white)
                            Text("Can adjust by a few minutes")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .toggleStyle(SwitchToggleStyle(tint: Color.hopeGreen))
                    
                    if isFlexibleTime {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Flexible by: \(Int(flexibleMinutes)) minutes")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            Slider(value: $flexibleMinutes, in: 5...30, step: 5)
                                .accentColor(Color.hopeGreen)
                        }
                    }
                }
            }
        }
    }
    
    var stepTwoContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Ride preferences
            VStack(alignment: .leading, spacing: 16) {
                Label("Ride preferences", systemImage: "person.2.fill")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                // Smoking
                CarpoolPreferenceToggle(
                    title: "Smoking allowed",
                    subtitle: "Passengers can smoke",
                    icon: "smoke",
                    isOn: $smokingAllowed,
                    color: Color.gray
                )
                
                // Pets
                CarpoolPreferenceToggle(
                    title: "Pets allowed",
                    subtitle: "Furry friends welcome",
                    icon: "pawprint",
                    isOn: $petsAllowed,
                    color: Color.brown
                )
                
                // Music preference
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "music.note")
                            .foregroundColor(Color.hopePurple)
                        Text("Music preference")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    
                    VStack(spacing: 8) {
                        ForEach(MusicPreference.allCases, id: \.self) { pref in
                            CarpoolRadioButton(
                                title: pref.rawValue,
                                isSelected: musicPreference == pref,
                                action: { musicPreference = pref }
                            )
                        }
                    }
                }
                
                // Conversation level
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .foregroundColor(Color.hopeBlue)
                        Text("Conversation preference")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    
                    VStack(spacing: 8) {
                        ForEach(ConversationLevel.allCases, id: \.self) { level in
                            CarpoolRadioButton(
                                title: level.rawValue,
                                isSelected: conversationLevel == level,
                                action: { conversationLevel = level }
                            )
                        }
                    }
                }
                
                // Detour willingness
                VStack(spacing: 12) {
                    CarpoolPreferenceToggle(
                        title: "Willing to make detours",
                        subtitle: "For pickup/dropoff",
                        icon: "arrow.triangle.turn.up.right.diamond",
                        isOn: $detourWilling,
                        color: Color.hopeOrange
                    )
                    
                    if detourWilling {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Max detour: \(Int(maxDetourMinutes)) minutes")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            Slider(value: $maxDetourMinutes, in: 5...30, step: 5)
                                .accentColor(Color.hopeOrange)
                        }
                        .padding(.horizontal)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
            }
        }
    }
    
    var stepThreeContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Driver or passenger
            VStack(alignment: .leading, spacing: 12) {
                Label("Are you driving or riding?", systemImage: "car.2")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                HStack(spacing: 12) {
                    RoleCard(
                        title: "I'm Driving",
                        subtitle: "Offering seats",
                        icon: "steeringwheel",
                        isSelected: isDriver,
                        color: Color.hopeGreen,
                        action: { isDriver = true }
                    )
                    
                    RoleCard(
                        title: "Need a Ride",
                        subtitle: "Looking for driver",
                        icon: "figure.wave",
                        isSelected: !isDriver,
                        color: Color.hopeBlue,
                        action: { isDriver = false }
                    )
                }
            }
            
            if isDriver {
                // Vehicle details
                VStack(alignment: .leading, spacing: 16) {
                    Label("Vehicle details", systemImage: "car.fill")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    HStack(spacing: 12) {
                        TextField("", text: $vehicleMake)
                            .placeholder(when: vehicleMake.isEmpty) {
                                Text("Make")
                                    .foregroundColor(.gray)
                            }
                            .foregroundColor(.white)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.hopeDarkSecondary)
                            )
                        
                        TextField("", text: $vehicleModel)
                            .placeholder(when: vehicleModel.isEmpty) {
                                Text("Model")
                                    .foregroundColor(.gray)
                            }
                            .foregroundColor(.white)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.hopeDarkSecondary)
                            )
                    }
                    
                    TextField("", text: $vehicleColor)
                        .placeholder(when: vehicleColor.isEmpty) {
                            Text("Color (helps riders find you)")
                                .foregroundColor(.gray)
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.hopeDarkSecondary)
                        )
                    
                    // Available seats
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Available seats")
                                .font(.headline)
                                .foregroundColor(.white)
                            Text("Not including driver")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        Stepper("\(availableSeats)", value: $availableSeats, in: 1...7)
                            .labelsHidden()
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.hopeDarkSecondary)
                    )
                    
                    // Luggage space
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Luggage space")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                            ForEach(LuggageSpace.allCases, id: \.self) { space in
                                LuggageButton(
                                    space: space,
                                    isSelected: luggageSpace == space,
                                    action: { luggageSpace = space }
                                )
                            }
                        }
                    }
                    
                    // Accessibility options
                    VStack(spacing: 12) {
                        CarpoolPreferenceToggle(
                            title: "Child seat available",
                            subtitle: "For young passengers",
                            icon: "figure.and.child.holdinghands",
                            isOn: $hasChildSeat,
                            color: Color.yellow
                        )
                        
                        CarpoolPreferenceToggle(
                            title: "Wheelchair accessible",
                            subtitle: "Vehicle equipped for wheelchairs",
                            icon: "figure.roll",
                            isOn: $wheelchairAccessible,
                            color: Color.hopeBlue
                        )
                    }
                }
            } else {
                // Passenger preferences
                VStack(alignment: .leading, spacing: 16) {
                    Label("What do you need?", systemImage: "person.fill")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    // Number of seats needed
                    HStack {
                        Text("Seats needed: \(availableSeats)")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Stepper("", value: $availableSeats, in: 1...4)
                            .labelsHidden()
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.hopeDarkSecondary)
                    )
                    
                    // Special requirements
                    Text("Any special requirements?")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.top)
                    
                    TextField("", text: $notes)
                        .placeholder(when: notes.isEmpty) {
                            Text("e.g., Need trunk space for luggage, traveling with a pet...")
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
    }
    
    var stepFourContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Cost sharing
            VStack(alignment: .leading, spacing: 16) {
                Label("Cost sharing", systemImage: "dollarsign.circle")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                VStack(spacing: 8) {
                    ForEach(CostSharing.allCases, id: \.self) { type in
                        CostSharingCard(
                            type: type,
                            isSelected: costSharingType == type,
                            action: { costSharingType = type }
                        )
                    }
                }
                
                if costSharingType == .splitGas || costSharingType == .fixedAmount {
                    TextField("", text: $estimatedCost)
                        .placeholder(when: estimatedCost.isEmpty) {
                            Text(costSharingType == .splitGas ? "Estimated gas cost to split" : "Amount per person")
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
                
                // Payment method
                if costSharingType != .free {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Preferred payment method")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                            ForEach(PaymentMethod.allCases, id: \.self) { method in
                                PaymentButton(
                                    method: method,
                                    isSelected: paymentMethod == method,
                                    action: { paymentMethod = method }
                                )
                            }
                        }
                    }
                }
            }
            
            // Additional notes
            VStack(alignment: .leading, spacing: 12) {
                Label("Anything else to add?", systemImage: "text.bubble")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                TextEditor(text: $notes)
                    .placeholder(when: notes.isEmpty) {
                        Text("Special instructions, meeting point details, etc...")
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
                                CarpoolDonationOption(
                                    amount: "$1",
                                    isSelected: selectedDonationOption == 0,
                                    action: {
                                        selectedDonationOption = 0
                                        donationAmount = 1.0
                                        customDonationAmount = ""
                                    }
                                )
                                
                                CarpoolDonationOption(
                                    amount: "$5",
                                    isSelected: selectedDonationOption == 1,
                                    action: {
                                        selectedDonationOption = 1
                                        donationAmount = 5.0
                                        customDonationAmount = ""
                                    }
                                )
                                
                                CarpoolDonationOption(
                                    amount: "$10",
                                    isSelected: selectedDonationOption == 2,
                                    action: {
                                        selectedDonationOption = 2
                                        donationAmount = 10.0
                                        customDonationAmount = ""
                                    }
                                )
                                
                                CarpoolDonationOption(
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
            
            // Summary
            VStack(alignment: .leading, spacing: 16) {
                Label("Ready to post!", systemImage: "checkmark.circle.fill")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.hopeGreen)
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: tripType.icon)
                            .foregroundColor(tripType.color)
                        if tripType == .regular {
                            Text("Regular \(frequency.rawValue) commute")
                                .font(.headline)
                                .foregroundColor(.white)
                        } else {
                            Text("\(origin.isEmpty ? "Starting point" : origin) → \(destination.isEmpty ? "Destination" : destination)")
                                .font(.headline)
                                .foregroundColor(.white)
                                .lineLimit(1)
                        }
                    }
                    
                    HStack {
                        Image(systemName: isDriver ? "car.fill" : "figure.wave")
                            .foregroundColor(Color.hopeOrange)
                        Text(isDriver ? "Offering \(availableSeats) seat\(availableSeats == 1 ? "" : "s")" : "Need \(availableSeats) seat\(availableSeats == 1 ? "" : "s")")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        Image(systemName: "dollarsign.circle")
                            .foregroundColor(Color.hopeGreen)
                        Text(costSharingType.rawValue)
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
                        (showListingFee ? "Post Carpool ($1 fee)" : 
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
                        .fill(canProceed() ? Color.hopeBlue : Color.gray.opacity(0.3))
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
            if tripType == .regular {
                // For regular commutes, only need frequency/days selection
                return frequency != .custom || !selectedDays.isEmpty
            } else {
                // For one-time trips, need origin and destination
                return !origin.isEmpty && !destination.isEmpty
            }
        case 2:
            return true // All have defaults
        case 3:
            if isDriver {
                return !vehicleMake.isEmpty && !vehicleModel.isEmpty && !vehicleColor.isEmpty
            } else {
                return true
            }
        case 4:
            return costSharingType == .free || !estimatedCost.isEmpty
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
            postCarpool()
        }
    }
    
    func previousStep() {
        if currentStep > 1 {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep -= 1
            }
        }
    }
    
    private func postCarpool() {
        // Process donation if applicable
        if donationAmount > 0 {
            // In a real app, this would process the payment through Stripe or similar
            print("Processing donation of $\(donationAmount) to Hyundai Hope on Wheels")
        }
        
        // Create formatted description
        var description = "🚗 Carpool Request\n\n"
        if tripType == .regular {
            description += "**Type:** Regular \(frequency.rawValue) commute\n"
        } else {
            description += "**Route:** \(origin.isEmpty ? "Not specified" : origin) to \(destination.isEmpty ? "Not specified" : destination)\n"
        }
        if frequency == .custom && !selectedDays.isEmpty {
            description += "**Schedule:** \(selectedDays.map { $0.rawValue }.joined(separator: ", "))\n"
        } else if frequency != .oneTime {
            description += "**Schedule:** \(frequency.rawValue)\n"
        }
        description += "**Time:** \(isFlexibleTime ? "Flexible" : DateFormatter.localizedString(from: departureTime, dateStyle: .none, timeStyle: .short))\n\n"
        
        if rideType == .driver {
            description += "**Offering:** \(vehicleType.rawValue) with \(seatsAvailable) seat(s) available\n"
            description += "**Cost sharing:** $\(String(format: "%.0f", costPerRide))\(costSharingMethod == .perRide ? " per ride" : " " + costSharingMethod.rawValue)\n"
        } else {
            description += "**Looking for:** \(lookingForDriver ? "Driver" : lookingForRiders ? "Riders to share costs" : "Carpool partner")\n"
        }
        
        if !carpoolRules.isEmpty {
            description += "\n**Preferences:** \(carpoolRules)\n"
        }
        
        description += "\n**Distance willing to detour:** \(Int(maxDetour)) miles\n"
        description += "**Music preference:** \(musicPreference.rawValue)\n"
        description += "**Conversation:** \(conversationPreference.rawValue)\n"
        
        if !additionalNotes.isEmpty {
            description += "\n**Additional notes:** \(additionalNotes)"
        }
        
        // Create the item
        let newItem = Item(
            title: tripType == .regular ? "Regular Commute Partner" : "Carpool: \(origin) to \(destination)",
            description: description,
            category: .miscellaneous,
            condition: .new,
            userId: UUID(),
            location: tripType == .regular ? "Private - Contact to Arrange" : (origin.isEmpty ? "Current Location" : origin),
            price: 0,
            priceIsFirm: true,
            images: [],
            listingType: .carpool
        )
        
        Task {
            await dataManager.addItem(newItem)
            showingSuccessAlert = true
        }
    }
}

// MARK: - Supporting Views

struct TripTypeCard: View {
    let type: CarpoolFlow.TripType
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
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
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

struct CarpoolDayButton: View {
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

struct CarpoolPreferenceToggle: View {
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

struct CarpoolRadioButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Circle()
                    .stroke(isSelected ? Color.hopeOrange : Color.gray, lineWidth: 2)
                    .frame(width: 20, height: 20)
                    .overlay(
                        Circle()
                            .fill(Color.hopeOrange)
                            .frame(width: 12, height: 12)
                            .opacity(isSelected ? 1 : 0)
                    )
                
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.white)
                
                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.hopeDarkSecondary)
            )
        }
    }
}

struct RoleCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(color.opacity(isSelected ? 1 : 0.2))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(isSelected ? Color.hopeDarkBg : color)
                }
                
                VStack(spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.hopeDarkSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? color : Color.clear, lineWidth: 2)
                    )
            )
        }
    }
}

struct LuggageButton: View {
    let space: CarpoolFlow.LuggageSpace
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(space.rawValue)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? Color.hopeDarkBg : .white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? Color.hopePurple : Color.hopeDarkSecondary)
                )
        }
    }
}

struct CostSharingCard: View {
    let type: CarpoolFlow.CostSharing
    let isSelected: Bool
    let action: () -> Void
    
    var icon: String {
        switch type {
        case .free: return "gift"
        case .splitGas: return "fuelpump"
        case .fixedAmount: return "dollarsign.circle"
        case .donation: return "heart"
        }
    }
    
    var color: Color {
        switch type {
        case .free: return Color.hopeGreen
        case .splitGas: return Color.hopeOrange
        case .fixedAmount: return Color.hopeBlue
        case .donation: return Color.hopePink
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.headline)
                    .foregroundColor(isSelected ? Color.hopeDarkBg : color)
                
                Text(type.rawValue)
                    .font(.headline)
                    .foregroundColor(isSelected ? Color.hopeDarkBg : .white)
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? Color.hopeDarkBg : .gray)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? color : Color.hopeDarkSecondary)
            )
        }
    }
}

struct PaymentButton: View {
    let method: CarpoolFlow.PaymentMethod
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(method.rawValue)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? Color.hopeDarkBg : .white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? Color.hopeGreen : Color.hopeDarkSecondary)
                )
        }
    }
}

struct CarpoolDonationOption: View {
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
    CarpoolFlow(selectedTab: .constant(0))
        .environmentObject(DataManager.shared)
}