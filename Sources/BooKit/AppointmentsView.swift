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

public struct AppointmentsView: UIViewControllerRepresentable {

    public typealias UIViewControllerType = UINavigationController

    public init() {}
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    public func makeUIViewController(context: Context) -> UINavigationController {
        let appointmentsViewController = AppointmentsViewController()
        //availabilityViewController.authorizeCalendarAccess()
        let nav = UINavigationController(rootViewController: appointmentsViewController)
        nav.delegate = context.coordinator
        return nav
    }

    public func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {

        print("Children \(uiViewController.children)")
    }

    public class Coordinator: NSObject, UINavigationControllerDelegate {

        var parent: AppointmentsView
        init(_ appointments: AppointmentsView) {
            self.parent = appointments
        }

    }
}
