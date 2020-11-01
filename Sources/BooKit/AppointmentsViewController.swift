//
//  AppointmentsViewController.swift
//  Messages
//
//  Created by Johan Sellström on 2020-10-28.
//

import UIKit
import EventKit
import EventKitUI

struct CalendarConfig {

    struct Keys {
        static let appointmentsIdentifier = "appointmentsIdentifier"
        static let availabilityIdentifier = "availabilityIdentifier"
    }

    static let current: CalendarConfig = CalendarConfig()

    let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public var appointmentsIdentifier: String? {
        get {
            let k = defaults.string(forKey: Keys.appointmentsIdentifier)
            guard k != nil  else { return nil }
            return k
        }
        set { defaults.set(newValue, forKey: Keys.appointmentsIdentifier) }
    }

    public var availabilityIdentifier: String? {
        get {
            let k = defaults.string(forKey: Keys.availabilityIdentifier)
            guard k != nil  else { return nil }
            return k
        }
        set { defaults.set(newValue, forKey: Keys.availabilityIdentifier) }
    }
}

open class EventCell: UITableViewCell {

    // MARK: - Properties
    let startLabel = UILabel()
    let endLabel = UILabel()
    let titleLabel = UILabel()
    let subtitleLabel = UILabel()
    let verticalBar = UIView()

    var event: EKEvent? {
        didSet {
            if let event = event {
                startLabel.text = asClock(date: event.startDate)
                endLabel.text   = asClock(date: event.endDate)
                titleLabel.text = event.title
                subtitleLabel.text = event.location
           }
        }
    }

    func asClock(date: Date) -> String {
        let calendar = Calendar.current
        let hours = String(format: "%02d", calendar.component(.hour, from: date))
        let minutes = String(format: "%02d", calendar.component(.minute, from: date))
        return hours + ":" + minutes
    }

    //
    open class var reuseIdentifier: String {
        return "EventCell"
    }

    // MARK: - Initialization

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    // MARK: - Setup

    private func setup() {
        setupSubviews()
        setupConstraints()
        selectionStyle = .none
    }

    open func setupSubviews() {
        addSubview(startLabel)
        addSubview(endLabel)
        addSubview(titleLabel)
        addSubview(subtitleLabel)
        addSubview(verticalBar)
    }

    open func setupConstraints() {

        startLabel.font = UIFont.systemFont(ofSize: 14)
        endLabel.font = UIFont.systemFont(ofSize: 14)
        titleLabel.font = UIFont.systemFont(ofSize: 20)
        endLabel.textColor = .gray
        subtitleLabel.textColor = .gray

        startLabel.translatesAutoresizingMaskIntoConstraints = false
        startLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16).isActive = true
        startLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: 12).isActive = true

        endLabel.translatesAutoresizingMaskIntoConstraints = false
        endLabel.topAnchor.constraint(equalTo: startLabel.bottomAnchor, constant: 6).isActive = true
        endLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: 12).isActive = true


        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.centerYAnchor.constraint(equalTo: startLabel.centerYAnchor, constant: 0).isActive = true
        titleLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: 72).isActive = true

        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.centerYAnchor.constraint(equalTo: endLabel.centerYAnchor, constant: 0).isActive = true
        subtitleLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: 72).isActive = true

        if  let cgColor = event?.calendar.cgColor {
            verticalBar.backgroundColor = UIColor(cgColor: cgColor)
        } else {
            verticalBar.backgroundColor = .purple
        }

        verticalBar.translatesAutoresizingMaskIntoConstraints = false
        verticalBar.topAnchor.constraint(equalTo: topAnchor, constant: 1).isActive = true
        verticalBar.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -1).isActive = true
        verticalBar.widthAnchor.constraint(equalToConstant: 0.5).isActive = true
        verticalBar.leftAnchor.constraint(equalTo: leftAnchor, constant: 62).isActive = true
    }

}

class AppointmentsViewController: UITableViewController, EKEventEditViewDelegate {


    let eventStore = EKEventStore()
    var groupedEvents = [Date: [EKEvent]]()
    let editEventViewController = EKEventEditViewController()
    var calendar: EKCalendar!
    var config = CalendarConfig()

    func eventEditViewControllerDefaultCalendar(forNewEvents controller: EKEventEditViewController) -> EKCalendar {
        return calendar
    }

    func eventEditViewController(_ controller: EKEventEditViewController, didCompleteWith action: EKEventEditViewAction) {
        print("eventEditViewController(_ controller: \(controller), didCompleteWith: \(action)) ")
        print("action ", action)
        controller.dismiss(animated: true, completion: nil)
    }


