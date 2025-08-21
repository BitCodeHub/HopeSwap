import SwiftUI

struct WorkoutBuddyFlow: View {
    @EnvironmentObject var dataManager: DataManager
    @Binding var selectedTab: Int
    @Environment(\.dismiss) var dismiss
    
    @State private var currentStep = 1
    @State private var showingSuccessAlert = false
    
    // Basic info
    @State private var headline = ""
    @State private var bio = ""
    @State private var age = ""
    @State private var gender: Gender = .noPreference
    @State private var buddyGenderPreference: Gender = .noPreference
    
    // Workout preferences
    @State private var workoutTypes: Set<WorkoutType> = []
    @State private var fitnessLevel: FitnessLevel = .intermediate
    @State private var experience = ""
    @State private var goals: Set<Goal> = []
    @State private var customGoal = ""
    
    // Schedule and location
    @State private var preferredDays: Set<Weekday> = []
    @State private var preferredTimes: Set<TimeSlot> = []
    @State private var gymName = ""
    @State private var location = ""
    @State private var canMeetAtHome = false
    @State private var canMeetOutdoors = false
    @State private var maxDistance = 5.0
    
    // Preferences and rules
    @State private var workoutDuration: Duration = .oneHour
    @State private var musicPreference: MusicPreference = .open
    @State private var conversationWhileWorking = true
    @State private var spotterAvailable = true
    @State private var shareEquipment = true
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
    
    enum WorkoutType: String, CaseIterable {
        case weightlifting = "Weightlifting"
        case cardio = "Cardio"
        case yoga = "Yoga"
        case pilates = "Pilates"
        case crossfit = "CrossFit"
        case running = "Running"
        case cycling = "Cycling"
        case swimming = "Swimming"
        case boxing = "Boxing/MMA"
        case dance = "Dance/Zumba"
        case hiking = "Hiking"
        case sports = "Sports"
        
        var icon: String {
            switch self {
            case .weightlifting: return "dumbbell.fill"
            case .cardio: return "figure.run"
            case .yoga: return "figure.yoga"
            case .pilates: return "figure.pilates"
            case .crossfit: return "figure.cross.training"
            case .running: return "figure.run.circle"
            case .cycling: return "bicycle"
            case .swimming: return "figure.pool.swim"
            case .boxing: return "figure.boxing"
            case .dance: return "figure.dance"
            case .hiking: return "figure.hiking"
            case .sports: return "sportscourt"
            }
        }
        
        var color: Color {
            switch self {
            case .weightlifting: return Color.red
            case .cardio: return Color.hopeOrange
            case .yoga: return Color.hopePurple
            case .pilates: return Color.mint
            case .crossfit: return Color.hopeGreen
            case .running: return Color.hopeBlue
            case .cycling: return Color.yellow
            case .swimming: return Color.cyan
            case .boxing: return Color.brown
            case .dance: return Color.hopePink
            case .hiking: return Color.green
            case .sports: return Color.indigo
            }
        }
    }
    
    enum FitnessLevel: String, CaseIterable {
        case beginner = "Beginner"
        case intermediate = "Intermediate"
        case advanced = "Advanced"
        case expert = "Expert/Athlete"
        
        var description: String {
            switch self {
            case .beginner: return "Just starting out"
            case .intermediate: return "Regular workouts"
            case .advanced: return "Serious training"
            case .expert: return "Competitive level"
            }
        }
        
        var color: Color {
            switch self {
            case .beginner: return Color.hopeGreen
            case .intermediate: return Color.hopeBlue
            case .advanced: return Color.hopeOrange
            case .expert: return Color.red
            }
        }
    }
    
    enum Goal: String, CaseIterable {
        case loseWeight = "Lose Weight"
        case buildMuscle = "Build Muscle"
        case getToned = "Get Toned"
        case improveEndurance = "Improve Endurance"
        case stayActive = "Stay Active"
        case trainForEvent = "Train for Event"
        case rehabilitation = "Rehabilitation"
        case mentalHealth = "Mental Health"
        
        var icon: String {
            switch self {
            case .loseWeight: return "arrow.down.circle"
            case .buildMuscle: return "arrow.up.circle"
            case .getToned: return "figure.strengthtraining.traditional"
            case .improveEndurance: return "heart.circle"
            case .stayActive: return "figure.walk.motion"
            case .trainForEvent: return "trophy"
            case .rehabilitation: return "cross.circle"
            case .mentalHealth: return "brain"
            }
        }
        
