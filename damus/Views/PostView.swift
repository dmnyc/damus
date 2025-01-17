//
//  Post.swift
//  damus
//
//  Created by William Casarin on 2022-04-03.
//

import SwiftUI

enum NostrPostResult {
    case post(NostrPost)
    case cancel
}

let POST_PLACEHOLDER = NSLocalizedString("Type your post here...", comment: "Text box prompt to ask user to type their post.")

struct PostView: View {
    @State var post: NSMutableAttributedString = NSMutableAttributedString()

    @FocusState var focus: Bool
    @State var showPrivateKeyWarning: Bool = false
    
    let replying_to: NostrEvent?
    let references: [ReferencedId]
    let damus_state: DamusState

    @Environment(\.presentationMode) var presentationMode

    enum FocusField: Hashable {
      case post
    }

    func cancel() {
        NotificationCenter.default.post(name: .post, object: NostrPostResult.cancel)
        dismiss()
    }

    func dismiss() {
        self.presentationMode.wrappedValue.dismiss()
    }

    func send_post() {
        var kind: NostrKind = .text
        if replying_to?.known_kind == .chat {
            kind = .chat
        }

        post.enumerateAttributes(in: NSRange(location: 0, length: post.length), options: []) { attributes, range, stop in
            if let link = attributes[.link] as? String {
                post.replaceCharacters(in: range, with: link)
            }
        }

        let content = self.post.string.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        let new_post = NostrPost(content: content, references: references, kind: kind)

        NotificationCenter.default.post(name: .post, object: NostrPostResult.post(new_post))

        if let replying_to {
            damus_state.drafts.replies.removeValue(forKey: replying_to)
        } else {
            damus_state.drafts.post = NSMutableAttributedString(string: "")
        }

        dismiss()
    }

    var is_post_empty: Bool {
        return post.string.allSatisfy { $0.isWhitespace }
    }

    var body: some View {
        VStack {
            HStack {
                Button(NSLocalizedString("Cancel", comment: "Button to cancel out of posting a note.")) {
                    self.cancel()
                }
                .foregroundColor(.primary)

                Spacer()

                if !is_post_empty {
                    Button(NSLocalizedString("Post", comment: "Button to post a note.")) {
                        showPrivateKeyWarning = contentContainsPrivateKey(self.post.string)

                        if !showPrivateKeyWarning {
                            self.send_post()
                        }
                    }
                    .font(.system(size: 14, weight: .bold))
                    .frame(width: 80, height: 30)
                    .foregroundColor(.white)
                    .background(LINEAR_GRADIENT)
                    .clipShape(Capsule())
                }
            }
            .frame(height: 30)
            .padding([.top, .bottom], 4)
            
            HStack(alignment: .top) {
                
                ProfilePicView(pubkey: damus_state.pubkey, size: 45.0, highlight: .none, profiles: damus_state.profiles)
                
                VStack(alignment: .leading) {
                    ZStack(alignment: .topLeading) {
                        
                        TextViewWrapper(attributedText: $post)
                            .focused($focus)
                            .textInputAutocapitalization(.sentences)
                            .onChange(of: post) { _ in
                                if let replying_to {
                                    damus_state.drafts.replies[replying_to] = post
                                } else {
                                    damus_state.drafts.post = post
                                }
                            }
                        
                        if post.string.isEmpty {
                            Text(POST_PLACEHOLDER)
                                .padding(.top, 8)
                                .padding(.leading, 4)
                                .foregroundColor(Color(uiColor: .placeholderText))
                                .allowsHitTesting(false)
                        }
                    }
                }
            }

            // This if-block observes @ for tagging
            if let searching = get_searching_string(post.string) {
                VStack {
                    Spacer()
                    UserSearch(damus_state: damus_state, search: searching, post: $post)
                }.zIndex(1)
            }
        }
        .onAppear() {
            if let replying_to {
                if damus_state.drafts.replies[replying_to] == nil {
                    damus_state.drafts.post = NSMutableAttributedString(string: "")
                }
                if let p = damus_state.drafts.replies[replying_to] {
                    post = p
                }
            } else {
                post = damus_state.drafts.post
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.focus = true
            }
        }
        .onDisappear {
            if let replying_to, let reply = damus_state.drafts.replies[replying_to], reply.string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                damus_state.drafts.replies.removeValue(forKey: replying_to)
            } else if replying_to == nil && damus_state.drafts.post.string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                damus_state.drafts.post = NSMutableAttributedString(string : "")
            }
        }
        .padding()
        .alert(NSLocalizedString("Note contains \"nsec1\" private key. Are you sure?", comment: "Alert user that they might be attempting to paste a private key and ask them to confirm."), isPresented: $showPrivateKeyWarning, actions: {
            Button(NSLocalizedString("No", comment: "Button to cancel out of posting a note after being alerted that it looks like they might be posting a private key."), role: .cancel) {
                showPrivateKeyWarning = false
            }
            Button(NSLocalizedString("Yes, Post with Private Key", comment: "Button to proceed with posting a note even though it looks like they might be posting a private key."), role: .destructive) {
                self.send_post()
            }
        })
    }
}

func get_searching_string(_ post: String) -> String? {
    guard let handle = post.components(separatedBy: .whitespacesAndNewlines).first(where: {$0.first == "@"}) else {
        return nil
    }
    
    guard handle.count >= 2 else {
        return nil
    }
    
    // don't include @npub... strings
    guard handle.count != 64 else {
        return nil
    }
    
    return String(handle.dropFirst())
}

struct PostView_Previews: PreviewProvider {
    static var previews: some View {
        PostView(replying_to: nil, references: [], damus_state: test_damus_state())
    }
}
