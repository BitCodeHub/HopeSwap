import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var showingDonationHistory = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 15) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 100))
                            .foregroundColor(.pink)
                        
                        Text(dataManager.currentUser.username)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text(dataManager.currentUser.email)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.top)
                    
                    VStack(spacing: 15) {
                        HStack {
                            StatCard(title: "Total Donated", value: "$\(Int(dataManager.currentUser.totalDonated))", icon: "heart.fill", color: .pink)
                            StatCard(title: "Items Listed", value: "\(dataManager.currentUser.itemsListed)", icon: "tag.fill", color: .blue)
                        }
                        
                        HStack {
                            StatCard(title: "Trades Done", value: "\(dataManager.currentUser.tradesCompleted)", icon: "arrow.triangle.2.circlepath", color: .green)
                            StatCard(title: "Member Since", value: dateFormatter.string(from: dataManager.currentUser.joinedDate), icon: "calendar", color: .orange)
                        }
                    }
                    .padding(.horizontal)
                    
                    VStack(spacing: 0) {
                        MenuRow(title: "My Listings", icon: "square.grid.2x2", action: {})
                        MenuRow(title: "Trade History", icon: "clock.arrow.circlepath", action: {})
                        MenuRow(title: "Donation History", icon: "heart.text.square", action: {
                            showingDonationHistory = true
                        })
                        MenuRow(title: "Settings", icon: "gearshape", action: {})
                        MenuRow(title: "Help & Support", icon: "questionmark.circle", action: {})
                        MenuRow(title: "About Hope", icon: "info.circle", action: {})
                    }
                    .background(Color.white)
                    .cornerRadius(15)
                    .padding(.horizontal)
                    .shadow(color: .gray.opacity(0.1), radius: 5, x: 0, y: 2)
                    
                    Button(action: {}) {
                        Text("Sign Out")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .foregroundColor(.red)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
            .background(Color.gray.opacity(0.05))
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingDonationHistory) {
                DonationHistoryView()
            }
        }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: .gray.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct MenuRow: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .frame(width: 30)
                    .foregroundColor(.pink)
                
                Text(title)
                    .foregroundColor(.black)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding()
        }
        Divider()
            .padding(.leading, 50)
    }
}

struct DonationHistoryView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Total Impact")
                    .font(.headline)
                    .foregroundColor(.gray)
                
                Text("$125")
                    .font(.system(size: 60))
                    .fontWeight(.bold)
                    .foregroundColor(.pink)
                
                Text("donated to pediatric cancer research")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                
                List {
                    DonationRow(type: "Listing Fee", amount: 1, date: Date())
                    DonationRow(type: "Trade Commission", amount: 5, date: Date().addingTimeInterval(-86400))
                    DonationRow(type: "Direct Donation", amount: 20, date: Date().addingTimeInterval(-172800))
                }
                .listStyle(InsetGroupedListStyle())
            }
            .navigationTitle("Donation History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct DonationRow: View {
    let type: String
    let amount: Double
    let date: Date
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(type)
                    .font(.headline)
                Text(dateFormatter.string(from: date))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Text("$\(Int(amount))")
                .font(.headline)
                .foregroundColor(.pink)
        }
        .padding(.vertical, 4)
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }
}