        var color: Color {
            switch self {
            case .loseWeight: return Color.hopeGreen
            case .buildMuscle: return Color.red
            case .getToned: return Color.hopePurple
            case .improveEndurance: return Color.hopeOrange
            case .stayActive: return Color.hopeBlue
            case .trainForEvent: return Color.yellow
            case .rehabilitation: return Color.mint
            case .mentalHealth: return Color.pink
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
    
    enum Duration: String, CaseIterable {
        case thirtyMin = "30 minutes"
        case fortyFiveMin = "45 minutes"
        case oneHour = "1 hour"
        case ninetyMin = "1.5 hours"
        case twoHours = "2+ hours"
        case flexible = "Flexible"
    }
    
    enum MusicPreference: String, CaseIterable {
        case myPlaylist = "My Playlist"
        case theirPlaylist = "Their Playlist"
        case taketurns = "Take Turns"
        case noMusic = "No Music"
        case open = "Open to Anything"
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
        .alert("Workout Buddy Request Posted!", isPresented: $showingSuccessAlert) {
            Button("OK") {
                dismiss()
                selectedTab = 0
            }
        } message: {
            Text("Your workout buddy request has been posted! You'll be notified when someone matches your preferences.")
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
                Text("Workout Buddy")
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
                        Text("Headline (e.g., \"Looking for a gym partner for morning workouts\")")
                            .foregroundColor(.gray)
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.hopeDarkSecondary)
                    )
                
                TextEditor(text: $bio)
                    .placeholder(when: bio.isEmpty) {
                        Text("Tell potential buddies about yourself, your fitness journey, what motivates you...")
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
                            WorkoutGenderButton(
                                gender: gender,
                                isSelected: self.gender == gender,
                                action: { self.gender = gender }
                            )
                        }
                    }
                }
                
