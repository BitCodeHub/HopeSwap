//
//  DonationView.swift
//  HopeSwap
//
//  Created by Assistant on 8/18/25.
//

import SwiftUI
import WebKit

struct DonationView: View {
    @State private var selectedAmount = 2 // Index of selected amount
    @State private var customAmount = ""
    @State private var isCustomAmount = false
    @State private var showingPaymentMethod = false
    @State private var isMonthlyDonation = false
    @State private var showingThankYou = false
    @State private var showingTaxInfo = false
    @State private var currentTestimonialIndex = 0
    @FocusState private var isCustomAmountFocused: Bool
    
    let donationAmounts = [10, 25, 50, 100, 250, 500]
    let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
    
    let testimonials = [
        ("Sarah M.", "My daughter is a cancer survivor thanks to research funded by donations like these. Every dollar truly makes a difference."),
        ("John D.", "Knowing that 100% of listing fees go to pediatric cancer research makes every purchase meaningful."),
        ("Maria L.", "Small donations add up. Together, we're funding life-saving treatments for children.")
    ]
    
    var selectedDonationAmount: Double {
        if isCustomAmount {
            return Double(customAmount) ?? 0
        } else {
            return Double(donationAmounts[selectedAmount])
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.hopeDarkBg
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Hero Section
                        heroSection
                        
                        // Impact Statistics
                        impactSection
                            .padding(.top, -20)
                        
                        // Donation Amount Selection
                        donationAmountSection
                        
                        // Monthly Donation Toggle
                        monthlyDonationSection
                        
                        // Tax Deductible Info
                        taxInfoSection
                        
                        // Testimonials
                        testimonialSection
                        
                        // Progress Tracker
                        progressSection
                        
                        // Donate Button
                        donateButton
                        
                        // Trust Indicators
                        trustSection
                        
                        // FAQ Link
                        faqSection
                    }
                    .padding(.bottom, 100)
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingPaymentMethod) {
            PaymentMethodView(
                amount: selectedDonationAmount,
                isMonthly: isMonthlyDonation,
                onSuccess: {
                    showingPaymentMethod = false
                    showingThankYou = true
                }
            )
        }
        .sheet(isPresented: $showingThankYou) {
            ThankYouView(amount: selectedDonationAmount, isMonthly: isMonthlyDonation)
        }
        .sheet(isPresented: $showingTaxInfo) {
            TaxInfoView()
        }
    }
    
    var heroSection: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.91, green: 0.29, blue: 0.39),
                    Color(red: 0.91, green: 0.29, blue: 0.39).opacity(0.8)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 300)
            
            VStack(spacing: 20) {
                // Logo/Heart Icon
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "heart.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.white)
                }
                
                Text("Make a Difference")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("100% of your donation funds pediatric cancer research through Hyundai Hope on Wheels")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                Link(destination: URL(string: "https://hyundaihopeonwheels.org/our-story/")!) {
                    HStack(spacing: 4) {
                        Text("Learn about our mission")
                            .font(.caption)
                            .foregroundColor(.white)
                            .underline()
                        
                        Image(systemName: "arrow.up.right.square")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(.top, 50)
        }
    }
    
    var impactSection: some View {
        VStack(spacing: 16) {
            // Impact Cards
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ImpactCard(
                        number: "$200M+",
                        title: "Total Funded",
                        subtitle: "Since 1998",
                        icon: "dollarsign.circle.fill",
                        color: Color.hopeGreen
                    )
                    
                    ImpactCard(
                        number: "1,000+",
                        title: "Researchers",
                        subtitle: "Supported",
                        icon: "person.3.fill",
                        color: Color.hopeBlue
                    )
                    
                    ImpactCard(
                        number: "168",
                        title: "Hospitals",
                        subtitle: "Nationwide",
                        icon: "building.2.fill",
                        color: Color.hopePurple
                    )
                    
                    ImpactCard(
                        number: "15,000+",
                        title: "Children",
                        subtitle: "Helped yearly",
                        icon: "figure.2.and.child.holdinghands",
                        color: Color.hopePink
                    )
                }
                .padding(.horizontal)
            }
            
            // Live counter
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(Color.hopePink)
                    .font(.caption)
                
                Text("$3,247 raised today from 42 donors")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical)
    }
    
    var donationAmountSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Choose your donation amount")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal)
            
            // Preset amounts
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(0..<donationAmounts.count, id: \.self) { index in
                    DonationAmountButton(
                        amount: donationAmounts[index],
                        isSelected: !isCustomAmount && selectedAmount == index,
                        action: {
                            selectedAmount = index
                            isCustomAmount = false
                            isCustomAmountFocused = false
                        }
                    )
                }
            }
            .padding(.horizontal)
            
            // Custom amount
            HStack {
                Text("$")
                    .font(.title2)
                    .foregroundColor(.white)
                
                TextField("Enter amount", text: $customAmount)
                    .keyboardType(.decimalPad)
                    .foregroundColor(.white)
                    .font(.title2)
                    .focused($isCustomAmountFocused)
                    .onChange(of: customAmount) {
                        if !customAmount.isEmpty {
                            isCustomAmount = true
                        }
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isCustomAmount ? Color.hopeOrange.opacity(0.2) : Color.white.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(isCustomAmount ? Color.hopeOrange : Color.clear, lineWidth: 2)
                            )
                    )
            }
            .padding(.horizontal)
            
            // Donor levels
            if selectedDonationAmount >= 100 {
                DonorLevelIndicator(amount: selectedDonationAmount)
                    .padding(.horizontal)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.vertical)
    }
    
    var monthlyDonationSection: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Make it monthly")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(isMonthlyDonation ? 
                         "Your $\(Int(selectedDonationAmount))/month will provide ongoing support" :
                         "Multiply your impact with a recurring donation")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Toggle("", isOn: $isMonthlyDonation)
                    .toggleStyle(SwitchToggleStyle(tint: Color.hopeGreen))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
            )
            
            if isMonthlyDonation {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(Color.hopeGreen)
                    
                    Text("Cancel anytime • Get monthly impact reports")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.horizontal)
        .animation(.easeInOut, value: isMonthlyDonation)
    }
    
    var taxInfoSection: some View {
        Button(action: { showingTaxInfo = true }) {
            HStack {
                Image(systemName: "doc.text.fill")
                    .foregroundColor(Color.hopeBlue)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Tax Deductible")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    Text("EIN: 52-2106545 • 501(c)(3) nonprofit")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
            )
        }
        .padding(.horizontal)
    }
    
    var testimonialSection: some View {
        VStack(spacing: 16) {
            Text("Stories of Hope")
                .font(.headline)
                .foregroundColor(.white)
            
            TabView(selection: $currentTestimonialIndex) {
                ForEach(0..<testimonials.count, id: \.self) { index in
                    TestimonialCard(
                        name: testimonials[index].0,
                        quote: testimonials[index].1
                    )
                    .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle())
            .frame(height: 150)
            .onReceive(timer) { _ in
                withAnimation {
                    currentTestimonialIndex = (currentTestimonialIndex + 1) % testimonials.count
                }
            }
        }
        .padding(.vertical)
    }
    
    var progressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Monthly Goal Progress")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("$147,231 / $250,000")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.hopeOrange, Color.hopePink]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * 0.589, height: 8)
                }
            }
            .frame(height: 8)
            
            Text("59% of monthly goal • 18 days left")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
        .padding(.horizontal)
    }
    
    var donateButton: some View {
        Button(action: {
            if selectedDonationAmount > 0 {
                showingPaymentMethod = true
            }
        }) {
            HStack {
                Image(systemName: "heart.fill")
                    .font(.headline)
                
                Text(isMonthlyDonation ? 
                     "Donate $\(Int(selectedDonationAmount))/month" :
                     "Donate $\(Int(selectedDonationAmount))")
                    .font(.headline)
                    .fontWeight(.bold)
            }
            .foregroundColor(Color.hopeDarkBg)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: selectedDonationAmount > 0 ? 
                                [Color.hopeOrange, Color.hopePink] : 
                                [Color.gray.opacity(0.3), Color.gray.opacity(0.3)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .shadow(color: Color.hopeOrange.opacity(0.3), radius: 8, y: 4)
        }
        .disabled(selectedDonationAmount == 0)
        .padding(.horizontal)
        .padding(.vertical)
    }
    
    var trustSection: some View {
        VStack(spacing: 16) {
            // Security badges
            HStack(spacing: 20) {
                TrustBadge(icon: "lock.shield.fill", text: "Secure")
                TrustBadge(icon: "checkmark.shield.fill", text: "Verified")
                TrustBadge(icon: "star.fill", text: "4-Star")
                TrustBadge(icon: "building.columns.fill", text: "501(c)(3)")
            }
            
            // Payment methods
            Text("Accepted payment methods")
                .font(.caption)
                .foregroundColor(.gray)
            
            HStack(spacing: 16) {
                PaymentMethodIcon(name: "creditcard.fill")
                PaymentMethodIcon(name: "applelogo")
                PaymentMethodIcon(name: "g.circle.fill")
                PaymentMethodIcon(name: "p.circle.fill")
            }
        }
        .padding()
    }
    
    var faqSection: some View {
        VStack(spacing: 12) {
            Link(destination: URL(string: "https://hyundaihopeonwheels.org/")!) {
                HStack {
                    Text("Visit Hyundai Hope on Wheels")
                        .font(.subheadline)
                        .foregroundColor(Color.hopeBlue)
                    
                    Image(systemName: "arrow.up.right.square")
                        .font(.subheadline)
                        .foregroundColor(Color.hopeBlue)
                }
            }
            
            Text("Questions? Contact donate@hopeswap.com")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.bottom, 20)
    }
}

