import SwiftUI

struct LunchBuddyFlow: View {
    @EnvironmentObject var dataManager: DataManager
    @Binding var selectedTab: Int
    @Environment(\.dismiss) var dismiss
    
    @State private var currentStep = 1
    @State private var showingSuccessAlert = false
    
    // Basic info
    @State private var headline = ""
    @State private var aboutMe = ""
    @State private var occupation = ""
    @State private var company = ""
    @State private var age = ""
    @State private var buddyPreference: BuddyPreference = .anyone
    
    // Food preferences
    @State private var cuisineTypes: Set<CuisineType> = []
    @State private var dietaryRestrictions: Set<DietaryRestriction> = []
    @State private var priceRange: PriceRange = .moderate
    @State private var mealType: Set<MealType> = []
    @State private var favoriteSpots = ""
    @State private var openToNew = true
    
    // Schedule and logistics
    @State private var preferredDays: Set<Weekday> = []
    @State private var lunchDuration: Duration = .oneHour
    @State private var lunchTime: Date = Calendar.current.date(from: DateComponents(hour: 12, minute: 0)) ?? Date()
    @State private var flexibleTime = false
    @State private var location = ""
    @State private var maxDistance = 2.0
    @State private var canDrive = false
    
    // Social preferences
    @State private var conversationTopics: Set<ConversationTopic> = []
    @State private var socialStyle: SocialStyle = .balanced
    @State private var groupSize: GroupSize = .oneOnOne
    @State private var networkingInterest: NetworkingLevel = .casual
    @State private var phoneUsage: PhonePolicy = .emergencyOnly
    @State private var additionalNotes = ""
    
    // Listing fee and donation
    @State private var showListingFee = true
    @State private var donationAmount = 1.0
    @State private var selectedDonationOption = 0
    @State private var customDonationAmount = ""
    
    enum BuddyPreference: String, CaseIterable {
        case anyone = "Anyone"
        case sameCompany = "Same Company"
        case sameIndustry = "Same Industry"
        case different = "Different Field"
    }
    
    enum CuisineType: String, CaseIterable {
        case american = "American"
        case italian = "Italian"
        case mexican = "Mexican"
        case asian = "Asian"
        case mediterranean = "Mediterranean"
        case indian = "Indian"
        case cafes = "Cafes/Delis"
        case healthy = "Healthy/Salads"
        case fastFood = "Fast Food"
        case foodTrucks = "Food Trucks"
        case sushi = "Sushi"
        case anything = "Anything!"
        
        var icon: String {
            switch self {
            case .american: return "flag.fill"
            case .italian: return "fork.knife"
            case .mexican: return "flame"
            case .asian: return "takeoutbag.and.cup.and.straw"
            case .mediterranean: return "leaf"
            case .indian: return "flame.fill"
            case .cafes: return "cup.and.saucer"
            case .healthy: return "carrot"
            case .fastFood: return "clock"
            case .foodTrucks: return "truck.box"
            case .sushi: return "fish"
            case .anything: return "sparkles"
            }
        }
        
        var color: Color {
            switch self {
            case .american: return Color.red
            case .italian: return Color.hopeGreen
            case .mexican: return Color.hopeOrange
            case .asian: return Color.hopePink
            case .mediterranean: return Color.hopeBlue
            case .indian: return Color.yellow
            case .cafes: return Color.brown
            case .healthy: return Color.mint
            case .fastFood: return Color.purple
            case .foodTrucks: return Color.cyan
            case .sushi: return Color.indigo
            case .anything: return Color.hopePurple
            }
        }
    }
    
    enum DietaryRestriction: String, CaseIterable {
        case vegetarian = "Vegetarian"
        case vegan = "Vegan"
        case glutenFree = "Gluten-Free"
        case kosher = "Kosher"
        case halal = "Halal"
        case nutAllergy = "Nut Allergy"
        case lactoseIntolerant = "Lactose Intolerant"
        case lowCarb = "Low Carb/Keto"
        case none = "No Restrictions"
        