     func reload() {

        if let calendar = self.calendar {
            let oneYearAfter = Date(timeIntervalSinceNow: 365*24*3600)
            let predicate = eventStore.predicateForEvents(withStart: Date(), end: oneYearAfter, calendars: [calendar])
            var events = eventStore.events(matching: predicate).sorted(by: { $0.startDate > $1.startDate })
            let cal = Calendar.current

            let event = EKEvent(eventStore: eventStore)
            event.startDate = Date()
            event.endDate = Date()
            event.title = "test"
            event.location = nil
            print("event \(event)")
            events.append(event)
            groupedEvents = Dictionary(grouping: events, by: { cal.startOfDay(for: $0.startDate) })
        } else {
            print("ERROR: No Calendar")
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
                self.calendar = AvailabilityViewController.createAvailabilityCalendar(eventStore: self.eventStore)
            } else if accessGranted, let identifier = config.appointmentsCalendarIdentifier {
                self.calendar = self.eventStore.calendar(withIdentifier: identifier)
                
                if self.calendar == nil {
                    self.calendar = AvailabilityViewController.createAvailabilityCalendar(eventStore: self.eventStore)
                }

                print("calendar \(self.calendar)")
            }
        }
    }

    static func createAppointmentCalendar(eventStore: EKEventStore) -> EKCalendar? {
        var config = CalendarConfig()
        let calendar = EKCalendar(for: .event, eventStore: eventStore)
        do {
            if eventStore.sources.count == 0 { // reproducible after Reset Content and Settings
                calendar.source = EKSource()
            } else if let defaultCalendar = eventStore.defaultCalendarForNewEvents {
                calendar.source = defaultCalendar.source
            }
            calendar.title = "Appointments"
            try eventStore.saveCalendar(calendar, commit: true)
            config.appointmentsIdentifier = calendar.calendarIdentifier
            return calendar
        } catch {
            print("ERROR: Can not save calendar", error)
            return nil
        }
    }

    /*
    static func pickAvailabilityCalendar(eventStore: EKEventStore) -> EKCalendar? {

        let controller = AppointmentsViewController()
        controller.availabilityAction()

        var config = CalendarConfig()
        let calendar = EKCalendar(for: .event, eventStore: eventStore)
        do {
            if eventStore.sources.count == 0 { // reproducible after Reset Content and Settings
                calendar.source = EKSource()
            } else if let defaultCalendar = eventStore.defaultCalendarForNewEvents {
                calendar.source = defaultCalendar.source
            }
            calendar.title = "Availability"
            try eventStore.saveCalendar(calendar, commit: true)
            config.availabilityIdentifier = calendar.calendarIdentifier
            return calendar
        } catch {
            print("ERROR: Can not save calendar", error)
            return nil
        }

    }
   */

    override func viewDidLoad() {
        super.viewDidLoad()
        //hidesBottomBarWhenPushed = true
        //self.config.identifier = nil
        title = "Appointments"
        navigationItem.largeTitleDisplayMode = .never
        tableView.register(EventCell.self, forCellReuseIdentifier: EventCell.reuseIdentifier)
        tableView.delegate = self
        tableView.dataSource = self
        self.eventStore.requestAccess(to: EKEntityType.event) {
            (accessGranted: Bool, error: Error?) in
            if accessGranted, let identifier = self.config.appointmentsIdentifier {
               // self.calendar = self.eventStore.calendar(withIdentifier: identifier)

                self.calendar = self.eventStore
                    .calendars(for: .event)
                    .first(where: { $0.calendarIdentifier == identifier })

                if self.calendar == nil {
                    self.calendar = AppointmentsViewController.createAppointmentCalendar(eventStore: self.eventStore)
                } else {
                    self.reload()
                }
            } else if accessGranted {
                self.calendar = AppointmentsViewController.createAppointmentCalendar(eventStore: self.eventStore)
            }
        }

        editEventViewController.editViewDelegate = self
        editEventViewController.eventStore = self.eventStore

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addAction))
        let availabilityButton = UIBarButtonItem(title: "Set Availability", style: .plain, target: self, action: #selector(availabilityAction))
        //let addButton = UIBarButtonItem(title: "Add Appointment", style: .plain, target: self, action: #selector(addAction))
        let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        let items: [UIBarButtonItem] = [
            availabilityButton,
            flex
            /*,
            addButton*/
        ]

        navigationController?.setToolbarHidden(false, animated: false)
        setToolbarItems(items, animated: false)
    }

    func nonLocalCalendars() -> [EKCalendar] {

        var nonLocalCalendars = [EKCalendar]()
        let allCalendars = eventStore.calendars(for: .event)
        print("allCalendars")
        for calendar in allCalendars {
            print(calendar)
            print(calendar.type.rawValue, calendar.source.sourceType)
            // webcal://p13-calendars.icloud.com/published/2/MTkyMjcxODczOTE5MjI3Me-NC01E0si70dpZ7rEQ3TQUugqpkS2r0R_8fREETvBKdgwpc8mqoBdIWAaiH5TIyjvvgF0PQ11gte0oTToQBV8

            if (calendar.type == .calDAV ||  calendar.type == .exchange) && calendar.allowsContentModifications {
                print("calendar debug ", calendar.debugDescription)
                if let source = calendar.source {
                    print("calendar identifier ", calendar.calendarIdentifier)
                    let identifier = source.sourceIdentifier
                    print("source identifier ", identifier)
                }

                nonLocalCalendars.append(calendar)
            }
        }
        return nonLocalCalendars
    }

    @objc func availabilityAction() {

        let controller = AvailabilityViewController()
        //controller.hidesBottomBarWhenPushed = true
        if !nonLocalCalendars().isEmpty, let identifier = config.availabilityIdentifier {
            controller.ekCalendar = self.eventStore.calendar(withIdentifier: identifier)
            navigationController?.pushViewController(controller, animated: true)
        } else {
            let calendarChooser = EKCalendarChooser(selectionStyle: .single, displayStyle: .writableCalendarsOnly, entityType: .event, eventStore: eventStore)
            calendarChooser.showsDoneButton = true
            calendarChooser.showsCancelButton = true
            calendarChooser.navigationItem.title = "Select Availability Calendar"
            calendarChooser.navigationItem.backBarButtonItem = nil
            calendarChooser.isEditing = true
            calendarChooser.delegate = self
            self.navigationController?.pushViewController(calendarChooser, animated: true)
        }
    }

    @objc func addAction() {
        let event = EKEvent.init(eventStore: self.eventStore)
        event.title = ""
        event.calendar = self.calendar
        editEventViewController.event = event
        present(editEventViewController, animated: true, completion: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //navigationController?.setToolbarHidden(true, animated: true)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        //navigationController?.setToolbarHidden(false, animated: true)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        reload()
        tableView.reloadData()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
         return groupedEvents.keys.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let keys = Array(groupedEvents.keys)
        let key = keys[section]
        if let events = groupedEvents[key] {
            return events.count
        }
        return 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: EventCell.reuseIdentifier, for: indexPath) as! EventCell
        let keys = Array(groupedEvents.keys)
        let key = keys[indexPath.section]
        if let events = groupedEvents[key] {
            let event = events[indexPath.row]
            cell.event = event
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let keys = Array(groupedEvents.keys)
        let key = keys[section] as Date
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US")
        dateFormatter.setLocalizedDateFormatFromTemplate("MMMd") // set template after setting locale
        let str = dateFormatter.string(from: key)
        return str
    }

    override func tableView(_ tableView: UITableView,
                            heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 66.0
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let keys = Array(groupedEvents.keys)
        let key = keys[indexPath.section]
        if let events = groupedEvents[key] {
            editEventViewController.event = events[indexPath.row]
            print("event ", events[indexPath.row])
            present(editEventViewController, animated: true, completion: nil)
        } else {
            print("ERROR no events")
        }
    }
}



