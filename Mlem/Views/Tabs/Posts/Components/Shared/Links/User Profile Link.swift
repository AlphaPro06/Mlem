//
//  User Profile Link.swift
//  Mlem
//
//  Created by David Bureš on 02.04.2022.
//

import SwiftUI
import CachedAsyncImage

struct UserProfileLink: View
{
    @AppStorage("shouldShowUserAvatars") var shouldShowUserAvatars: Bool = true
    
    @State var account: SavedAccount
    @State var user: APIPerson
    
    // Extra context about where the link is being displayed
    // to pick the correct flair
    @State var postContext: APIPostView? = nil
    @State var commentContext: APIComment? = nil
    
    static let developerNames = ["lFenix"]
    
    static let flairDeveloper = UserProfileLinkFlair(color: Color.purple, systemIcon: "hammer.fill")
    static let flairMod = UserProfileLinkFlair(color: Color.green, systemIcon: "shield.fill")
    static let flairBot = UserProfileLinkFlair(color: Color.indigo, systemIcon: "faxmachine.fill")
    static let flairOP = UserProfileLinkFlair(color: Color.orange, systemIcon: "mic.fill")
    static let flairAdmin = UserProfileLinkFlair(color: Color.red)
   
    var body: some View
    {
        NavigationLink(destination: UserView(userID: user.id, account: account))
        {
            HStack(alignment: .center, spacing: 5) {
                if shouldShowUserAvatars {
                    if let avatarLink = user.avatar {
                        AvatarView(avatarLink: avatarLink)
                    }
                }
                
                /* Disabled icons for now */
                if let flair = calculateFlair() {
                    if let flairSystemIcon = flair.systemIcon {
                        Image(systemName: flairSystemIcon).foregroundColor(flair.color)
                    }
                }
                
                
                // User display name if one exists
                Text(user.displayName ?? user.name)
                    .minimumScaleFactor(0.01)
                    .lineLimit(1)
            }
            .if(calculateFlair() != nil)
            { viewProxy in
                viewProxy
                    .foregroundColor(calculateFlair()!.color).bold()
            }
        }
    }
    
    struct UserProfileLinkFlair {
        var color: Color
        var systemIcon: String? = nil
    }
    
    private func calculateFlair() -> UserProfileLinkFlair? {
        if UserProfileLink.developerNames.contains(where: { $0 == user.name }) {
            return UserProfileLink.flairDeveloper
        }
        if user.admin {
            return UserProfileLink.flairAdmin
        }
        if user.botAccount {
            return UserProfileLink.flairBot
        }
        if commentContext != nil {
            if commentContext!.distinguished {
                return UserProfileLink.flairMod
            }
        }
        if postContext != nil {
            if user == postContext!.creator {
                return UserProfileLink.flairOP
            }
        }
        return nil
    }
}

struct UserProfileLinkPreview: PreviewProvider {
    static let previewAccount = SavedAccount(id: 0, instanceLink: URL(string: "lemmy.com")!, accessToken: "abcdefg", username: "Test Account")
    
    // Only Admin and Bot work right now
    // Because the rest require post/comment context
    enum PreviewUserType:  String, CaseIterable {
        case Normal = "normal"
        case Mod = "mod"
        case OP = "op"
        case Bot = "bot"
        case Admin = "admin"
        case Dev = "developer"
    }
    
    static func generatePreviewUser(name: String, displayName: String, userType: PreviewUserType) -> APIPerson {
        return APIPerson(id: name.hashValue, name: name, displayName: displayName, avatar: nil, banned: false, published: "idk", updated: nil, actorId: URL(string: "google.com")!, bio: nil, local: false, banner: nil, deleted: false, inboxUrl: URL(string: "google.com")!, sharedInboxUrl: nil, matrixUserId: nil, admin: userType == .Admin, botAccount: userType == .Bot, banExpires: nil, instanceId: 123)
    }
    
    static func generatePreviewComment(creator: APIPerson, isMod: Bool) -> APIComment {
        return APIComment(id: 0, creatorId: creator.id, postId: 0, content: "", removed: false, deleted: false, published: Date.now, updated: nil, apId: "foo.bar", local: false, path: "foo", distinguished: isMod, languageId: 0)
    }
    
    static func generatePreviewPost(creator: APIPerson) -> APIPostView {
        let community = generateFakeCommunity(id: 123, namePrefix: "Test")
        let post = APIPost(id: 123, name: "Test Post Title", url: nil, body: "This is a test post body", creatorId: creator.id, communityId: 123, deleted: false, embedDescription: "Embeedded Description", embedTitle: "Embedded Title", embedVideoUrl: nil, featuredCommunity: false, featuredLocal: false, languageId: 0, apId: "my.app.id", local: false, locked: false, nsfw: false, published: Date.now, removed: false, thumbnailUrl: nil, updated: nil)
        
        let postVotes = APIPostAggregates(id: 123, postId: post.id, comments: 0, score: 10, upvotes: 15, downvotes: 5, published: Date.now, newestCommentTime: Date.now, newestCommentTimeNecro: Date.now, featuredCommunity: false, featuredLocal: false)
        
        return APIPostView(post: post, creator: creator, community: community, creatorBannedFromCommunity: false, counts: postVotes, subscribed: .notSubscribed, saved: false, read: false, creatorBlocked: false, unreadComments: 0)
    }
    
    static func generateUserProfileLink(name: String, userType: PreviewUserType) -> UserProfileLink {
        var previewUserName = name
        if userType == .Dev {
            previewUserName = UserProfileLink.developerNames[0]
        }
        
        let previewUser = generatePreviewUser(name: previewUserName, displayName: name, userType: userType);
        
        var postContext: APIPostView? = nil
        var commentContext: APIComment? = nil
        
        if userType == .Mod {
            commentContext = generatePreviewComment(creator: previewUser, isMod:  true)
        }
        
        if userType == .OP {
            commentContext = generatePreviewComment(creator: previewUser, isMod:  false)
            postContext = generatePreviewPost(creator: previewUser)
        }
        
        return UserProfileLink(account: UserProfileLinkPreview.previewAccount, user: previewUser, postContext: postContext, commentContext: commentContext)
    }
    
    static var previews: some View {
        VStack {
            ForEach(PreviewUserType.allCases, id: \.rawValue) {
                userType in
                generateUserProfileLink(name: "\(userType)User", userType: userType)
            }
        }
    }
}
