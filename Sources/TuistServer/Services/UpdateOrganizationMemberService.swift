import Foundation
import OpenAPIURLSession
import TuistSupport

public protocol UpdateOrganizationMemberServicing {
    func updateOrganizationMember(
        organizationName: String,
        username: String,
        role: CloudOrganization.Member.Role,
        serverURL: URL
    ) async throws -> CloudOrganization.Member
}

enum UpdateOrganizationMemberServiceError: FatalError {
    case unknownError(Int)
    case notFound(String)
    case forbidden(String)
    case badRequest(String)

    var type: ErrorType {
        switch self {
        case .unknownError:
            return .bug
        case .notFound, .forbidden, .badRequest:
            return .abort
        }
    }

    var description: String {
        switch self {
        case let .unknownError(statusCode):
            return "The member could not be updated due to an unknown cloud response of \(statusCode)."
        case let .notFound(message), let .forbidden(message), let .badRequest(message):
            return message
        }
    }
}

public final class UpdateOrganizationMemberService: UpdateOrganizationMemberServicing {
    public init() {}

    public func updateOrganizationMember(
        organizationName: String,
        username: String,
        role: CloudOrganization.Member.Role,
        serverURL: URL
    ) async throws -> CloudOrganization.Member {
        let client = Client.cloud(serverURL: serverURL)

        let response = try await client.updateOrganizationMember(
            .init(
                path: .init(
                    organization_name: organizationName,
                    user_name: username
                ),
                body: .json(.init(role: .init(rawValue: role.rawValue)!))
            )
        )
        switch response {
        case let .ok(okResponse):
            switch okResponse.body {
            case let .json(organizationMember):
                return CloudOrganization.Member(organizationMember)
            }
        case let .notFound(notFoundResponse):
            switch notFoundResponse.body {
            case let .json(error):
                throw UpdateOrganizationMemberServiceError.notFound(error.message)
            }
        case let .forbidden(forbiddenResponse):
            switch forbiddenResponse.body {
            case let .json(error):
                throw UpdateOrganizationMemberServiceError.forbidden(error.message)
            }
        case let .undocumented(statusCode: statusCode, _):
            throw UpdateOrganizationMemberServiceError.unknownError(statusCode)
        case let .badRequest(badRequestResponse):
            switch badRequestResponse.body {
            case let .json(error):
                throw UpdateOrganizationMemberServiceError.badRequest(error.message)
            }
        }
    }
}