// MARK: - Supporting Views

struct ImpactCard: View {
    let number: String
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(number)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
            
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .frame(width: 120, height: 140)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct DonationAmountButton: View {
    let amount: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text("$\(amount)")
                    .font(.title3)
                    .fontWeight(.bold)
                
                if amount == 50 {
                    Text("Most popular")
                        .font(.caption2)
                        .foregroundColor(isSelected ? Color.hopeDarkBg : Color.hopeOrange)
                }
            }
            .foregroundColor(isSelected ? Color.hopeDarkBg : .white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.hopeOrange : Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.clear : Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
        }
    }
}

struct DonorLevelIndicator: View {
    let amount: Double
    
    var donorLevel: (name: String, color: Color, icon: String) {
        switch amount {
        case 100..<250:
            return ("Hope Supporter", Color.hopeGreen, "star.fill")
        case 250..<500:
            return ("Hope Champion", Color.hopeBlue, "star.circle.fill")
        case 500..<1000:
            return ("Hope Leader", Color.hopePurple, "star.square.fill")
        default:
            return ("Hope Visionary", Color.hopePink, "star.bubble.fill")
        }
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: donorLevel.icon)
                .foregroundColor(donorLevel.color)
            
            Text("You'll become a \(donorLevel.name)")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(donorLevel.color.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(donorLevel.color, lineWidth: 1)
                )
        )
    }
}

