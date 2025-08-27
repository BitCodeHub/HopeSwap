import Foundation
import FirebaseFirestore

extension FirestoreManager {
    
    // Helper function to find document by item ID
    private func findDocumentId(for itemId: String) async throws -> String {
        // First try using the item ID as document ID
        let document = try await db.collection("items").document(itemId).getDocument()
        
        if document.exists {
            return document.documentID
        }
        
        // If not found, search by id field
        print("⚠️ Document not found with ID \(itemId), searching by id field...")
        let querySnapshot = try await db.collection("items")
            .whereField("id", isEqualTo: itemId)
            .limit(to: 1)
            .getDocuments()
        
        guard let doc = querySnapshot.documents.first else {
            throw NSError(domain: "FirestoreError", code: 404, userInfo: [NSLocalizedDescriptionKey: "Item not found in database"])
        }
        
        print("✅ Found document with ID \(doc.documentID) for item \(itemId)")
        return doc.documentID
    }
    
    // Update all analytics methods to use the helper
    func safeIncrementItemClick(itemId: String) async throws {
        do {
            let docId = try await findDocumentId(for: itemId)
            print("🔥 Incrementing clickCount for document: \(docId)")
            try await db.collection("items").document(docId).updateData([
                "clickCount": FieldValue.increment(Int64(1))
            ])
            print("✅ Successfully incremented clickCount")
        } catch {
            print("❌ Error incrementing clickCount: \(error)")
            throw error
        }
    }
    
    func safeIncrementVideoPlay(itemId: String) async throws {
        do {
            let docId = try await findDocumentId(for: itemId)
            print("🔥 Incrementing videoPlays for document: \(docId)")
            try await db.collection("items").document(docId).updateData([
                "videoPlays": FieldValue.increment(Int64(1))
            ])
            print("✅ Successfully incremented videoPlays")
        } catch {
            print("❌ Error incrementing videoPlays: \(error)")
            throw error
        }
    }
    
    func safeIncrementItemSave(itemId: String) async throws {
        do {
            let docId = try await findDocumentId(for: itemId)
            print("🔥 Incrementing saveCount for document: \(docId)")
            try await db.collection("items").document(docId).updateData([
                "saveCount": FieldValue.increment(Int64(1))
            ])
            print("✅ Successfully incremented saveCount")
        } catch {
            print("❌ Error incrementing saveCount: \(error)")
            throw error
        }
    }
    
    func safeDecrementItemSave(itemId: String) async throws {
        do {
            let docId = try await findDocumentId(for: itemId)
            print("🔥 Decrementing saveCount for document: \(docId)")
            try await db.collection("items").document(docId).updateData([
                "saveCount": FieldValue.increment(Int64(-1))
            ])
            print("✅ Successfully decremented saveCount")
        } catch {
            print("❌ Error decrementing saveCount: \(error)")
            throw error
        }
    }
    
    func safeIncrementItemShare(itemId: String) async throws {
        do {
            let docId = try await findDocumentId(for: itemId)
            print("🔥 Incrementing shareCount for document: \(docId)")
            try await db.collection("items").document(docId).updateData([
                "shareCount": FieldValue.increment(Int64(1))
            ])
            print("✅ Successfully incremented shareCount")
        } catch {
            print("❌ Error incrementing shareCount: \(error)")
            throw error
        }
    }
}