extension AppointmentsViewController: EKCalendarChooserDelegate {

    func calendarChooserDidFinish(_ calendarChooser: EKCalendarChooser) {
        _ = self.navigationController?.popViewController(animated: true)
        print(calendarChooser.selectedCalendars)
        if let calendar = Array(calendarChooser.selectedCalendars).first {
            print("calendar ", calendar, "calendar.source.sourceIdentifier", calendar.source.sourceIdentifier)
            if (calendar.type != .calDAV && calendar.type != .exchange) || !calendar.allowsContentModifications {

                print("ALERT")

                let bundle = Bundle(for: self.classForCoder)
                let image = UIImage(named: "offline", in: bundle, compatibleWith: nil)

                let alertVC = UIAlertController(title: "Error", message: "You must pick or add a public calendar that is not local to your phone, f.i an iCloud, Google or Exchange Calendar that you can modify", preferredStyle: .alert)

                alertVC.addAction(
                    UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
                        print("cancel")
                    })
                )


                alertVC.addAction(
                    UIAlertAction(title: "Try Again", style: .default, handler: { (action) in
                        self.availabilityAction()
                    })
                )

                self.present(alertVC, animated: true, completion: nil)
            } else {
                config.availabilityIdentifier = calendar.calendarIdentifier
                self.availabilityAction()
            }
        } else {
            print("ALERT pls add a new calendar")
        }
    }

    func calendarChooserDidCancel(_ calendarChooser: EKCalendarChooser) {
        _ = self.navigationController?.popViewController(animated: true)
    }

    func calendarChooserSelectionDidChange(_ calendarChooser: EKCalendarChooser) {
        //print(calendarChooser.selectedCalendars)
        //let calendar = Array(calendarChooser.selectedCalendars).first
    }
}