struct TestimonialCard: View {
    let name: String
    let quote: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\"\(quote)\"")
                .font(.subheadline)
                .foregroundColor(.white)
                .italic()
                .multilineTextAlignment(.leading)
            
            Text("— \(name)")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
        .padding(.horizontal)
    }
}

struct TrustBadge: View {
    let icon: String
    let text: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.gray)
            
            Text(text)
                .font(.caption2)
                .foregroundColor(.gray)
        }
    }
}

struct PaymentMethodIcon: View {
    let name: String
    
    var body: some View {
        Image(systemName: name)
            .font(.title2)
            .foregroundColor(.gray)
            .frame(width: 40, height: 30)
    }
}

// MARK: - Payment Method View

struct PaymentMethodView: View {
    let amount: Double
    let isMonthly: Bool
    let onSuccess: () -> Void
    @Environment(\.dismiss) var dismiss
    @State private var selectedPaymentMethod = 0
    
    let paymentMethods = [
        ("Credit/Debit Card", "creditcard.fill"),
        ("Apple Pay", "applelogo"),
        ("Google Pay", "g.circle.fill"),
        ("PayPal", "p.circle.fill")
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.hopeDarkBg
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Amount summary
                    VStack(spacing: 8) {
                        Text(isMonthly ? "Monthly Donation" : "One-time Donation")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        Text("$\(Int(amount))\(isMonthly ? "/month" : "")")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    .padding(.top)
                    
                    // Payment methods
                    VStack(spacing: 12) {
                        ForEach(0..<paymentMethods.count, id: \.self) { index in
                            PaymentMethodRow(
                                method: paymentMethods[index].0,
                                icon: paymentMethods[index].1,
                                isSelected: selectedPaymentMethod == index,
                                action: { selectedPaymentMethod = index }
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Continue button
                    Button(action: {
                        // In a real app, process payment here
                        onSuccess()
                    }) {
                        Text("Continue to \(paymentMethods[selectedPaymentMethod].0)")
                            .font(.headline)
                            .foregroundColor(Color.hopeDarkBg)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.hopeOrange)
                            )
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("Payment Method")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Color.hopeOrange)
                }
            }
        }
    }
}

