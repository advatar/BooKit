//
//  BookingViewController.swift
//  Vagus
//
//  Created by Johan Sellström on 2020-10-28.
//  Copyright © 2020 Advatar Systems. All rights reserved.
//

import Foundation
import UIKit
import CalendarKit
import EventKit
import EventKitUI
import DateToolsSwift

extension TimeChunk {
  static func dateComponents(seconds: Int = 0,
                                  minutes: Int = 0,
                                  hours: Int = 0,
                                  days: Int = 0,
                                  weeks: Int = 0,
                                  months: Int = 0,
                                  years: Int = 0) -> TimeChunk {
    return TimeChunk(seconds: seconds,
                     minutes: minutes,
                     hours: hours,
                     days: days,
                     weeks: weeks,
                     months: months,
                     years: years)
  }
}

public class BookingViewController: DayViewController {

    var data = [
        ["15 min",""],
        ["15 min",""],
        ["15 min",""],
        ["15 min",""],
        ["15 min",""],
    ]

    let eventStore = EKEventStore()
    public var ekCalendar = EKCalendar()

    public override func viewDidLoad() {

        super.viewDidLoad()
        title = "Booking"

        let todayButton = UIBarButtonItem(title: "Today", style: .plain, target: self, action: #selector(todayAction))
        let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)

        let items: [UIBarButtonItem] = [
            todayButton,
            flex
        ]

        ekCalendar = EKCalendar(for: .event, eventStore: eventStore)

        navigationController?.setToolbarHidden(false, animated: false)
        setToolbarItems(items, animated: false)
        
        navigationController?.navigationBar.isTranslucent = false
        dayView.autoScrollToFirstEvent = true
        reloadData()
    }


    @objc func todayAction() {
        dayView.state?.move(to: Date())
    }

  // MARK: EventDataSource

    public override func eventsForDate(_ date: Date) -> [EventDescriptor] {

        var date = Date() //date.add(TimeChunk.dateComponents(hours: Int(arc4random_uniform(10) + 5)))
        var events = [Event]()

        for i in 0...4 {
            let event = Event()
            let duration = 30 //Int(arc4random_uniform(160) + 60)
            let datePeriod = TimePeriod(beginning: date,
                                  chunk: TimeChunk.dateComponents(minutes: duration))

            event.startDate = datePeriod.beginning!
            event.endDate = datePeriod.end!

            var info = data[Int(arc4random_uniform(UInt32(data.count)))]

            let timezone = TimeZone.ReferenceType.default
            info.append(datePeriod.beginning!.format(with: "dd.MM.YYYY", timeZone: timezone))
            info.append("\(datePeriod.beginning!.format(with: "HH:mm", timeZone: timezone)) - \(datePeriod.end!.format(with: "HH:mm", timeZone: timezone))")
            event.text = info.reduce("", {$0 + $1 + "\n"})
            event.color = .systemGreen //colors[Int(arc4random_uniform(UInt32(colors.count)))]
            event.isAllDay = false //Int(arc4random_uniform(2)) % 2 == 0

            // Event styles are updated independently from CalendarStyle
            // hence the need to specify exact colors in case of Dark style
            if #available(iOS 12.0, *) {
                if traitCollection.userInterfaceStyle == .dark {
                    event.textColor = textColorForEventInDarkTheme(baseColor: event.color)
                    event.backgroundColor = event.color.withAlphaComponent(0.6)
                }
            }

            events.append(event)
            events.append(event)

            let nextOffset = Int(arc4random_uniform(250) + 40)
            date = date.add(TimeChunk.dateComponents(minutes: nextOffset))
            event.userInfo = String(i)
        }
        return events
    }

    private func textColorForEventInDarkTheme(baseColor: UIColor) -> UIColor {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        baseColor.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return UIColor(hue: h, saturation: s * 0.3, brightness: b, alpha: a)
    }

    func unselectReserved() {
        let events = eventsForDate(Date())
        for event in events {
            print("text \(event)")
        }
    }

  // MARK: DayViewDelegate

    public override func dayViewDidSelectEventView(_ eventView: EventView) {

        guard let descriptor = eventView.descriptor as? Event else {
            return
        }


        print(eventView)
        //unselectReserved()

        print("text \(descriptor.text)")

        if descriptor.text.contains("15 min") {
            descriptor.text = "RESERVED"
            descriptor.backgroundColor = .systemRed
        } else if descriptor.text == "RESERVED" {
            descriptor.text = "15 min"
            descriptor.backgroundColor = .systemGreen
        }

        eventView.updateWithDescriptor(event: descriptor)

        print("Event has been selected: \(descriptor) \(String(describing: descriptor.userInfo))")

        let event = EKEvent.init(eventStore: self.eventStore)
        event.title = "Dr. Mengele"
        event.startDate = Date()
        event.availability = .busy
        event.endDate = Date()
        //event.calendar = self.calendar
        let editEventViewController = EKEventEditViewController()
        editEventViewController.event = event
        present(editEventViewController, animated: true, completion: nil)

    }

    public override func dayViewDidLongPressEventView(_ eventView: EventView) {
        guard let descriptor = eventView.descriptor as? Event else {
            return
        }
        print("Event has been longPressed: \(descriptor) \(String(describing: descriptor.userInfo))")
    }

    public override func dayView(dayView: DayView, willMoveTo date: Date) {
        print("DayView = \(dayView) will move to: \(date)")
    }

    public override func dayView(dayView: DayView, didMoveTo date: Date) {
        print("DayView = \(dayView) did move to: \(date)")
    }

    public override func dayView(dayView: DayView, didLongPressTimelineAt date: Date) {
        print("Did long press timeline at date \(date)")
    }
}