        var icon: String {
            switch self {
            case .vegetarian: return "leaf"
            case .vegan: return "leaf.circle"
            case .glutenFree: return "wheat"
            case .kosher: return "star.circle"
            case .halal: return "moon.stars"
            case .nutAllergy: return "exclamationmark.triangle"
            case .lactoseIntolerant: return "drop.triangle"
            case .lowCarb: return "minus.circle"
            case .none: return "checkmark.circle"
            }
        }
        
        var color: Color {
            switch self {
            case .vegetarian: return Color.hopeGreen
            case .vegan: return Color.mint
            case .glutenFree: return Color.hopeOrange
            case .kosher: return Color.hopeBlue
            case .halal: return Color.hopePurple
            case .nutAllergy: return Color.red
            case .lactoseIntolerant: return Color.yellow
            case .lowCarb: return Color.cyan
            case .none: return Color.gray
            }
        }
    }
    
    enum PriceRange: String, CaseIterable {
        case budget = "Budget ($)"
        case moderate = "Moderate ($$)"
        case upscale = "Upscale ($$$)"
        case flexible = "Flexible"
        
        var description: String {
            switch self {
            case .budget: return "Under $10"
            case .moderate: return "$10-20"
            case .upscale: return "$20+"
            case .flexible: return "Any price"
            }
        }
    }
    
    enum MealType: String, CaseIterable {
        case sitDown = "Sit-down Restaurant"
        case quickBite = "Quick Bite"
        case coffee = "Coffee/Tea"
        case picnic = "Outdoor/Picnic"
        case workCafeteria = "Work Cafeteria"
        case delivery = "Order In"
        
        var icon: String {
            switch self {
            case .sitDown: return "fork.knife.circle"
            case .quickBite: return "hare"
            case .coffee: return "cup.and.saucer"
            case .picnic: return "sun.max"
            case .workCafeteria: return "building.2.crop.circle"
            case .delivery: return "takeoutbag.and.cup.and.straw"
            }
        }
        
        var color: Color {
            switch self {
            case .sitDown: return Color.hopePurple
            case .quickBite: return Color.hopeOrange
            case .coffee: return Color.brown
            case .picnic: return Color.hopeGreen
            case .workCafeteria: return Color.hopeBlue
            case .delivery: return Color.red
            }
        }
    }
    
    enum Weekday: String, CaseIterable {
        case monday = "Mon"
        case tuesday = "Tue"
        case wednesday = "Wed"
        case thursday = "Thu"
        case friday = "Fri"
    }
    
    enum Duration: String, CaseIterable {
        case thirtyMin = "30 minutes"
        case fortyFiveMin = "45 minutes"
        case oneHour = "1 hour"
        case ninetyMin = "1.5 hours"
        case flexible = "Flexible"
    }
    
    enum ConversationTopic: String, CaseIterable {
        case work = "Work/Career"
        case hobbies = "Hobbies"
        case family = "Family/Kids"
        case travel = "Travel"
        case sports = "Sports"
        case tech = "Technology"
        case currentEvents = "Current Events"
        case entertainment = "Movies/TV"
        case food = "Food & Dining"
        case books = "Books"
        case wellness = "Health/Wellness"
        case anything = "Anything"
        
        var icon: String {
            switch self {
            case .work: return "briefcase"
            case .hobbies: return "paintbrush"
            case .family: return "figure.2"
            case .travel: return "airplane"
            case .sports: return "sportscourt"
            case .tech: return "desktopcomputer"
            case .currentEvents: return "newspaper"
            case .entertainment: return "tv"
            case .food: return "fork.knife"
            case .books: return "book"
            case .wellness: return "heart"
            case .anything: return "bubble.left.and.bubble.right"
            }
        }
        
        var color: Color {
            switch self {
            case .work: return Color.hopeBlue
            case .hobbies: return Color.hopePink
            case .family: return Color.hopeOrange
            case .travel: return Color.mint
            case .sports: return Color.red
            case .tech: return Color.cyan
            case .currentEvents: return Color.yellow
            case .entertainment: return Color.hopePurple
            case .food: return Color.hopeGreen
            case .books: return Color.indigo
            case .wellness: return Color.pink
            case .anything: return Color.gray
            }
        }
    }
    
    enum SocialStyle: String, CaseIterable {
        case veryTalkative = "Very Talkative"
        case talkative = "Talkative"
        case balanced = "Balanced"
        case quiet = "More Quiet"
        case veryQuiet = "Very Quiet"
        
