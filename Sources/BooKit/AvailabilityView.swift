//
//  AvailabilityView.swift
//  Vagus
//
//  Created by Johan Sellström on 2020-10-28.
//  Copyright © 2020 Advatar Systems. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI

struct AvailabilityView: UIViewControllerRepresentable {

    typealias UIViewControllerType = UINavigationController

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UINavigationController {
        let availabilityViewController = AvailabilityViewController()
        availabilityViewController.authorizeCalendarAccess()
        let nav = UINavigationController(rootViewController: availabilityViewController)
        nav.delegate = context.coordinator

    
        return nav
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {

        print("Children \(uiViewController.children)")
    }

    class Coordinator: NSObject, UINavigationControllerDelegate {

        var parent: AvailabilityView
        init(_ availabilityView: AvailabilityView) {
            self.parent = availabilityView
        }

    }
}