                // Buddy preference
                VStack(alignment: .leading, spacing: 8) {
                    Text("Workout buddy gender preference")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(Gender.allCases, id: \.self) { gender in
                            WorkoutGenderButton(
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
            // Workout types
            VStack(alignment: .leading, spacing: 12) {
                Label("What type of workouts?", systemImage: "figure.run")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text("Select all that apply")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(WorkoutType.allCases, id: \.self) { type in
                        WorkoutTypeCard(
                            type: type,
                            isSelected: workoutTypes.contains(type),
                            action: {
                                if workoutTypes.contains(type) {
                                    workoutTypes.remove(type)
                                } else {
                                    workoutTypes.insert(type)
                                }
                            }
                        )
                    }
                }
            }
            
            // Fitness level
            VStack(alignment: .leading, spacing: 12) {
                Label("Your fitness level", systemImage: "chart.line.uptrend.xyaxis")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                VStack(spacing: 8) {
                    ForEach(FitnessLevel.allCases, id: \.self) { level in
                        FitnessLevelCard(
                            level: level,
                            isSelected: fitnessLevel == level,
                            action: { fitnessLevel = level }
                        )
                    }
                }
            }
            
            // Experience
            VStack(alignment: .leading, spacing: 12) {
                Label("Years of experience", systemImage: "calendar")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                TextField("", text: $experience)
                    .placeholder(when: experience.isEmpty) {
                        Text("e.g., 2 years lifting, new to running")
                            .foregroundColor(.gray)
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.hopeDarkSecondary)
                    )
            }
            
            // Goals
            VStack(alignment: .leading, spacing: 12) {
                Label("Fitness goals", systemImage: "target")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text("Select all that apply")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(Goal.allCases, id: \.self) { goal in
                        GoalCard(
                            goal: goal,
                            isSelected: goals.contains(goal),
                            action: {
                                if goals.contains(goal) {
                                    goals.remove(goal)
                                } else {
                                    goals.insert(goal)
                                }
                            }
                        )
                    }
                }
                
                if goals.contains(.trainForEvent) {
                    TextField("", text: $customGoal)
                        .placeholder(when: customGoal.isEmpty) {
                            Text("What event? (e.g., Marathon, Triathlon)")
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
        }
    }
    
    var stepThreeContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Schedule
            VStack(alignment: .leading, spacing: 12) {
                Label("When can you workout?", systemImage: "calendar")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                // Days
                Text("Preferred days")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 8) {
                    ForEach(Weekday.allCases, id: \.self) { day in
                        WorkoutDayButton(
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
                        WorkoutTimeSlotButton(
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
            
            // Location preferences
            VStack(alignment: .leading, spacing: 16) {
                Label("Where do you workout?", systemImage: "location")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                // Primary gym
                VStack(alignment: .leading, spacing: 8) {
                    Text("Primary gym/location")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    TextField("", text: $gymName)
                        .placeholder(when: gymName.isEmpty) {
                            Text("e.g., LA Fitness Downtown, Central Park")
                                .foregroundColor(.gray)
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.hopeDarkSecondary)
                        )
                }
                
                // General area
                TextField("", text: $location)
                    .placeholder(when: location.isEmpty) {
                        Text("Neighborhood or zip code")
                            .foregroundColor(.gray)
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.hopeDarkSecondary)
                    )
                
                // Alternative locations
                VStack(spacing: 12) {
                    WorkoutPreferenceToggle(
                        title: "Home workouts",
                        subtitle: "Can meet at home gym",
                        icon: "house",
                        isOn: $canMeetAtHome,
                        color: Color.hopeBlue
                    )
                    
                    WorkoutPreferenceToggle(
                        title: "Outdoor workouts",
                        subtitle: "Parks, trails, etc.",
                        icon: "tree",
                        isOn: $canMeetOutdoors,
                        color: Color.hopeGreen
                    )
                }
                
                // Distance willing to travel
                VStack(alignment: .leading, spacing: 8) {
                    Text("Willing to travel: \(Int(maxDistance)) miles")
                        .font(.subheadline)
                        .foregroundColor(.white)
                    
                    Slider(value: $maxDistance, in: 1...25, step: 1)
                        .accentColor(Color.hopeOrange)
                }
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
            // Workout preferences
            VStack(alignment: .leading, spacing: 16) {
                Label("Workout style", systemImage: "figure.strengthtraining.traditional")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                // Duration
                VStack(alignment: .leading, spacing: 8) {
                    Text("Typical workout duration")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(Duration.allCases, id: \.self) { duration in
                            WorkoutDurationButton(
                                duration: duration,
                                isSelected: workoutDuration == duration,
                                action: { workoutDuration = duration }
                            )
                        }
                    }
                }
                
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
                            WorkoutRadioButton(
                                title: pref.rawValue,
                                isSelected: musicPreference == pref,
                                action: { musicPreference = pref }
                            )
                        }
                    }
                }
                
                // Other preferences
                VStack(spacing: 12) {
                    WorkoutPreferenceToggle(
                        title: "Chat during workout",
                        subtitle: "Enjoy conversation while exercising",
                        icon: "bubble.left.and.bubble.right",
                        isOn: $conversationWhileWorking,
                        color: Color.hopeBlue
                    )
                    
                    WorkoutPreferenceToggle(
                        title: "Can spot/assist",
                        subtitle: "Available to help with lifts",
                        icon: "hands.and.sparkles",
                        isOn: $spotterAvailable,
                        color: Color.hopeOrange
                    )
                    
                    WorkoutPreferenceToggle(
                        title: "Share equipment",
                        subtitle: "Work in between sets",
                        icon: "arrow.left.arrow.right",
                        isOn: $shareEquipment,
                        color: Color.hopeGreen
                    )
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
                        Text("Specific requirements, preferences, or things potential buddies should know...")
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
                                WorkoutDonationOption(
                                    amount: "$1",
                                    isSelected: selectedDonationOption == 0,
                                    action: {
                                        selectedDonationOption = 0
                                        donationAmount = 1.0
                                        customDonationAmount = ""
                                    }
                                )
                                
                                WorkoutDonationOption(
                                    amount: "$5",
                                    isSelected: selectedDonationOption == 1,
                                    action: {
                                        selectedDonationOption = 1
                                        donationAmount = 5.0
                                        customDonationAmount = ""
                                    }
                                )
                                
                                WorkoutDonationOption(
                                    amount: "$10",
                                    isSelected: selectedDonationOption == 2,
                                    action: {
                                        selectedDonationOption = 2
                                        donationAmount = 10.0
                                        customDonationAmount = ""
                                    }
                                )
                                
                                WorkoutDonationOption(
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
                        Image(systemName: "figure.run")
                            .foregroundColor(Color.hopeOrange)
                        Text(headline.isEmpty ? "Looking for workout buddy" : headline)
                            .font(.headline)
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }
                    
                    HStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .foregroundColor(fitnessLevel.color)
                        Text("\(fitnessLevel.rawValue) level")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    
                    if !workoutTypes.isEmpty {
                        HStack {
                            Image(systemName: "dumbbell")
                                .foregroundColor(Color.hopeBlue)
                            Text("\(workoutTypes.count) workout type\(workoutTypes.count == 1 ? "" : "s") selected")
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
                Button(action: postWorkoutBuddy) {
                    HStack {
                        Image(systemName: "figure.run")
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
            return !headline.isEmpty && !bio.isEmpty
        case 2:
            return !workoutTypes.isEmpty && !goals.isEmpty
        case 3:
            return !preferredDays.isEmpty && !preferredTimes.isEmpty && (!gymName.isEmpty || !location.isEmpty)
        case 4:
            return true
        default:
            return true
        }
    }
    
    private func postWorkoutBuddy() {
        // Process donation if applicable
        if donationAmount > 0 {
            // In a real app, this would process the payment through Stripe or similar
            print("Processing donation of $\(donationAmount) to Hyundai Hope on Wheels")
        }
        
        // Create formatted description
        var description = "🏋️ Workout Buddy Request\n\n"
        description += "**About me:** \(bio.isEmpty ? "Not specified" : bio)\n\n"
        
        if !age.isEmpty {
            description += "**Age:** \(age)\n"
        }
        description += "**Gender:** \(gender.rawValue)\n"
        description += "**Looking for:** \(buddyGenderPreference.rawValue) buddy\n\n"
        
        description += "**Workout types:** \(workoutTypes.map { $0.rawValue }.joined(separator: ", "))\n"
        description += "**Fitness level:** \(fitnessLevel.rawValue) (\(fitnessLevel.description))\n"
        if !experience.isEmpty {
            description += "**Experience:** \(experience)\n"
        }
        description += "**Goals:** \(goals.map { $0.rawValue }.joined(separator: ", "))\n"
        if goals.contains(.trainForEvent) && !customGoal.isEmpty {
            description += " - \(customGoal)\n"
        }
        
        description += "\n**Schedule:** \(preferredDays.map { $0.rawValue }.joined(separator: ", "))\n"
        description += "**Times:** \(preferredTimes.map { $0.rawValue }.joined(separator: ", "))\n"
        description += "**Duration:** \(workoutDuration.rawValue)\n\n"
        
        if !gymName.isEmpty {
            description += "**Primary gym:** \(gymName)\n"
        }
        description += "**Location:** \(location.isEmpty ? "Not specified" : location)\n"
        description += "**Willing to travel:** \(Int(maxDistance)) miles\n"
        if canMeetAtHome || canMeetOutdoors {
            description += "**Also available for:** "
            if canMeetAtHome { description += "Home workouts " }
            if canMeetOutdoors { description += "Outdoor workouts" }
            description += "\n"
        }
        
        description += "\n**Preferences:**\n"
        description += "- Music: \(musicPreference.rawValue)\n"
        description += "- Chat during workout: \(conversationWhileWorking ? "Yes" : "No")\n"
        description += "- Can spot/assist: \(spotterAvailable ? "Yes" : "No")\n"
        description += "- Share equipment: \(shareEquipment ? "Yes" : "No")\n"
        
        if !additionalNotes.isEmpty {
            description += "\n**Additional notes:** \(additionalNotes)"
        }
        
        // Create the item
        let newItem = Item(
            title: headline.isEmpty ? "Looking for Workout Buddy" : headline,
            description: description,
            category: .sportingGoods,
            condition: .new,
            userId: UUID(),
            location: location.isEmpty ? "Current Location" : location,
            price: 0,
            priceIsFirm: true,
            images: [],
            listingType: .workoutBuddy
        )
        
        dataManager.addItem(newItem)
        showingSuccessAlert = true
    }
}

// MARK: - Supporting Views

struct WorkoutGenderButton: View {
    let gender: WorkoutBuddyFlow.Gender
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

struct WorkoutDayButton: View {
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

struct WorkoutTypeCard: View {
    let type: WorkoutBuddyFlow.WorkoutType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isSelected ? type.color : type.color.opacity(0.2))
                        .frame(width: 44, height: 44)
                    
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
            .padding(.horizontal, 4)
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

struct FitnessLevelCard: View {
    let level: WorkoutBuddyFlow.FitnessLevel
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Circle()
                    .fill(level.color)
                    .frame(width: 12, height: 12)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(level.rawValue)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(level.description)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(level.color)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? level.color.opacity(0.2) : Color.hopeDarkSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? level.color : Color.clear, lineWidth: 2)
                    )
            )
        }
    }
}

struct GoalCard: View {
    let goal: WorkoutBuddyFlow.Goal
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isSelected ? goal.color : goal.color.opacity(0.2))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: goal.icon)
                        .font(.title3)
                        .foregroundColor(isSelected ? Color.hopeDarkBg : goal.color)
                }
                
                Text(goal.rawValue)
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
                            .stroke(isSelected ? goal.color : Color.clear, lineWidth: 2)
                    )
            )
        }
    }
}

struct WorkoutTimeSlotButton: View {
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

struct WorkoutDurationButton: View {
    let duration: WorkoutBuddyFlow.Duration
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

struct WorkoutPreferenceToggle: View {
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

struct WorkoutRadioButton: View {
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

struct WorkoutDonationOption: View {
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
    WorkoutBuddyFlow(selectedTab: .constant(0))
        .environmentObject(DataManager.shared)
}