        var description: String {
            switch self {
            case .veryTalkative: return "Love deep conversations"
            case .talkative: return "Enjoy good chat"
            case .balanced: return "Mix of talk and quiet"
            case .quiet: return "Prefer less talking"
            case .veryQuiet: return "Mostly quiet meals"
            }
        }
    }
    
    enum GroupSize: String, CaseIterable {
        case oneOnOne = "1-on-1"
        case smallGroup = "Small Group (3-4)"
        case largeGroup = "Large Group (5+)"
        case flexible = "Flexible"
        
        var icon: String {
            switch self {
            case .oneOnOne: return "person.2"
            case .smallGroup: return "person.3"
            case .largeGroup: return "person.3.fill"
            case .flexible: return "person.2.wave.2"
            }
        }
        
        var color: Color {
            switch self {
            case .oneOnOne: return Color.hopeBlue
            case .smallGroup: return Color.hopeGreen
            case .largeGroup: return Color.hopeOrange
            case .flexible: return Color.hopePurple
            }
        }
    }
    
    enum NetworkingLevel: String, CaseIterable {
        case professional = "Professional Networking"
        case casual = "Casual Connection"
        case friendship = "Building Friendship"
        case justLunch = "Just Lunch"
    }
    
    enum PhonePolicy: String, CaseIterable {
        case noPhones = "No Phones"
        case emergencyOnly = "Emergency Only"
        case occasional = "Occasional OK"
        case flexible = "Flexible"
        
        var icon: String {
            switch self {
            case .noPhones: return "iphone.slash"
            case .emergencyOnly: return "exclamationmark.triangle"
            case .occasional: return "iphone"
            case .flexible: return "checkmark.circle"
            }
        }
        
