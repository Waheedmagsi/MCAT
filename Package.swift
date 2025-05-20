// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "MCATPrep",
    platforms: [
        .iOS(.v17),
        .macOS(.v10_15)
    ],
    products: [
        .library(name: "MBFoundation", targets: ["MBFoundation"]),
        .library(name: "MBUI", targets: ["MBUI"]),
        .library(name: "SAKTLiteKit", targets: ["SAKTLiteKit"]),
        .library(name: "CAKTClient", targets: ["CAKTClient"]),
        .library(name: "MBMocks", targets: ["MBMocks"])
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.8.0"),
        .package(url: "https://github.com/supabase-community/supabase-swift.git", from: "2.0.0"),
        .package(url: "https://github.com/apple/swift-protobuf.git", from: "1.25.0"),
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture.git", from: "1.7.0")
    ],
    targets: [
        // MBFoundation - Core utilities, networking, models
        .target(
            name: "MBFoundation",
            dependencies: [
                .product(name: "Alamofire", package: "Alamofire"),
                .product(name: "Supabase", package: "supabase-swift")
            ],
            path: "Packages/MBFoundation/Sources"
        ),
        
        // MBUI - Reusable SwiftUI components
        .target(
            name: "MBUI",
            dependencies: ["MBFoundation"],
            path: "Packages/MBUI/Sources"
        ),
        
        // SAKTLiteKit - Offline algorithm implementation
        .target(
            name: "SAKTLiteKit",
            dependencies: ["MBFoundation"],
            path: "Packages/Algorithms/SAKTLiteKit/Sources"
        ),
        
        // CAKTClient - Client for CAKT server API
        .target(
            name: "CAKTClient",
            dependencies: [
                "MBFoundation",
                .product(name: "SwiftProtobuf", package: "swift-protobuf")
            ],
            path: "Packages/Algorithms/CAKTClient/Sources"
        ),
        
        // MBMocks - Test utilities and mocks
        .target(
            name: "MBMocks",
            dependencies: [
                "MBFoundation",
                "SAKTLiteKit",
                "CAKTClient"
            ],
            path: "Packages/MBMocks/Sources"
        ),
        
        // Test targets
        .testTarget(
            name: "MBFoundationTests",
            dependencies: ["MBFoundation", "MBMocks"],
            path: "Tests/MBFoundationTests"
        ),
        .testTarget(
            name: "SAKTLiteKitTests",
            dependencies: ["SAKTLiteKit", "MBMocks"],
            path: "Tests/SAKTLiteKitTests"
        )
    ]
) 