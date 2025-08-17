import SwiftUI
import PhotosUI

struct PostItemView: View {
    @EnvironmentObject var dataManager: DataManager
    @Binding var selectedTab: Int
    @State private var title = ""
    @State private var description = ""
    @State private var selectedCategory: Category = .other
    @State private var selectedCondition: Condition = .good
    @State private var location = ""
    @State private var selectedImages: [PhotosPickerItem] = []
    @State private var selectedImageData: [Data] = []
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @FocusState private var isInputActive: Bool
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        isInputActive = false
                    }
                
                ScrollView {
                    VStack(spacing: 20) {
                        Text("List an Item")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.pink)
                    
                    Text("$1 listing fee goes to pediatric cancer research")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    VStack(alignment: .leading, spacing: 15) {
                        VStack(alignment: .leading) {
                            Text("Title *")
                                .font(.headline)
                            TextField("Enter item title", text: $title)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .focused($isInputActive)
                        }
                        
                        VStack(alignment: .leading) {
                            Text("Description *")
                                .font(.headline)
                            TextEditor(text: $description)
                                .frame(height: 100)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                                .focused($isInputActive)
                        }
                        
                        VStack(alignment: .leading) {
                            Text("Category")
                                .font(.headline)
                            Picker("Category", selection: $selectedCategory) {
                                ForEach(Category.allCases, id: \.self) { category in
                                    Text(category.rawValue).tag(category)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(10)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        }
                        
                        VStack(alignment: .leading) {
                            Text("Condition")
                                .font(.headline)
                            Picker("Condition", selection: $selectedCondition) {
                                ForEach(Condition.allCases, id: \.self) { condition in
                                    Text(condition.rawValue).tag(condition)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        }
                        
                        VStack(alignment: .leading) {
                            Text("Location *")
                                .font(.headline)
                            TextField("Enter your location", text: $location)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .focused($isInputActive)
                        }
                        
                        VStack(alignment: .leading) {
                            Text("Photos")
                                .font(.headline)
                            
                            PhotosPicker(
                                selection: $selectedImages,
                                maxSelectionCount: 5,
                                matching: .images
                            ) {
                                HStack {
                                    Image(systemName: "photo.on.rectangle.angled")
                                    Text("Select Photos (Max 5)")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.pink.opacity(0.1))
                                .foregroundColor(.pink)
                                .cornerRadius(10)
                            }
                            
                            if !selectedImageData.isEmpty {
                                ScrollView(.horizontal) {
                                    HStack {
                                        ForEach(selectedImageData, id: \.self) { imageData in
                                            if let uiImage = UIImage(data: imageData) {
                                                Image(uiImage: uiImage)
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: 100, height: 100)
                                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    
                    Button(action: postItem) {
                        HStack {
                            Image(systemName: "heart.fill")
                            Text("Post Item ($1 donation)")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            Group {
                                if title.isEmpty || description.isEmpty || location.isEmpty {
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(Color.gray.opacity(0.2))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 15)
                                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                        )
                                } else {
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [Color.pink, Color.purple]), 
                                                startPoint: .leading, 
                                                endPoint: .trailing
                                            )
                                        )
                                }
                            }
                        )
                        .foregroundColor(title.isEmpty || description.isEmpty || location.isEmpty ? Color.gray.opacity(0.5) : .white)
                        .font(.headline)
                        .scaleEffect(title.isEmpty || description.isEmpty || location.isEmpty ? 0.98 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: title.isEmpty || description.isEmpty || location.isEmpty)
                    }
                    .padding(.horizontal)
                    .disabled(title.isEmpty || description.isEmpty || location.isEmpty)
                    }
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        isInputActive = false
                    }
                }
            }
            .alert("Posted!", isPresented: $showingAlert) {
                Button("OK", role: .cancel) {
                    clearForm()
                    selectedTab = 0
                }
            } message: {
                Text(alertMessage)
            }
        }
        .onChange(of: selectedImages) {
            Task {
                selectedImageData.removeAll()
                for item in selectedImages {
                    if let data = try? await item.loadTransferable(type: Data.self) {
                        selectedImageData.append(data)
                    }
                }
            }
        }
    }
    
    func postItem() {
        let newItem = Item(
            title: title,
            description: description,
            category: selectedCategory,
            condition: selectedCondition,
            userId: dataManager.currentUser.id,
            location: location
        )
        
        dataManager.addItem(newItem)
        
        alertMessage = "Your item has been posted! Thank you for your $1 donation to pediatric cancer research."
        showingAlert = true
    }
    
    func clearForm() {
        title = ""
        description = ""
        selectedCategory = .other
        selectedCondition = .good
        location = ""
        selectedImages = []
        selectedImageData = []
    }
}