        var color: Color {
            switch self {
            case .noPhones: return Color.red
            case .emergencyOnly: return Color.hopeOrange
            case .occasional: return Color.hopeBlue
            case .flexible: return Color.hopeGreen
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
        .alert("Lunch Buddy Request Posted!", isPresented: $showingSuccessAlert) {
            Button("OK") {
                dismiss()
                selectedTab = 0
            }
        } message: {
            Text("Your lunch buddy request has been posted! You'll be notified when someone wants to grab lunch.")
        }
    }
    
    var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Lunch Buddy")
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
            // Introduction
            VStack(alignment: .leading, spacing: 12) {
                Label("Tell us about yourself", systemImage: "person.fill")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                TextField("", text: $headline)
                    .placeholder(when: headline.isEmpty) {
                        Text("Headline (e.g., \"Tech worker looking for lunch buddies downtown\")")
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
                        Text("Tell potential lunch buddies about yourself, your interests, what you're looking for...")
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
            
            // Work info
            VStack(alignment: .leading, spacing: 16) {
                Label("Work information", systemImage: "briefcase")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                TextField("", text: $occupation)
                    .placeholder(when: occupation.isEmpty) {
                        Text("Your occupation (optional)")
                            .foregroundColor(.gray)
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.hopeDarkSecondary)
                    )
                
                TextField("", text: $company)
                    .placeholder(when: company.isEmpty) {
                        Text("Company/Organization (optional)")
                            .foregroundColor(.gray)
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.hopeDarkSecondary)
                    )
                
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
            }
            
            // Buddy preference
            VStack(alignment: .leading, spacing: 12) {
                Label("Who would you like to meet?", systemImage: "person.2")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(BuddyPreference.allCases, id: \.self) { pref in
                        LunchBuddyPreferenceButton(
                            preference: pref,
                            isSelected: buddyPreference == pref,
                            action: { buddyPreference = pref }
                        )
                    }
                }
            }
        }
    }
    
    var stepTwoContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Cuisine preferences
            VStack(alignment: .leading, spacing: 12) {
                Label("What do you like to eat?", systemImage: "fork.knife")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text("Select all that apply")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(CuisineType.allCases, id: \.self) { cuisine in
                        CuisineCard(
                            cuisine: cuisine,
                            isSelected: cuisineTypes.contains(cuisine),
                            action: {
                                if cuisineTypes.contains(cuisine) {
                                    cuisineTypes.remove(cuisine)
                                } else {
                                    cuisineTypes.insert(cuisine)
                                }
                            }
                        )
                    }
                }
            }
            
            // Dietary restrictions
            VStack(alignment: .leading, spacing: 12) {
                Label("Dietary restrictions", systemImage: "leaf")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text("Select all that apply")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(DietaryRestriction.allCases, id: \.self) { restriction in
                        DietaryButton(
                            restriction: restriction,
                            isSelected: dietaryRestrictions.contains(restriction),
                            action: {
                                if restriction == .none {
                                    dietaryRestrictions.removeAll()
                                    dietaryRestrictions.insert(.none)
                                } else {
                                    dietaryRestrictions.remove(.none)
                                    if dietaryRestrictions.contains(restriction) {
                                        dietaryRestrictions.remove(restriction)
                                    } else {
                                        dietaryRestrictions.insert(restriction)
                                    }
                                }
                            }
                        )
                    }
                }
            }
            
            // Price range
            VStack(alignment: .leading, spacing: 12) {
                Label("Price preference", systemImage: "dollarsign.circle")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                VStack(spacing: 8) {
                    ForEach(PriceRange.allCases, id: \.self) { range in
                        PriceRangeCard(
                            range: range,
                            isSelected: priceRange == range,
                            action: { priceRange = range }
                        )
                    }
                }
            }
            
            // Meal type
            VStack(alignment: .leading, spacing: 12) {
                Label("Meal style", systemImage: "building.2")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text("Select all that apply")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(MealType.allCases, id: \.self) { type in
                        MealTypeButton(
                            type: type,
                            isSelected: mealType.contains(type),
                            action: {
                                if mealType.contains(type) {
                                    mealType.remove(type)
                                } else {
                                    mealType.insert(type)
                                }
                            }
                        )
                    }
                }
            }
            
            // Favorite spots and preferences
            VStack(alignment: .leading, spacing: 12) {
                Label("Favorite lunch spots", systemImage: "star")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                TextEditor(text: $favoriteSpots)
                    .placeholder(when: favoriteSpots.isEmpty) {
                        Text("Share some of your go-to lunch places...")
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
                
                LunchPreferenceToggle(
                    title: "Open to new places",
                    subtitle: "Love trying new restaurants",
                    icon: "sparkles",
                    isOn: $openToNew,
                    color: Color.hopePurple
                )
            }
        }
    }
    
    var stepThreeContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Schedule
            VStack(alignment: .leading, spacing: 12) {
                Label("When can you do lunch?", systemImage: "calendar")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                // Days
                Text("Available days")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                HStack(spacing: 8) {
                    ForEach(Weekday.allCases, id: \.self) { day in
                        WeekdayButton(
                            day: day,
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
                
                // Time
                VStack(alignment: .leading, spacing: 8) {
                    Text("Usual lunch time")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    DatePicker(
                        "",
                        selection: $lunchTime,
                        displayedComponents: .hourAndMinute
                    )
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .frame(height: 120)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.hopeDarkSecondary)
                    )
                    .colorScheme(.dark)
                    
                    LunchPreferenceToggle(
                        title: "Flexible timing",
                        subtitle: "Can adjust by 30 min",
                        icon: "clock",
                        isOn: $flexibleTime,
                        color: Color.hopeOrange
                    )
                }
                
                // Duration
                VStack(alignment: .leading, spacing: 8) {
                    Text("How long for lunch?")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(Duration.allCases, id: \.self) { duration in
                            LunchDurationButton(
                                duration: duration,
                                isSelected: lunchDuration == duration,
                                action: { lunchDuration = duration }
                            )
                        }
                    }
                }
            }
            
            // Location
            VStack(alignment: .leading, spacing: 16) {
                Label("Location preferences", systemImage: "location")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                TextField("", text: $location)
                    .placeholder(when: location.isEmpty) {
                        Text("Your area/neighborhood")
                            .foregroundColor(.gray)
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.hopeDarkSecondary)
                    )
                
                // Distance willing to travel
                VStack(alignment: .leading, spacing: 8) {
                    Text("Willing to travel: \(maxDistance, specifier: "%.1f") miles")
                        .font(.subheadline)
                        .foregroundColor(.white)
                    
                    Slider(value: $maxDistance, in: 0.5...5, step: 0.5)
                        .accentColor(Color.hopeOrange)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.hopeDarkSecondary)
                )
                
                LunchPreferenceToggle(
                    title: "Can drive",
                    subtitle: "Have a car for lunch trips",
                    icon: "car",
                    isOn: $canDrive,
                    color: Color.hopeBlue
                )
            }
        }
    }
    
    var stepFourContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Conversation topics
            VStack(alignment: .leading, spacing: 12) {
                Label("Conversation interests", systemImage: "bubble.left.and.bubble.right")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text("What do you like to talk about?")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(ConversationTopic.allCases, id: \.self) { topic in
                        ConversationTopicCard(
                            topic: topic,
                            isSelected: conversationTopics.contains(topic),
                            action: {
                                if conversationTopics.contains(topic) {
                                    conversationTopics.remove(topic)
                                } else {
                                    conversationTopics.insert(topic)
                                }
                            }
                        )
                    }
                }
            }
            
            // Social style
            VStack(alignment: .leading, spacing: 12) {
                Label("Your social style", systemImage: "person.wave.2")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                VStack(spacing: 8) {
                    ForEach(SocialStyle.allCases, id: \.self) { style in
                        SocialStyleCard(
                            style: style,
                            isSelected: socialStyle == style,
                            action: { socialStyle = style }
                        )
                    }
                }
            }
            
            // Group preferences
            VStack(alignment: .leading, spacing: 12) {
                Label("Lunch preferences", systemImage: "person.3")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                // Group size
                VStack(alignment: .leading, spacing: 8) {
                    Text("Preferred group size")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(GroupSize.allCases, id: \.self) { size in
                            GroupSizeCard(
                                size: size,
                                isSelected: groupSize == size,
                                action: { groupSize = size }
                            )
                        }
                    }
                }
                
                // Networking level
                VStack(alignment: .leading, spacing: 8) {
                    Text("Meeting purpose")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    VStack(spacing: 8) {
                        ForEach(NetworkingLevel.allCases, id: \.self) { level in
                            NetworkingCard(
                                level: level,
                                isSelected: networkingInterest == level,
                                action: { networkingInterest = level }
                            )
                        }
                    }
                }
                
                // Phone policy
                VStack(alignment: .leading, spacing: 8) {
                    Text("Phone usage during lunch")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(PhonePolicy.allCases, id: \.self) { policy in
                            PhonePolicyCard(
                                policy: policy,
                                isSelected: phoneUsage == policy,
                                action: { phoneUsage = policy }
                            )
                        }
                    }
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
                                LunchDonationOption(
                                    amount: "$1",
                                    isSelected: selectedDonationOption == 0,
                                    action: {
                                        selectedDonationOption = 0
                                        donationAmount = 1.0
                                        customDonationAmount = ""
                                    }
                                )
                                
                                LunchDonationOption(
                                    amount: "$5",
                                    isSelected: selectedDonationOption == 1,
                                    action: {
                                        selectedDonationOption = 1
                                        donationAmount = 5.0
                                        customDonationAmount = ""
                                    }
                                )
                                
                                LunchDonationOption(
                                    amount: "$10",
                                    isSelected: selectedDonationOption == 2,
                                    action: {
                                        selectedDonationOption = 2
                                        donationAmount = 10.0
                                        customDonationAmount = ""
                                    }
                                )
                                
                                LunchDonationOption(
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
            
            // Additional notes
            VStack(alignment: .leading, spacing: 12) {
                Label("Anything else?", systemImage: "text.bubble")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                TextEditor(text: $additionalNotes)
                    .placeholder(when: additionalNotes.isEmpty) {
                        Text("Other preferences, specific days you're free, topics to avoid...")
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
            
            // Summary
            VStack(alignment: .leading, spacing: 16) {
                Label("Ready to find lunch buddies!", systemImage: "checkmark.circle.fill")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.hopeGreen)
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "fork.knife")
                            .foregroundColor(Color.hopeOrange)
                        Text(headline.isEmpty ? "Looking for lunch buddy" : headline)
                            .font(.headline)
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }
                    
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(Color.hopeBlue)
                        Text("\(preferredDays.count) days available")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        Image(systemName: "person.2")
                            .foregroundColor(Color.hopePurple)
                        Text(groupSize.rawValue)
                            .font(.subheadline)
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
                        (showListingFee ? "Post Buddy ($1 fee)" : 
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
            return !cuisineTypes.isEmpty && !mealType.isEmpty
        case 3:
            return !preferredDays.isEmpty && !location.isEmpty
        case 4:
            return !conversationTopics.isEmpty
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
            postLunchBuddy()
        }
    }
    
    func previousStep() {
        if currentStep > 1 {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep -= 1
            }
        }
    }
    
    private func postLunchBuddy() {
        // Process donation if applicable
        if donationAmount > 0 {
            // In a real app, this would process the payment through Stripe or similar
            print("Processing donation of $\(donationAmount) to Hyundai Hope on Wheels")
        }
        
        // Create formatted description
        var description = "🍴 Lunch Buddy Request\n\n"
        description += "**About me:** \(aboutMe.isEmpty ? "Not specified" : aboutMe)\n\n"
        
        if !occupation.isEmpty {
            description += "**Occupation:** \(occupation)\n"
        }
        if !company.isEmpty {
            description += "**Company:** \(company)\n"
        }
        if !age.isEmpty {
            description += "**Age:** \(age)\n"
        }
        description += "**Looking for:** \(buddyPreference.rawValue)\n\n"
        
        description += "**Cuisine preferences:** \(cuisineTypes.map { $0.rawValue }.joined(separator: ", "))\n"
        if !dietaryRestrictions.isEmpty {
            description += "**Dietary restrictions:** \(dietaryRestrictions.map { $0.rawValue }.joined(separator: ", "))\n"
        }
        description += "**Price range:** \(priceRange.rawValue)\n"
        description += "**Meal types:** \(mealType.map { $0.rawValue }.joined(separator: ", "))\n"
        if !favoriteSpots.isEmpty {
            description += "**Favorite spots:** \(favoriteSpots)\n"
        }
        description += "**Open to new places:** \(openToNew ? "Yes" : "No")\n\n"
        
        description += "**Schedule:** \(preferredDays.map { $0.rawValue }.joined(separator: ", "))\n"
        description += "**Lunch time:** \(formatTime(lunchTime))\(flexibleTime ? " (flexible)" : "")\n"
        description += "**Duration:** \(lunchDuration.rawValue)\n\n"
        
        description += "**Location:** \(location.isEmpty ? "Not specified" : location)\n"
        description += "**Willing to travel:** \(Int(maxDistance)) miles\n"
        description += "**Can drive:** \(canDrive ? "Yes" : "No")\n\n"
        
        if !conversationTopics.isEmpty {
            description += "**Conversation topics:** \(conversationTopics.map { $0.rawValue }.joined(separator: ", "))\n"
        }
        description += "**Social style:** \(socialStyle.rawValue)\n"
        description += "**Group size:** \(groupSize.rawValue)\n"
        description += "**Networking interest:** \(networkingInterest.rawValue)\n"
        description += "**Phone usage:** \(phoneUsage.rawValue)\n"
        
        if !additionalNotes.isEmpty {
            description += "\n**Additional notes:** \(additionalNotes)"
        }
        
        // Create the item
        let newItem = Item(
            title: headline.isEmpty ? "Looking for Lunch Buddy" : headline,
            description: description,
            category: .miscellaneous,
            condition: .likeNew,
            userId: UUID(),
            location: location.isEmpty ? "Current Location" : location,
            price: 0,
            priceIsFirm: true,
            images: [],
            listingType: .lunchBuddy
        )
        
        dataManager.addItem(newItem)
        showingSuccessAlert = true
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Views

struct LunchBuddyPreferenceButton: View {
    let preference: LunchBuddyFlow.BuddyPreference
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(preference.rawValue)
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
                        .fill(isSelected ? Color.hopeOrange : Color.hopeDarkSecondary)
                )
        }
    }
}

