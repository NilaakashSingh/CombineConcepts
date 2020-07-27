import SwiftUI
import Combine

var str = "Hello, playground"
private let basicNotification = Notification.Name("basicNotification")
let stringArray = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L"]

/*********************** Basic notifications and publisher way ***********************/

// MARK: - Basic notifications and publisher way
private func basicNotificationImplementation() {
    let center = NotificationCenter.default
    let observer = center.addObserver(forName: basicNotification, object: nil, queue: nil) { notification in
        print("BasicNotificationImplementation Notification recieved \(notification)")
    }
    center.post(Notification(name: basicNotification))
    center.removeObserver(observer)
}

private func basicNotificationImplementationWithCombine() {
    let publisher = NotificationCenter.default.publisher(for: basicNotification)
    let subscription = publisher.sink { (notification) in
        print("BasicNotificationImplementationWithCombine Notification recieved \(notification)")
    }
    NotificationCenter.default.post(Notification(name: basicNotification))
    subscription.cancel()
}

/*********************** Publishers, Subscribers and Subjects basic ***********************/

// MARK: - String Subscriber class
class StringSubscriber: Subscriber {
    
    typealias Input = String
    typealias Failure = Never
    
    func receive(subscription: Subscription) {
        print("Received Subscription")
        subscription.request(.max(2)) // backpressure
    }
    
    func receive(_ input: String) -> Subscribers.Demand {
        print("Received Value", input)
        return .max(2)
    }
    
    func receive(completion: Subscribers.Completion<Never>) {
        print("Completed")
    }
}

// MARK: - Creating Subscriber
private func creatingSubscriber() {
    let publisher = stringArray.publisher
    let subscriber = StringSubscriber()
    publisher.subscribe(subscriber)
}

// MARK: - Creating subjects
private func creatingSubjects() {
    
    // Subjects are both publisher and subscribers
    let subscriber = StringSubscriber()
    let subject = PassthroughSubject<String,Never>()
    
    // Subject acting as subscriber
    subject.subscribe(subscriber)
    
    // Subject acting as publisher
    let subscription = subject.sink { (value) in
        print("Received value from sink", value)
    }
    
    // Sending data
    subject.send("A")
    subject.send("B")
    subscription.cancel()
    subject.send("C")
    subject.send("D")
    
    // Type erasers
    let subject1 = PassthroughSubject<String,Never>().eraseToAnyPublisher()
}

/*********************** Transforming Operators ***********************/

// MARK: - Transforming Operators

/// Collect operator
func collectOperator() {
    stringArray.publisher.collect().sink { print($0) }
    stringArray.publisher.collect(2).sink { print($0) }
}

/// Map / Transformation operator
func mapOperator() {
    let numberArray = [123, 45, 67, 98, 009]
    let formatter = NumberFormatter()
    formatter.numberStyle = .spellOut
    numberArray.publisher.map {
        formatter.string(from: NSNumber.init(value: $0))
    }.sink { print($0 ?? "") }
}

/// Map Key Path - Used to map individual element in keypath
struct Point {
    let x: Int
    let y: Int
}

func mapKeyPath() {
    let publisher = PassthroughSubject<Point, Never>()
    publisher.map(\.x, \.y).sink { (x, y) in
        print("x is \(x) and y is \(y)")
    }
    publisher.send(Point(x: 2, y: 10))
}

/// FlatMap - Used to combine upstream publishers to single down stream publisher
struct Office {
    let name: String
    let numberOfEmployee: CurrentValueSubject<Int, Never>
    
    init(name: String, numberOfEmployee: Int) {
        self.name = name
        self.numberOfEmployee = CurrentValueSubject(numberOfEmployee)
    }
}

func flatmap() {
    let villageOffice = Office(name: "My Office", numberOfEmployee: 20)
    let townOffice = Office(name: "My new office", numberOfEmployee: 1000)
    let office = CurrentValueSubject<Office, Never>(villageOffice)
    
    office
        .flatMap { $0.numberOfEmployee }
        .sink{ print($0) }
    office.value = townOffice
    townOffice.numberOfEmployee.value += 1200
    villageOffice.numberOfEmployee.value += 1000
}


/// Replace nil
func replaceNil() {
    ["A", "B", nil, "C"].publisher.replaceNil(with: "*").sink { print($0!) }
}

/// Replace empty
func replaceEmpty() {
    let empty = Empty<Int, Never>()
    empty
        .replaceEmpty(with: 2)
        .sink(receiveCompletion: { print($0) }, receiveValue: { print($0) })
}

/// Scan
func scan() {
    let numberSequence = (1...10)
    numberSequence.publisher.scan([]) { number, value -> [Int] in
        number + [value]
    }.sink { print($0) }
}

