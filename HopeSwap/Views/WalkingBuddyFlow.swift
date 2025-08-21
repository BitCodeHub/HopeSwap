import SwiftUI
import MapKit

struct WalkingBuddyFlow: View {
    @EnvironmentObject var dataManager: DataManager
    @Binding var selectedTab: Int
    @Environment(\.dismiss) var dismiss
    
    @State private var currentStep = 1
    @State private var showingSuccessAlert = false
    
    // Basic info
    @State private var headline = ""
    @State private var aboutMe = ""
    @State private var age = ""
    @State private var gender: Gender = .noPreference
    @State private var buddyGenderPreference: Gender = .noPreference
    
    // Walking preferences
    @State private var walkingPurpose: Set<WalkingPurpose> = []
    @State private var pace: PaceLevel = .moderate
    @State private var typicalDistance = ""
    @State private var typicalDuration: Duration = .thirtyToSixty
    @State private var experienceLevel: Experience = .regular
    
    // Routes and locations
    @State private var favoriteRoutes = ""
    @State private var neighborhood = ""
    @State private var terrainPreference: Set<Terrain> = []
    @State private var maxDistance = 3.0
    @State private var hasPreferredRoutes = false
    @State private var openToNewRoutes = true
    
    // Schedule and safety
    @State private var preferredDays: Set<Weekday> = []
    @State private var preferredTimes: Set<TimeSlot> = []
    @State private var safetyPreferences: Set<SafetyPreference> = []
    @State private var bringsCompanion: CompanionType = .none
    @State private var additionalNotes = ""
    
    // Listing fee and donation
    @State private var showListingFee = true
    @State private var donationAmount = 1.0
    @State private var selectedDonationOption = 0
    @State private var customDonationAmount = ""
    
    enum Gender: String, CaseIterable {
        case male = "Male"
        case female = "Female"
        case other = "Other"
        case noPreference = "No Preference"
    }
    
    enum WalkingPurpose: String, CaseIterable {
        case exercise = "Exercise/Fitness"
        case dogWalking = "Dog Walking"
        case socializing = "Socializing"
        case stressRelief = "Stress Relief"
        case exploration = "Explore Area"
        case photography = "Photography"
        case birdwatching = "Bird Watching"
        case meditation = "Walking Meditation"
        
        var icon: String {
            switch self {
            case .exercise: return "figure.walk"
            case .dogWalking: return "pawprint"
            case .socializing: return "bubble.left.and.bubble.right"
            case .stressRelief: return "brain"
            case .exploration: return "map"
            case .photography: return "camera"
            case .birdwatching: return "binoculars"
            case .meditation: return "leaf"
            }
        }
        
        var color: Color {
            switch self {
            case .exercise: return Color.hopeOrange
            case .dogWalking: return Color.brown
            case .socializing: return Color.hopeBlue
            case .stressRelief: return Color.hopePurple
            case .exploration: return Color.hopeGreen
            case .photography: return Color.hopePink
            case .birdwatching: return Color.yellow
            case .meditation: return Color.mint
            }
        }
    }
    
    enum PaceLevel: String, CaseIterable {
        case leisurely = "Leisurely"
        case moderate = "Moderate"
        case brisk = "Brisk"
        case powerWalking = "Power Walking"
        case mixed = "Mixed/Flexible"
        
        var description: String {
            switch self {
            case .leisurely: return "Casual stroll, lots of stops"
            case .moderate: return "Steady pace, some breaks"
            case .brisk: return "Fast walk, few breaks"
            case .powerWalking: return "Athletic pace"
            case .mixed: return "Varies by mood"
            }
        }
        
        var icon: String {
            switch self {
            case .leisurely: return "tortoise"
            case .moderate: return "figure.walk"
            case .brisk: return "figure.walk.motion"
            case .powerWalking: return "hare"
            case .mixed: return "arrow.left.arrow.right"
            }
        }
    }
    
    enum Duration: String, CaseIterable {
        case underThirty = "Under 30 min"
        case thirtyToSixty = "30-60 min"
        case oneToTwo = "1-2 hours"
        case twoPlus = "2+ hours"
        case flexible = "Flexible"
    }
    
    enum Experience: String, CaseIterable {
        case newWalker = "New Walker"
        case occasional = "Occasional"
        case regular = "Regular Walker"
        case daily = "Daily Walker"
        case expert = "Trail Expert"
    }
    