struct CuisineCard: View {
    let cuisine: LunchBuddyFlow.CuisineType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isSelected ? cuisine.color : cuisine.color.opacity(0.2))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: cuisine.icon)
                        .font(.title3)
                        .foregroundColor(isSelected ? Color.hopeDarkBg : cuisine.color)
                }
                
                Text(cuisine.rawValue)
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
                            .stroke(isSelected ? cuisine.color : Color.clear, lineWidth: 2)
                    )
            )
        }
    }
}

struct DietaryButton: View {
    let restriction: LunchBuddyFlow.DietaryRestriction
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isSelected ? restriction.color : restriction.color.opacity(0.2))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: restriction.icon)
                        .font(.title3)
                        .foregroundColor(isSelected ? Color.hopeDarkBg : restriction.color)
                }
                
                Text(restriction.rawValue)
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
                            .stroke(isSelected ? restriction.color : Color.clear, lineWidth: 2)
                    )
            )
        }
    }
}

struct PriceRangeCard: View {
    let range: LunchBuddyFlow.PriceRange
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(range.rawValue)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(range.description)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color.hopeGreen)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.hopeGreen.opacity(0.2) : Color.hopeDarkSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.hopeGreen : Color.clear, lineWidth: 2)
                    )
            )
        }
    }
}