/*********************** Filtering Operators ***********************/

// MARK: - Filtering Operators
/// Filter
func filter() {
    let numbers = (1...20).publisher
    numbers
        .filter { $0 % 2 == 0 }
        .sink { print($0) }
}

/// Remove Duplicates
func removeDuplicates() {
    let cartoonArray = "Pokemon Pikachu Pikachu Pokemon Pokemon Squirtle Charmender Pikachu Pokemon".components(separatedBy: " ")
    cartoonArray.publisher.removeDuplicates().sink { print($0) }
}

/// Compact Map: Works exactly as swift
func compactMap() {
    let array = ["9999", "nine", "ten", "100", "20", "60", "90"].publisher.compactMap { Int($0) }
    array.sink{ print($0) }
}

/// Ignore Output
func ignoreOutput() {
    let numbers = (1...1000).publisher
    numbers
        .ignoreOutput()
        .sink(receiveCompletion: { print($0) }, receiveValue: { print($0) })
}

/// First and last
func firstLast() {
    let numbers = (1...100).publisher
    numbers
        .first()
        .sink(receiveValue: { print($0) }) // We can also use first where
    
    numbers
        .last()
        .sink(receiveValue: { print($0) }) // We can also use last where
}

/// Drop
func drop() {
    let numbers = (1...10)
    
    // Drop First
    numbers
        .publisher
        .dropFirst(2)
        .sink { print("Drop", $0) }
    
    // Drop while
    numbers
        .publisher
        .drop(while: { $0 % 4 != 0 })
        .sink(receiveValue: {
            print("Drop While", $0)
        })
    
    // Drop Until Output from
    let stoppingSubscriber = PassthroughSubject<Void, Never>()
    let dropSubscriber = PassthroughSubject<Int, Never>()
    dropSubscriber
        .drop(untilOutputFrom: stoppingSubscriber)
        .sink(receiveValue: { print("Drop until output from", $0) })
    numbers.forEach { (n) in
        if n == 6 {
            stoppingSubscriber.send()
        }
        dropSubscriber.send(n)
    }
}

/// Prefix
func prefix() {
    let numbers = (1...10).publisher
    numbers
        .prefix(3)
        .sink(receiveValue: { print($0) })
}

/*********************** Combining Operators ***********************/

// MARK: - Combining Operators
/// Prepend
func prepend() {
    let numbers = (7...10).publisher
    let negativeNumbers = (-10...0).publisher
    
    numbers
        .prepend([5,6])
        .prepend(2...4)
        .prepend(1)
        .prepend(negativeNumbers)
        .sink { print($0) }
}

/// Append()
func append() {
    let numbers = [-10,-9].publisher
    let negativeNumbers = (-8...0).publisher
    
    numbers
        .append(negativeNumbers)
        .append(1)
        .append(2...8)
        .append([9,10])
        .sink { print($0) }
}

/// Switch to latest
func switchToLatest() {
    let publisher1 = PassthroughSubject<String, Never>()
    let publisher2 = PassthroughSubject<String, Never>()
    let publishers = PassthroughSubject<PassthroughSubject<String, Never>,Never>()
    publishers.switchToLatest().sink { print($0) }

    publishers.send(publisher1)
    publisher1.send("Publisher 1 - Value 1")
    publisher1.send("Publisher 1 - Value 2")

    publishers.send(publisher2) // switching to publisher 2
    publisher2.send("Publisher 2 - Value 1")
    publisher1.send("Publisher 1 - Value 3")
}

/// Merge
func merge() {
    let publisher1 = PassthroughSubject<Int, Never>()
    let publisher2 = PassthroughSubject<Int, Never>()
    publisher1
        .merge(with: publisher2)
        .sink(receiveValue: { print($0) })
    publisher1.send(20)
    publisher2.send(30)
}

/// CombineLatest
func combineLatest() {
    let publisher1 = PassthroughSubject<Int, Never>()
    let publisher2 = PassthroughSubject<String, Never>()
    publisher1.combineLatest(publisher2).sink {
        print("Publisher 1 value is \($0) and Publisher 2 value is \($1)")
    }
    publisher1.send(1)
    publisher2.send("One")
    publisher1.send(2)
    publisher2.send("Two")
}

/// Zip
func zip() {
    let publisher1 = PassthroughSubject<Int, Never>()
    let publisher2 = PassthroughSubject<String, Never>()
    publisher1.zip(publisher2).sink {
        print("Publisher 1 value is \($0) and Publisher 2 value is \($1)")
    }
    publisher1.send(1)
    publisher2.send("One")
    publisher1.send(2)
    publisher2.send("Two")
}

/*********************** Sequence Operators ***********************/
