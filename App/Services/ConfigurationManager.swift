import Foundation

/// Manages application-wide configuration settings
class ConfigurationManager {
    // Singleton instance for app-wide access
    static let shared = ConfigurationManager()
    
    // MARK: - Supabase Settings
    /// Supabase project URL
    var supabaseURL: String {
        switch currentEnvironment {
        case .development:
            return "https://dev.supabase.mcatprep.com"
        case .staging:
            return "https://staging.supabase.mcatprep.com"
        case .production:
            return "https://supabase.mcatprep.com"
        }
    }
    
    // MARK: - Connectivity Settings
    /// Minimum delay between server polls when in offline mode (in seconds)
    let offlineModePollingInterval: TimeInterval = 60.0
    
    /// Timeout for network requests (in seconds)
    let networkTimeoutInterval: TimeInterval = 10.0
    
    // MARK: - Algorithm Settings
    /// Maximum number of interactions to track in SAKTLite
    let saktMaxInteractionHistory: Int = 512
    
    /// Size of the skill vector for user knowledge state
    let skillVectorSize: Int = 128
    
    /// Feature flags for algorithm usage
    var useCaktForDailyDrill: Bool = true
    var useCaktForFullExam: Bool = true
    
    // MARK: - Quiz Settings
    /// Maximum questions per session by quiz type
    let maxQuestionsPerDeck: Int = 50
    let maxQuestionsPerDailyDrill: Int = 10
    let maxQuestionsPerFullExam: Int = 230
    
    /// Daily drill refresh schedule (in hours)
    let dailyDrillRefreshInterval: TimeInterval = 24 * 60 * 60
    
    // MARK: - Content Settings
    /// Content refresh intervals (in seconds)
    let contentRefreshInterval: TimeInterval = 7 * 24 * 60 * 60 // Weekly
    
    /// Maximum size of offline content cache (in MB)
    let maxOfflineCacheSize: Int = 100
    
    // MARK: - Premium Features
    /// Limit for non-premium users
    let freeUserExamLimit: Int = 1 // 1 exam per week for free users
    
    // MARK: - Analytics Settings
    /// Frequency of analytics uploads (in seconds)
    let analyticsUploadInterval: TimeInterval = 30 * 60 // Every 30 minutes
    
    // MARK: - Environment
    private enum Environment: String {
        case development
        case staging
        case production
    }
    
    private let currentEnvironment: Environment
    
    // MARK: - Initialization
    
    private init() {
        // Determine environment based on build configuration
        #if DEBUG
        currentEnvironment = .development
        #elseif STAGING
        currentEnvironment = .staging
        #else
        currentEnvironment = .production
        #endif
        
        // Load environment-specific configurations
        loadEnvironmentConfig()
    }
    
    // MARK: - Methods
    
    /// Get the API URL based on the current environment
    var apiBaseURL: URL {
        switch currentEnvironment {
        case .development:
            return URL(string: "https://dev-api.mcatprep.com")!
        case .staging:
            return URL(string: "https://staging-api.mcatprep.com")!
        case .production:
            return URL(string: "https://api.mcatprep.com")!
        }
    }
    
    /// Get the CAKT service URL based on the current environment
    var caktServiceURL: URL {
        switch currentEnvironment {
        case .development:
            return URL(string: "https://dev-cakt.mcatprep.com")!
        case .staging:
            return URL(string: "https://staging-cakt.mcatprep.com")!
        case .production:
            return URL(string: "https://cakt.mcatprep.com")!
        }
    }
    
    /// Returns true if we're running in a development environment
    var isDevelopmentMode: Bool {
        return currentEnvironment == .development
    }
    
    /// Sets the current environment manually - primarily for testing
    func setEnvironment(_ env: String) {
        guard let environment = Environment(rawValue: env) else { return }
        if let mirror = Mirror(reflecting: self).descendant("currentEnvironment") as? Environment {
            // This is a bit of a hack to modify the let property for testing
            Unmanaged.passUnretained(mirror).toOpaque().storeBytes(of: environment, as: Environment.self)
        }
    }
    
    /// Load environment-specific configuration from plist or remote config
    private func loadEnvironmentConfig() {
        // In a real app, this would load from a plist or remote config
        // For now, we just use hardcoded values based on environment
        
        if currentEnvironment == .development {
            // Development-specific settings
            useCaktForDailyDrill = true
            useCaktForFullExam = true
        }
    }
} 