struct MealTypeButton: View {
    let type: LunchBuddyFlow.MealType
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

struct WeekdayButton: View {
    let day: LunchBuddyFlow.Weekday
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(day.rawValue)
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

struct TopicButton: View {
    let topic: LunchBuddyFlow.ConversationTopic
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: topic.icon)
                    .font(.caption)
                    .foregroundColor(isSelected ? Color.hopeDarkBg : .white)
                
                Text(topic.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? Color.hopeDarkBg : .white)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.hopePurple : Color.hopeDarkSecondary)
            )
        }
    }
}

struct ConversationTopicCard: View {
    let topic: LunchBuddyFlow.ConversationTopic
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isSelected ? topic.color : topic.color.opacity(0.2))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: topic.icon)
                        .font(.title3)
                        .foregroundColor(isSelected ? Color.hopeDarkBg : topic.color)
                }
                
                Text(topic.rawValue)
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
                            .stroke(isSelected ? topic.color : Color.clear, lineWidth: 2)
                    )
            )
        }
    }
}

struct SocialStyleCard: View {
    let style: LunchBuddyFlow.SocialStyle
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(style.rawValue)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(style.description)
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
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.hopeBlue.opacity(0.2) : Color.hopeDarkSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.hopeBlue : Color.clear, lineWidth: 2)
                    )
            )
        }
    }
}