struct PaymentMethodRow: View {
    let method: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? Color.hopeOrange : .gray)
                    .frame(width: 40)
                
                Text(method)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? Color.hopeOrange : .gray)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.hopeOrange : Color.clear, lineWidth: 2)
                    )
            )
        }
    }
}

// MARK: - Thank You View

struct ThankYouView: View {
    let amount: Double
    let isMonthly: Bool
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                // Confetti background
                Color.hopeDarkBg
                    .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    Spacer()
                    
                    // Success animation
                    ZStack {
                        Circle()
                            .fill(Color.hopeGreen.opacity(0.2))
                            .frame(width: 120, height: 120)
                        
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(Color.hopeGreen)
                    }
                    
                    VStack(spacing: 16) {
                        Text("Thank You!")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Your \(isMonthly ? "monthly" : "") donation of $\(Int(amount)) is making a real difference")
                            .font(.headline)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    
                    // Impact message
                    VStack(spacing: 12) {
                        Image(systemName: "envelope.fill")
                            .font(.title2)
                            .foregroundColor(Color.hopeBlue)
                        
                        Text("Check your email for your tax receipt")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.05))
                    )
                    .padding(.horizontal, 40)
                    
                    Spacer()
                    
                    // Share buttons
                    VStack(spacing: 16) {
                        Text("Spread the word")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        HStack(spacing: 20) {
                            ShareButton(icon: "message.fill", color: Color.hopeGreen)
                            ShareButton(icon: "envelope.fill", color: Color.hopeBlue)
                            ShareButton(icon: "link", color: Color.hopePurple)
                        }
                    }
                    
                    // Done button
                    Button(action: { dismiss() }) {
                        Text("Done")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.hopeOrange)
                            )
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
            }
            .navigationBarHidden(true)
        }
    }
}

struct ShareButton: View {
    let icon: String
    let color: Color
    
    var body: some View {
        Button(action: {}) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(
                    Circle()
                        .fill(color)
                )
        }
    }
}

// MARK: - Tax Info View

struct TaxInfoView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.hopeDarkBg
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Tax Deductible Information")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Your donation is tax-deductible to the fullest extent allowed by law")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        
                        // Tax info cards
                        TaxInfoCard(
                            title: "501(c)(3) Status",
                            content: "Hyundai Hope on Wheels is a registered 501(c)(3) nonprofit organization. All donations are tax-deductible.",
                            icon: "building.columns.fill"
                        )
                        
                        TaxInfoCard(
                            title: "EIN Number",
                            content: "52-2106545\nUse this number when filing your taxes.",
                            icon: "number.circle.fill"
                        )
                        
                        TaxInfoCard(
                            title: "Tax Receipt",
                            content: "You'll receive an email receipt immediately after your donation. Save this for your tax records.",
                            icon: "doc.text.fill"
                        )
                        
                        TaxInfoCard(
                            title: "Annual Statement",
                            content: "For donations over $250, you'll receive an annual contribution statement in January.",
                            icon: "calendar.circle.fill"
                        )
                        
                        // Disclaimer
                        Text("Please consult with your tax advisor for specific questions about your tax situation.")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.top)
                    }
                    .padding()
                }
            }
            .navigationTitle("Tax Information")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Color.hopeOrange)
                }
            }
        }
    }
}

struct TaxInfoCard: View {
    let title: String
    let content: String
    let icon: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(Color.hopeBlue)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(content)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }
}

#Preview {
    DonationView()
}