import SwiftUI

struct CategorySelectionView: View {
    @Binding var selectedCategory: Category?
    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""
    
    // Constructor for non-optional binding
    init(selectedCategory: Binding<Category>) {
        self._selectedCategory = Binding(
            get: { selectedCategory.wrappedValue },
            set: { newValue in
                if let value = newValue {
                    selectedCategory.wrappedValue = value
                }
            }
        )
    }
    
    // Constructor for optional binding
    init(selectedCategory: Binding<Category?>) {
        self._selectedCategory = selectedCategory
    }
    
    var filteredCategories: [Category] {
        if searchText.isEmpty {
            return Category.allCases
        } else {
            return Category.allCases.filter { 
                $0.rawValue.lowercased().contains(searchText.lowercased())
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
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "chevron.left")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                            .font(.body)
                        
                        TextField("", text: $searchText)
                            .placeholder(when: searchText.isEmpty) {
                                Text("What do you want to buy?")
                                    .foregroundColor(.gray)
                            }
                            .foregroundColor(.white)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                        
                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                                    .font(.body)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(Color.white.opacity(0.1))
                    )
                    .padding(.horizontal)
                    .padding(.vertical, 16)
                    
                    // All categories title
                    HStack {
                        Text("All categories")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                    
                    // Categories List
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(filteredCategories, id: \.self) { category in
                                CategoryRow(
                                    category: category,
                                    isSelected: selectedCategory == category,
                                    onTap: {
                                        if selectedCategory == category {
                                            selectedCategory = nil
                                        } else {
                                            selectedCategory = category
                                        }
                                        dismiss()
                                    }
                                )
                            }
                        }
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
}

struct CategoryRow: View {
    let category: Category
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Icon background
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 56, height: 56)
                    .overlay(
                        Image(systemName: iconForCategory(category))
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                    )
                
                Text(category.rawValue)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.body)
                        .foregroundColor(Color.hopeBlue)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(
                isSelected ? Color.hopeBlue.opacity(0.1) : Color.clear
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    func iconForCategory(_ category: Category) -> String {
        switch category {
        case .antiquesCollectibles:
            return "crown"
        case .artsCrafts:
            return "paintpalette"
        case .autoParts:
            return "gear"
        case .baby:
            return "figure.2.and.child.holdinghands"
        case .booksMoviesMusic:
            return "book"
        case .electronics:
            return "iphone"
        case .furniture:
            return "sofa"
        case .garageSale:
            return "house"
        case .healthBeauty:
            return "heart"
        case .homeKitchen:
            return "house.fill"
        case .homeImprovement:
            return "hammer"
        case .housingForSale:
            return "house.circle"
        case .jewelryWatches:
            return "sparkles"
        case .kidswearBaby:
            return "tshirt"
        case .luggageBags:
            return "bag"
        case .menswear:
            return "person.fill"
        case .miscellaneous:
            return "square.grid.2x2"
        case .musicalInstruments:
            return "guitars"
        case .patioGarden:
            return "leaf"
        case .petSupplies:
            return "pawprint"
        case .rentals:
            return "dollarsign.circle"
        case .sportingGoods:
            return "figure.run"
        case .toysGames:
            return "gamecontroller"
        case .vehicles:
            return "car"
        case .womenswear:
            return "person.fill"
        }
    }
}