struct NetworkingCard: View {
    let level: LunchBuddyFlow.NetworkingLevel
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(level.rawValue)
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
                    .fill(isSelected ? Color.hopePink : Color.hopeDarkSecondary)
            )
        }
    }
}

struct PhonePolicyButton: View {
    let policy: LunchBuddyFlow.PhonePolicy
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(policy.rawValue)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? Color.hopeDarkBg : .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? Color.yellow : Color.hopeDarkSecondary)
                )
        }
    }
}

struct GroupSizeCard: View {
    let size: LunchBuddyFlow.GroupSize
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isSelected ? size.color : size.color.opacity(0.2))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: size.icon)
                        .font(.title3)
                        .foregroundColor(isSelected ? Color.hopeDarkBg : size.color)
                }
                
                Text(size.rawValue)
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
                            .stroke(isSelected ? size.color : Color.clear, lineWidth: 2)
                    )
            )
        }
    }
}

struct PhonePolicyCard: View {
    let policy: LunchBuddyFlow.PhonePolicy
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isSelected ? policy.color : policy.color.opacity(0.2))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: policy.icon)
                        .font(.title3)
                        .foregroundColor(isSelected ? Color.hopeDarkBg : policy.color)
                }
                
                Text(policy.rawValue)
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
                            .stroke(isSelected ? policy.color : Color.clear, lineWidth: 2)
                    )
            )
        }
    }
}

struct LunchDurationButton: View {
    let duration: LunchBuddyFlow.Duration
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

struct LunchPreferenceToggle: View {
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

struct LunchDonationOption: View {
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
    LunchBuddyFlow(selectedTab: .constant(0))
        .environmentObject(DataManager.shared)
}