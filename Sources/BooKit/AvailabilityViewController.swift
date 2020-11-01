import UIKit
import CalendarKit
import DateToolsSwift
import EventKit
import EventKitUI

class AvailabilityViewController: DayViewController {

    let eventStore = EKEventStore()
    var ekCalendar: EKCalendar?
    var calendarChooser: EKCalendarChooser!
    var toggleButton = UIBarButtonItem()

/*
 {
 "@type": "jsevent",
 "uid": "2a358cee-6489-4f14-a57f-c104db4dc2f1",
 "updated": "2018-01-15T18:00:00Z",
 "title": "Some event",
 "start": "2018-01-15T13:00:00",
 "timeZone": "America/New_York",
 "duration": "PT1H"
 }
 */

    var sampleEvents = [EventDescriptor]()

    var data = [
        [ "FREE", ""],
        [ "FREE", ""],
        [ "FREE", ""],
        [ "FREE", ""],
    ]

    var events = [Event]()

    var colors = [UIColor.blue,
                UIColor.yellow,
                UIColor.green,
                UIColor.red]

    static func createAvailabilityCalendar(eventStore: EKEventStore) -> EKCalendar? {
        var config = Config()
        let calendar = EKCalendar(for: .event, eventStore: eventStore)

        do {
            if eventStore.sources.count == 0 { // reproducible after Reset Content and Settings
                calendar.source = EKSource()
            } else if let defaultCalendar = eventStore.defaultCalendarForNewEvents {
                calendar.source = defaultCalendar.source
            }
            calendar.title = "Availability"
            try eventStore.saveCalendar(calendar, commit: true)
            config.appointmentsCalendarIdentifier = calendar.calendarIdentifier
            return calendar
        } catch {
            print("\(error)")
            return nil
        }
    }

    func authorizeCalendarAccess() {

        let config = Config()
        self.eventStore.requestAccess(to: EKEntityType.event) {
            (accessGranted: Bool, error: Error?) in

            if let error = error {
                print("\(error)")
            } else {
                print("accessGranted \(accessGranted)")
            }

            if accessGranted, config.appointmentsCalendarIdentifier == nil {
                self.ekCalendar = AvailabilityViewController.createAvailabilityCalendar(eventStore: self.eventStore)
            } else if accessGranted, let identifier = config.appointmentsCalendarIdentifier {
                self.ekCalendar = self.eventStore.calendar(withIdentifier: identifier)
                if self.ekCalendar == nil {
                    self.ekCalendar = AvailabilityViewController.createAvailabilityCalendar(eventStore: self.eventStore)
                }
            }
        }
    }