    enum Terrain: String, CaseIterable {
        case sidewalks = "Sidewalks/Streets"
        case parks = "Parks"
        case trails = "Nature Trails"
        case beach = "Beach"
        case hills = "Hills/Inclines"
        case track = "Track/Loop"
        case mall = "Indoor/Mall"
        case mixed = "Any Terrain"
        
        var icon: String {
            switch self {
            case .sidewalks: return "road.lanes"
            case .parks: return "tree"
            case .trails: return "map"
            case .beach: return "beach.umbrella"
            case .hills: return "mountain.2"
            case .track: return "circle.dashed"
            case .mall: return "building.2"
            case .mixed: return "globe"
            }
        }
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
    
    enum TimeSlot: String, CaseIterable {
        case earlyMorning = "Early Morning (5-7am)"
        case morning = "Morning (7-10am)"
        case midday = "Midday (10am-2pm)"
        case afternoon = "Afternoon (2-5pm)"
        case evening = "Evening (5-8pm)"
        case night = "Night (8pm+)"
    }
    
    enum SafetyPreference: String, CaseIterable {
        case wellLitAreas = "Well-lit areas only"
        case populatedRoutes = "Populated routes"
        case phoneTracking = "Share location"
        case emergencyContact = "Emergency contact"
        case noHeadphones = "No headphones"
        case carryProtection = "Carry protection"
        
        var icon: String {
            switch self {
            case .wellLitAreas: return "lightbulb"
            case .populatedRoutes: return "person.3"
            case .phoneTracking: return "location.circle"
            case .emergencyContact: return "phone.circle"
            case .noHeadphones: return "headphones.circle.fill"
            case .carryProtection: return "shield"
            }
        }
    }
    
    enum CompanionType: String, CaseIterable {
        case none = "Just Me"
        case dog = "With Dog"
        case child = "With Child"
        case both = "Dog & Child"
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
        .alert("Walking Buddy Request Posted!", isPresented: $showingSuccessAlert) {
            Button("OK") {
                dismiss()
                selectedTab = 0
            }
        } message: {
            Text("Your walking buddy request has been posted! You'll be notified when someone with similar preferences wants to walk.")
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
                Text("Walking Buddy")
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
            // Introduction
            VStack(alignment: .leading, spacing: 12) {
                Label("Tell us about yourself", systemImage: "person.fill")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                TextField("", text: $headline)
                    .placeholder(when: headline.isEmpty) {
                        Text("Headline (e.g., \"Morning walker seeking company for park routes\")")
                            .foregroundColor(.gray)
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.hopeDarkSecondary)
                    )
                
                TextEditor(text: $aboutMe)
                    .placeholder(when: aboutMe.isEmpty) {
                        Text("Share a bit about yourself, why you walk, what you enjoy about it...")
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
            
            // Demographics
            VStack(alignment: .leading, spacing: 16) {
                Label("Basic info", systemImage: "info.circle")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                // Age
                HStack {
                    Text("Age")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    TextField("", text: $age)
                        .placeholder(when: age.isEmpty) {
                            Text("Optional")
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
                
                // Gender
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your gender")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(Gender.allCases, id: \.self) { gender in
                            WalkingGenderButton(
                                gender: gender,
                                isSelected: self.gender == gender,
                                action: { self.gender = gender }
                            )
                        }
                    }
                }
                
                // Buddy preference
                VStack(alignment: .leading, spacing: 8) {
                    Text("Walking buddy gender preference")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(Gender.allCases, id: \.self) { gender in
                            WalkingGenderButton(
                                gender: gender,
                                isSelected: self.buddyGenderPreference == gender,
                                action: { self.buddyGenderPreference = gender }
                            )
                        }
                    }
                }
            }
        }
    }
    
