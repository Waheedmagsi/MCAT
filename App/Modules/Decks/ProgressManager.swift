import Foundation
import Combine

class ProgressManager: ObservableObject {
    @Published var lastMaterialID: UUID?
    @Published var lastPDFPage: Int = 0
    @Published var lastVideoTime: Double = 0.0

    func saveProgress(materialID: UUID, pdfPage: Int? = nil, videoTime: Double? = nil) {
        lastMaterialID = materialID
        if let page = pdfPage { lastPDFPage = page }
        if let time = videoTime { lastVideoTime = time }
        
        // Save to UserDefaults for persistence
        UserDefaults.standard.set(materialID.uuidString, forKey: "lastMaterialID")
        UserDefaults.standard.set(lastPDFPage, forKey: "lastPDFPage")
        UserDefaults.standard.set(lastVideoTime, forKey: "lastVideoTime")
    }

    func loadProgress() {
        if let idString = UserDefaults.standard.string(forKey: "lastMaterialID"),
           let uuid = UUID(uuidString: idString) {
            lastMaterialID = uuid
        }
        lastPDFPage = UserDefaults.standard.integer(forKey: "lastPDFPage")
        lastVideoTime = UserDefaults.standard.double(forKey: "lastVideoTime")
    }
}