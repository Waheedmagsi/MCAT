import Foundation

struct StudyMaterial: Identifiable {
    enum MaterialType {
        case pdf(name: String)
        case video(url: URL)
    }
    let id = UUID()
    let title: String
    let type: MaterialType
}

struct Topic: Identifiable {
    let id = UUID()
    let title: String
    let materials: [StudyMaterial]
}