    var stepTwoContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Walking purpose
            VStack(alignment: .leading, spacing: 12) {
                Label("Why do you walk?", systemImage: "figure.walk")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text("Select all that apply")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(WalkingPurpose.allCases, id: \.self) { purpose in
                        PurposeCard(
                            purpose: purpose,
                            isSelected: walkingPurpose.contains(purpose),
                            action: {
                                if walkingPurpose.contains(purpose) {
                                    walkingPurpose.remove(purpose)
                                } else {
                                    walkingPurpose.insert(purpose)
                                }
                            }
                        )
                    }
                }
            }
            
            // Walking pace
            VStack(alignment: .leading, spacing: 12) {
                Label("Your walking pace", systemImage: "speedometer")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                VStack(spacing: 8) {
                    ForEach(PaceLevel.allCases, id: \.self) { paceLevel in
                        PaceCard(
                            pace: paceLevel,
                            isSelected: pace == paceLevel,
                            action: { pace = paceLevel }
                        )
                    }
                }
            }
            
            // Distance and duration
            VStack(alignment: .leading, spacing: 16) {
                Label("Typical walk details", systemImage: "ruler")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                // Distance
                TextField("", text: $typicalDistance)
                    .placeholder(when: typicalDistance.isEmpty) {
                        Text("Typical distance (e.g., 2-3 miles, 5k)")
                            .foregroundColor(.gray)
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.hopeDarkSecondary)
                    )
                
                // Duration
                VStack(alignment: .leading, spacing: 8) {
                    Text("Typical duration")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(Duration.allCases, id: \.self) { duration in
                            WalkingDurationButton(
                                duration: duration,
                                isSelected: typicalDuration == duration,
                                action: { typicalDuration = duration }
                            )
                        }
                    }
                }
                
                // Experience level
                VStack(alignment: .leading, spacing: 8) {
                    Text("Walking experience")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(Experience.allCases, id: \.self) { level in
                            WalkingExperienceButton(
                                experience: level,
                                isSelected: experienceLevel == level,
                                action: { experienceLevel = level }
                            )
                        }
                    }
                }
            }
        }
    }
    
    var stepThreeContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Location preferences
            VStack(alignment: .leading, spacing: 16) {
                Label("Where do you like to walk?", systemImage: "location")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                // Neighborhood
                TextField("", text: $neighborhood)
                    .placeholder(when: neighborhood.isEmpty) {
                        Text("Your neighborhood or area")
                            .foregroundColor(.gray)
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.hopeDarkSecondary)
                    )
                
                // Favorite routes
                TextEditor(text: $favoriteRoutes)
                    .placeholder(when: favoriteRoutes.isEmpty) {
                        Text("Describe your favorite walking routes or areas...")
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
                
                // Route preferences
                VStack(spacing: 12) {
                    WalkingPreferenceToggle(
                        title: "Have preferred routes",
                        subtitle: "Stick to familiar paths",
                        icon: "map.circle",
                        isOn: $hasPreferredRoutes,
                        color: Color.hopeGreen
                    )
                    
                    WalkingPreferenceToggle(
                        title: "Open to new routes",
                        subtitle: "Enjoy exploring",
                        icon: "location.magnifyingglass",
                        isOn: $openToNewRoutes,
                        color: Color.hopeBlue
                    )
                }
                
                // Distance willing to travel
                VStack(alignment: .leading, spacing: 8) {
                    Text("Willing to meet within: \(Int(maxDistance)) miles")
                        .font(.subheadline)
                        .foregroundColor(.white)
                    
                    Slider(value: $maxDistance, in: 1...10, step: 0.5)
                        .accentColor(Color.hopeOrange)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.hopeDarkSecondary)
                )
            }
            
            // Terrain preferences
            VStack(alignment: .leading, spacing: 12) {
                Label("Preferred terrain", systemImage: "map")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text("Select all that apply")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(Terrain.allCases, id: \.self) { terrain in
                        TerrainButton(
                            terrain: terrain,
                            isSelected: terrainPreference.contains(terrain),
                            action: {
                                if terrainPreference.contains(terrain) {
                                    terrainPreference.remove(terrain)
                                } else {
                                    terrainPreference.insert(terrain)
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
            // Schedule
            VStack(alignment: .leading, spacing: 12) {
                Label("When can you walk?", systemImage: "calendar")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                // Days
                Text("Preferred days")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 8) {
                    ForEach(Weekday.allCases, id: \.self) { day in
                        WalkingDayButton(
                            day: day.rawValue,
                            isSelected: preferredDays.contains(day),
                            action: {
                                if preferredDays.contains(day) {
                                    preferredDays.remove(day)
                                } else {
                                    preferredDays.insert(day)
                                }
                            }
                        )
                    }
                }
                
                // Time slots
                Text("Preferred times")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.top)
                
                VStack(spacing: 8) {
                    ForEach(TimeSlot.allCases, id: \.self) { slot in
                        WalkingTimeSlotButton(
                            slot: slot.rawValue,
                            isSelected: preferredTimes.contains(slot),
                            action: {
                                if preferredTimes.contains(slot) {
                                    preferredTimes.remove(slot)
                                } else {
                                    preferredTimes.insert(slot)
                                }
                            }
                        )
                    }
                }
            }
            
            // Safety preferences
            VStack(alignment: .leading, spacing: 12) {
                Label("Safety preferences", systemImage: "shield")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text("Select all that apply")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                VStack(spacing: 8) {
                    ForEach(SafetyPreference.allCases, id: \.self) { pref in
                        SafetyButton(
                            preference: pref,
                            isSelected: safetyPreferences.contains(pref),
                            action: {
                                if safetyPreferences.contains(pref) {
                                    safetyPreferences.remove(pref)
                                } else {
                                    safetyPreferences.insert(pref)
                                }
                            }
                        )
                    }
                }
            }
            
            // Companion info
            VStack(alignment: .leading, spacing: 12) {
                Label("Walking companions", systemImage: "figure.2")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Picker("Who walks with you?", selection: $bringsCompanion) {
                    ForEach(CompanionType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .colorScheme(.dark)
                
                if bringsCompanion == .dog || bringsCompanion == .both {
                    Text("🐕 Make sure to mention your dog's temperament!")
                        .font(.caption)
                        .foregroundColor(.yellow)
                        .padding(.horizontal)
                }
            }
            
            // Additional notes
            VStack(alignment: .leading, spacing: 12) {
                Label("Anything else?", systemImage: "text.bubble")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                TextEditor(text: $additionalNotes)
                    .placeholder(when: additionalNotes.isEmpty) {
                        Text("Health considerations, conversation topics you enjoy, or anything else buddies should know...")
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
                                DonationOption(
                                    amount: "$1",
                                    isSelected: selectedDonationOption == 0,
                                    action: {
                                        selectedDonationOption = 0
                                        donationAmount = 1.0
                                        customDonationAmount = ""
                                    }
                                )
                                
                                DonationOption(
                                    amount: "$5",
                                    isSelected: selectedDonationOption == 1,
                                    action: {
                                        selectedDonationOption = 1
                                        donationAmount = 5.0
                                        customDonationAmount = ""
                                    }
                                )
                                
                                DonationOption(
                                    amount: "$10",
                                    isSelected: selectedDonationOption == 2,
                                    action: {
                                        selectedDonationOption = 2
                                        donationAmount = 10.0
                                        customDonationAmount = ""
                                    }
                                )
                                
                                DonationOption(
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
                Label("Ready to find your buddy!", systemImage: "checkmark.circle.fill")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.hopeGreen)
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "figure.walk")
                            .foregroundColor(Color.hopeOrange)
                        Text(headline.isEmpty ? "Looking for walking buddy" : headline)
                            .font(.headline)
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }
                    
                    HStack {
                        Image(systemName: pace.icon)
                            .foregroundColor(Color.hopeBlue)
                        Text("\(pace.rawValue) pace")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    
                    if !preferredDays.isEmpty {
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(Color.hopePurple)
                            Text("\(preferredDays.count) days selected")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
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
                Button(action: postWalkingBuddy) {
                    HStack {
                        Image(systemName: "figure.walk")
                            .font(.headline)
                        Text(donationAmount > 0 ? String(format: "Post for $%.2f", donationAmount) : "Post for Free")
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
            return !headline.isEmpty && !aboutMe.isEmpty
        case 2:
            return !walkingPurpose.isEmpty
        case 3:
            return !neighborhood.isEmpty && !terrainPreference.isEmpty
        case 4:
            return !preferredDays.isEmpty && !preferredTimes.isEmpty
        default:
            return true
        }
    }
    
    private func postWalkingBuddy() {
        // Process donation if applicable
        if donationAmount > 0 {
            // In a real app, this would process the payment through Stripe or similar
            print("Processing donation of $\(donationAmount) to Hyundai Hope on Wheels")
        }
        
        // Create formatted description
        var description = "🚶 Walking Buddy Request\n\n"
        description += "**About me:** \(aboutMe.isEmpty ? "Not specified" : aboutMe)\n\n"
        
        if !age.isEmpty {
            description += "**Age:** \(age)\n"
        }
        description += "**Gender:** \(gender.rawValue)\n"
        description += "**Looking for:** \(buddyGenderPreference.rawValue) buddy\n\n"
        
        description += "**Walking purposes:** \(walkingPurpose.map { $0.rawValue }.joined(separator: ", "))\n"
        description += "**Pace:** \(pace.rawValue) - \(pace.description)\n"
        if !typicalDistance.isEmpty {
            description += "**Typical distance:** \(typicalDistance)\n"
        }
        description += "**Duration:** \(typicalDuration.rawValue)\n"
        description += "**Experience:** \(experienceLevel.rawValue)\n\n"
        
        description += "**Schedule:** \(preferredDays.map { $0.rawValue }.joined(separator: ", "))\n"
        description += "**Times:** \(preferredTimes.map { $0.rawValue }.joined(separator: ", "))\n\n"
        
        description += "**Location:** \(neighborhood.isEmpty ? "Not specified" : neighborhood)\n"
        if !favoriteRoutes.isEmpty {
            description += "**Favorite routes:** \(favoriteRoutes)\n"
        }
        description += "**Max distance from home:** \(Int(maxDistance)) miles\n"
        if !terrainPreference.isEmpty {
            description += "**Terrain preference:** \(terrainPreference.map { $0.rawValue }.joined(separator: ", "))\n"
        }
        description += "**Open to new routes:** \(openToNewRoutes ? "Yes" : "No")\n\n"
        
        if !safetyPreferences.isEmpty {
            description += "**Safety preferences:** \(safetyPreferences.map { $0.rawValue }.joined(separator: ", "))\n"
        }
        if bringsCompanion != .none {
            description += "**Brings:** \(bringsCompanion.rawValue)\n"
        }
        
        if !additionalNotes.isEmpty {
            description += "\n**Additional notes:** \(additionalNotes)"
        }
        
        // Create the item
        let newItem = Item(
            title: headline.isEmpty ? "Looking for Walking Buddy" : headline,
            description: description,
            category: .sportingGoods,
            condition: .new,
            userId: UUID(),
            location: neighborhood.isEmpty ? "Current Location" : neighborhood,
            price: 0,
            priceIsFirm: true,
            images: []
        )
        
        dataManager.addItem(newItem)
        showingSuccessAlert = true
    }
}

// MARK: - Supporting Views

struct WalkingGenderButton: View {
    let gender: WalkingBuddyFlow.Gender
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(gender.rawValue)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? Color.hopeDarkBg : .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? Color.hopeOrange : Color.hopeDarkSecondary)
                )
        }
    }
}

struct PurposeCard: View {
    let purpose: WalkingBuddyFlow.WalkingPurpose
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isSelected ? purpose.color : purpose.color.opacity(0.2))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: purpose.icon)
                        .font(.title3)
                        .foregroundColor(isSelected ? Color.hopeDarkBg : purpose.color)
                }
                
                Text(purpose.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 4)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.hopeDarkSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? purpose.color : Color.clear, lineWidth: 2)
                    )
            )
        }
    }
}