    override func viewDidLoad() {

        super.viewDidLoad()

        title = "Edit Availability"

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissAction))
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.backgroundColor = .clear
        navigationItem.largeTitleDisplayMode = .never
        navigationController?.toolbar.backgroundColor = .white

        toggleButton = UIBarButtonItem(title: "Show All", style: .plain, target: self, action: #selector(toggleAction))

        let todayButton = UIBarButtonItem(title: "Today", style: .plain, target: self, action: #selector(todayAction))
        let calendarsButton = UIBarButtonItem(title: "Calendars", style: .plain, target: self, action: #selector(calendarsAction))
        let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        let items: [UIBarButtonItem] = [
            todayButton,
            flex ,
            /*toggleButton,
            flex ,*/
            calendarsButton
        ]
        navigationController?.setToolbarHidden(false, animated: false)
        setToolbarItems(items, animated: false)

        self.ekCalendar = eventStore.defaultCalendarForNewEvents
        dayView.autoScrollToFirstEvent = true
        reloadData()
     }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        updateAvailability()
    }

    func updateAvailability() {

        if let calendar = self.ekCalendar {
            let cal = Calendar.current
            let today = cal.startOfDay(for: Date())
            let oneYearLater = Date(timeIntervalSinceNow: 365*24*3600)
            let predicate = eventStore.predicateForEvents(withStart: today, end: oneYearLater, calendars: [calendar])
            let ekEvents = eventStore.events(matching: predicate).sorted(by: { $0.startDate > $1.startDate })
            print("Events to sync")
            if !ekEvents.isEmpty {
                for ekEvent in ekEvents {
                    print(ekEvent)
                }
            }
        }
    }



    func toggle(show: Bool) {

         if let date = dayView.state?.selectedDate {

            if show { // From 9 - 17
                var startHour = 9.0*60.0*60.0
                for _ in 0...16 {
                    let duration = 30.0*60.0 //Int(arc4random_uniform(160) + 60)
                    let startDate = date.addingTimeInterval(startHour)
                    if startDate < Date() {
                        print("bail out")
                        return
                    }
                    let endDate = startDate.addingTimeInterval(duration)
                    let newEvent = EKEvent.init(eventStore: self.eventStore)
                    newEvent.startDate = startDate
                    newEvent.endDate = endDate
                    newEvent.title = "FREE"
                    newEvent.calendar = self.eventStore.defaultCalendarForNewEvents
                    print("default ", newEvent.calendar.title)
                    newEvent.structuredLocation = EKStructuredLocation(title: "messages")
                    do {
                        try self.eventStore.save(newEvent, span: .thisEvent, commit: true)
                        print("saved ", newEvent)
                    } catch {
                        print("ERROR: ", error)
                    }
                    startHour += 60.0*60.0/2.0
                }
            } else {
                if let calendar = self.ekCalendar {
                    let cal = Calendar.current
                    let today = cal.startOfDay(for: date)
                    let tomorrow = today.addingTimeInterval(24.0*3600.0)
                    let predicate = eventStore.predicateForEvents(withStart: today, end: tomorrow, calendars: [calendar])
                    let ekEvents  = eventStore.events(matching: predicate).sorted(by: { $0.startDate > $1.startDate })
                    if !ekEvents.isEmpty {
                        for ekEvent in ekEvents {
                            do {
                                try self.eventStore.remove(ekEvent, span: .thisEvent)
                            } catch {
                                print("ERROR: ", error)
                            }
                        }
                    }
                }
            }
            reloadData()
            dayView.scrollToFirstEventIfNeeded()
        }
    }

    @objc func dismissAction(sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }

    @objc func toggleAction(sender: UIBarButtonItem) {

        if sender.title == "Show All" {
            toggle(show: true)
            sender.title = "Hide All"
        } else {
            toggle(show: false)
            sender.title = "Show All"
        }
    }

    @objc func todayAction() {
        dayView.state?.move(to: Date())
    }

    @objc func calendarsAction() {
        calendarChooser = EKCalendarChooser(selectionStyle: .multiple, displayStyle: .allCalendars, entityType: .event, eventStore: eventStore)
        calendarChooser.showsDoneButton = true
        calendarChooser.showsCancelButton = true
        calendarChooser.navigationItem.title = "Select Calendars"
        calendarChooser.navigationItem.backBarButtonItem = nil
        calendarChooser.isEditing = true
        calendarChooser.delegate = self
        self.navigationController?.pushViewController(calendarChooser, animated: true)
    }

    @objc func startEditing() {
        calendarChooser.isEditing = true
        calendarChooser.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(endEditing))
    }

    @objc func endEditing() {
        _ = navigationController?.popViewController(animated: true)

        /*
        calendarChooser.isEditing = false
        calendarChooser.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(startEditing))*/
    }

  // MARK: EventDataSource
    override func eventsForDate(_ date: Date) -> [EventDescriptor] {

        print("eventsForDate(_ date: \(date))")
        if let calendar = self.ekCalendar {

            print(calendar.title)
            var events = [EventDescriptor]()
            let cal = Calendar.current
            let today = cal.startOfDay(for: date)
            let tomorrow = today.addingTimeInterval(24.0*3600.0)
            let predicate = eventStore.predicateForEvents(withStart: today, end: tomorrow, calendars: [calendar])

            let ekEvents = eventStore.events(matching: predicate).sorted(by: { $0.startDate > $1.startDate })

            if !ekEvents.isEmpty {
                for ekEvent in ekEvents {
                    let event = Event()
                    if ekEvent.startDate > Date() {
                        event.startDate = ekEvent.startDate
                        event.endDate = ekEvent.endDate
                        event.text = "FREE"
                        event.color = .green
                        event.userInfo = ekEvent.eventIdentifier
                        events.append(event)
                    }
                }
                return events
            }
        }
        return []
    }

  // MARK: DayViewDelegate

    override func dayViewDidSelectEventView(_ eventView: EventView) {
        guard let descriptor = eventView.descriptor as? Event else {
            return
        }
        descriptor.backgroundColor = .red
        //print("Event has been selected: \(descriptor) \(String(describing: descriptor.userInfo))", descriptor.userInfo)

        if let identifier = descriptor.userInfo as? String, let ekEvent = self.eventStore.event(withIdentifier: identifier) {
            do {
                try self.eventStore.remove(ekEvent, span: .thisEvent)
                reloadData()
            } catch {
                print("ERROR: ", error)
            }
        }
    }
    // FIXME override?
    func dayViewDidLongPressTimelineAtHalfHour(_ halfhour: Int) {

        if let date = dayView.state?.selectedDate {

            let startHour = Double(halfhour)*60.0*60.0/2.0
            print("half hour", Double(halfhour)/2.0, "startHour ", startHour)
            let duration = 30.0*60.0 //Int(arc4random_uniform(160) + 60)
            let startDate = date.addingTimeInterval(startHour)
            if startDate < Date() {
                print("bail out")
                return
            }
            let endDate = startDate.addingTimeInterval(duration)
            let newEvent = EKEvent.init(eventStore: self.eventStore)
            newEvent.startDate = startDate
            newEvent.endDate = endDate
            newEvent.title = "FREE"
            newEvent.calendar = self.eventStore.defaultCalendarForNewEvents
            print("default ", newEvent.calendar.title)
            newEvent.structuredLocation = EKStructuredLocation(title: "messages")
            do {
                try self.eventStore.save(newEvent, span: .thisEvent, commit: true)
                print("saved ", newEvent)
            } catch {
                print("ERROR: ", error)
            }
            reloadData()
        }
    }

    override func dayViewDidLongPressEventView(_ eventView: EventView) {
        guard let descriptor = eventView.descriptor as? Event else {
            return
        }
        //descriptor.color = .red
        print("Event has been longPressed: \(descriptor) \(String(describing: descriptor.userInfo))")
    }

    override func dayView(dayView: DayView, willMoveTo date: Date) {
        toggleButton.title = "Show All"
        //print("DayView = \(dayView) will move to: \(date)")
    }
  
    override func dayView(dayView: DayView, didMoveTo date: Date) {
        //print("DayView = \(dayView) did move to: \(date)")
    }
}

extension AvailabilityViewController: EKCalendarChooserDelegate {

    func calendarChooserDidFinish(_ calendarChooser: EKCalendarChooser) {
        _ = self.navigationController?.popViewController(animated: true)
         print(calendarChooser.selectedCalendars)
    }

    func calendarChooserDidCancel(_ calendarChooser: EKCalendarChooser) {
        _ = self.navigationController?.popViewController(animated: true)
         print(calendarChooser.selectedCalendars)
    }

    func calendarChooserSelectionDidChange(_ calendarChooser: EKCalendarChooser) {
         print(calendarChooser.selectedCalendars)

    }
}
