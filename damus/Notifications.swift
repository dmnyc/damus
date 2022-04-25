//
//  Notifications.swift
//  damus
//
//  Created by William Casarin on 2022-04-22.
//

import Foundation

extension Notification.Name {
    static var thread_focus: Notification.Name {
        return Notification.Name("thread focus")
    }
}

extension Notification.Name {
    static var select_event: Notification.Name {
        return Notification.Name("select_event")
    }
}

extension Notification.Name {
    static var select_quote: Notification.Name {
        return Notification.Name("select quote")
    }
}

extension Notification.Name {
    static var reply: Notification.Name {
        return Notification.Name("reply")
    }
}

extension Notification.Name {
    static var switched_timeline: Notification.Name {
        return Notification.Name("switched_timeline")
    }
}

extension Notification.Name {
    static var click_profile_pic: Notification.Name {
        return Notification.Name("click_profile_pic")
    }
}

extension Notification.Name {
    static var scroll_to_top: Notification.Name {
        return Notification.Name("scroll_to_to")
    }
}

extension Notification.Name {
    static var broadcast_event: Notification.Name {
        return Notification.Name("broadcast event")
    }
}

extension Notification.Name {
    static var open_thread: Notification.Name {
        return Notification.Name("open thread")
    }
}

extension Notification.Name {
    static var post: Notification.Name {
        return Notification.Name("send post")
    }
}

extension Notification.Name {
    static var boost: Notification.Name {
        return Notification.Name("boost post")
    }
}

func handle_notify(_ name: Notification.Name) -> NotificationCenter.Publisher {
    return NotificationCenter.default.publisher(for: name)
}

func notify(_ name: NSNotification.Name, _ object: Any?) {
    NotificationCenter.default.post(name: name, object: object)
}