struct PaceCard: View {
    let pace: WalkingBuddyFlow.PaceLevel
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: pace.icon)
                    .font(.title3)
                    .foregroundColor(isSelected ? Color.hopeDarkBg : Color.hopeOrange)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(pace.rawValue)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(pace.description)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color.hopeOrange)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.hopeOrange.opacity(0.2) : Color.hopeDarkSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.hopeOrange : Color.clear, lineWidth: 2)
                    )
            )
        }
    }
}

struct TerrainButton: View {
    let terrain: WalkingBuddyFlow.Terrain
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: terrain.icon)
                    .font(.title3)
                    .foregroundColor(isSelected ? Color.hopeDarkBg : Color.hopeGreen)
                
                Text(terrain.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? Color.hopeDarkBg : .white)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.hopeGreen : Color.hopeDarkSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.hopeGreen : Color.clear, lineWidth: 2)
                    )
            )
        }
    }
}

struct SafetyButton: View {
    let preference: WalkingBuddyFlow.SafetyPreference
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: preference.icon)
                    .font(.headline)
                    .foregroundColor(isSelected ? Color.hopeDarkBg : Color.yellow)
                    .frame(width: 30)
                
                Text(preference.rawValue)
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
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.yellow : Color.hopeDarkSecondary)
            )
        }
    }
}

struct WalkingDurationButton: View {
    let duration: WalkingBuddyFlow.Duration
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(duration.rawValue)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? Color.hopeDarkBg : .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? Color.hopePurple : Color.hopeDarkSecondary)
                )
        }
    }
}

struct WalkingExperienceButton: View {
    let experience: WalkingBuddyFlow.Experience
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(experience.rawValue)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? Color.hopeDarkBg : .white)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .padding(.horizontal, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? Color.hopeGreen : Color.hopeDarkSecondary)
                )
        }
    }
}

struct WalkingDayButton: View {
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

struct WalkingTimeSlotButton: View {
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

struct WalkingPreferenceToggle: View {
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

struct DonationOption: View {
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
    WalkingBuddyFlow(selectedTab: .constant(0))
        .environmentObject(DataManager.shared)
}