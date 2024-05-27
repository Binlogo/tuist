import Foundation
import Mockable
import TuistGraph
import TuistSupport

@Mockable
public protocol CacheDirectoriesProviderFactoring {
    func cacheDirectories() throws -> CacheDirectoriesProviding
}

public final class CacheDirectoriesProviderFactory: CacheDirectoriesProviderFactoring {
    public init() {}
    public func cacheDirectories() throws -> CacheDirectoriesProviding {
        let provider = CacheDirectoriesProvider()
        for category in CacheCategory.allCases {
            let directory = try provider.tuistCacheDirectory(for: category)
            if !FileHandler.shared.exists(directory) {
                try FileHandler.shared.createFolder(directory)
            }
        }
        return provider
    }
}
