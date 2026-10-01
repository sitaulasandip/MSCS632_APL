"Ride Sharing System in Pharo Smalltalk 12 (file-in/chunk format).
Run headless:  PharoConsole --headless Pharo.image st --quit RideSharing.st
Or in the Pharo IDE: drag this file onto the window and choose 'File in entire file'."!

Error subclass: #RideSharingError
	instanceVariableNames: ''
	classVariableNames: ''
	package: 'RideSharing'!

Object subclass: #Ride
	instanceVariableNames: 'rideID pickupLocation dropoffLocation distance'
	classVariableNames: ''
	package: 'RideSharing'!

Ride comment: 'Base ride: holds trip details and provides a default per-mile fare.'!

!Ride class methodsFor: 'instance creation'!
id: anId from: pickup to: dropoff miles: miles
	miles > 0 ifFalse: [
		^RideSharingError signal: 'Ride ', anId, ': distance must be positive.'].
	^self new setId: anId from: pickup to: dropoff miles: miles
! !

!Ride class methodsFor: 'formatting'!
fixed: aNumber
	"Answer aNumber with two decimals, e.g. 4.9 -> '4.90'."
	| cents |
	cents := (aNumber * 100) rounded.
	^(cents // 100) printString, '.', ((cents \\ 100) printPaddedWith: $0 to: 2)
!
money: anAmount
	^'$', (self fixed: anAmount)
!
pad: aString to: width
	^aString, (String new: (width - aString size max: 0) withAll: $ )
!
padLeft: aString to: width
	^(String new: (width - aString size max: 0) withAll: $ ), aString
!
line: aString
	Transcript show: aString; cr
! !

!Ride methodsFor: 'private'!
setId: anId from: pickup to: dropoff miles: miles
	rideID := anId.
	pickupLocation := pickup.
	dropoffLocation := dropoff.
	distance := miles
! !

!Ride methodsFor: 'accessing'!
rideID
	^rideID
!
distance
	^distance
!
rideType
	^'Basic'
! !

!Ride methodsFor: 'pricing'!
fare
	^2.50 + (1.00 * distance)
! !

!Ride methodsFor: 'printing'!
rideDetails
	Ride
		line: '  [', self rideType, '] ', rideID, '  ', pickupLocation, ' -> ', dropoffLocation;
		line: '    Distance: ', distance printString, ' mi   Fare: ', (Ride money: self fare)
! !

Ride subclass: #StandardRide
	instanceVariableNames: ''
	classVariableNames: ''
	package: 'RideSharing'!

StandardRide comment: 'Everyday ride: higher base and per-mile rate than the generic ride.'!

!StandardRide methodsFor: 'accessing'!
rideType
	^'Standard'
! !

!StandardRide methodsFor: 'pricing'!
fare
	^3.00 + (1.50 * distance)
! !

Ride subclass: #PremiumRide
	instanceVariableNames: 'vehicle'
	classVariableNames: ''
	package: 'RideSharing'!

PremiumRide comment: 'Luxury ride: premium per-mile rate with a minimum fare.'!

!PremiumRide class methodsFor: 'instance creation'!
id: anId from: pickup to: dropoff miles: miles vehicle: aString
	^(self id: anId from: pickup to: dropoff miles: miles) setVehicle: aString
! !

!PremiumRide methodsFor: 'private'!
setVehicle: aString
	vehicle := aString
! !

!PremiumRide methodsFor: 'accessing'!
rideType
	^'Premium'
! !

!PremiumRide methodsFor: 'pricing'!
fare
	^(5.00 + (2.75 * distance)) max: 15.00
! !

!PremiumRide methodsFor: 'printing'!
rideDetails
	super rideDetails.
	Ride line: '    Vehicle: ', vehicle, ' (minimum fare ', (Ride money: 15.00), ')'
! !

StandardRide subclass: #SharedRide
	instanceVariableNames: 'passengers'
	classVariableNames: ''
	package: 'RideSharing'!

SharedRide comment: 'Pooled ride: a Standard ride discounted 40% because passengers share the car.'!

!SharedRide class methodsFor: 'instance creation'!
id: anId from: pickup to: dropoff miles: miles passengers: count
	count >= 2 ifFalse: [
		^RideSharingError signal: 'A shared ride needs at least 2 passengers.'].
	^(self id: anId from: pickup to: dropoff miles: miles) setPassengers: count
! !

!SharedRide methodsFor: 'private'!
setPassengers: count
	passengers := count
! !

!SharedRide methodsFor: 'accessing'!
rideType
	^'Shared'
! !

!SharedRide methodsFor: 'pricing'!
fare
	^super fare * 0.60
! !

!SharedRide methodsFor: 'printing'!
rideDetails
	super rideDetails.
	Ride line: '    Pool: ', passengers printString, ' passengers (40% off Standard)'
! !

Object subclass: #Driver
	instanceVariableNames: 'driverID name rating ratingCount assignedRides'
	classVariableNames: ''
	package: 'RideSharing'!

Driver comment: 'Driver whose ride list and rating can change only through its methods.'!

!Driver class methodsFor: 'instance creation'!
id: anId name: aName rating: aRating
	(aRating between: 0 and: 5) ifFalse: [
		^RideSharingError signal: 'Rating must be between 0 and 5.'].
	^self new setId: anId name: aName rating: aRating
! !

!Driver methodsFor: 'private'!
setId: anId name: aName rating: aRating
	driverID := anId.
	name := aName.
	rating := aRating.
	ratingCount := 1.
	assignedRides := OrderedCollection new
! !

!Driver methodsFor: 'accessing'!
name
	^name
!
rideCount
	^assignedRides size
!
totalEarnings
	^assignedRides inject: 0 into: [:sum :ride | sum + ride fare]
! !

!Driver methodsFor: 'rides'!
addRide: aRide
	aRide ifNil: [^RideSharingError signal: 'Cannot assign an empty ride.'].
	assignedRides add: aRide
!
rateTrip: stars
	"Fold a 1-5 star trip rating into the running average."
	(stars between: 1 and: 5) ifFalse: [
		^RideSharingError signal: 'Trip rating must be 1-5 stars.'].
	rating := ((rating * ratingCount) + stars) / (ratingCount + 1).
	ratingCount := ratingCount + 1
! !

!Driver methodsFor: 'printing'!
getDriverInfo
	Ride
		line: 'Driver ', driverID, ': ', name;
		line: '  Rating: ', (Ride fixed: rating), '   Rides: ', self rideCount printString,
			'   Earnings: ', (Ride money: self totalEarnings).
	assignedRides do: [:ride | ride rideDetails]
! !

Object subclass: #Rider
	instanceVariableNames: 'riderID name requestedRides'
	classVariableNames: ''
	package: 'RideSharing'!

Rider comment: 'Rider whose requested-ride history is private to the object.'!

!Rider class methodsFor: 'instance creation'!
id: anId name: aName
	^self new setId: anId name: aName
! !

!Rider methodsFor: 'private'!
setId: anId name: aName
	riderID := anId.
	name := aName.
	requestedRides := OrderedCollection new
! !

!Rider methodsFor: 'rides'!
requestRide: aRide
	aRide ifNil: [^RideSharingError signal: 'Cannot request an empty ride.'].
	requestedRides add: aRide
!
totalSpent
	^requestedRides inject: 0 into: [:sum :ride | sum + ride fare]
! !

!Rider methodsFor: 'printing'!
viewRides
	Ride line: 'Rider ', riderID, ': ', name, ' - ', requestedRides size printString,
		' ride(s), total spent ', (Ride money: self totalSpent).
	requestedRides do: [:ride | ride rideDetails]
! !

| dana eli alex sam rides book total heading |
dana := Driver id: 'D-01' name: 'Dana Lopez' rating: 4.90.
eli := Driver id: 'D-02' name: 'Eli Brooks' rating: 4.60.
alex := Rider id: 'U-101' name: 'Alex Kim'.
sam := Rider id: 'U-102' name: 'Sam Patel'.

"Record a booking on both the rider and the driver, and in the system-wide list."
rides := OrderedCollection new.
book := [:ride :rider :driver |
	rider requestRide: ride.
	driver addRide: ride.
	rides add: ride].
heading := [:title | Ride line: ''; line: '=== ', title, ' ==='].

book value: (StandardRide id: 'R-1001' from: 'Union Station' to: 'Midtown' miles: 4.2)
	value: alex value: dana.
book value: (PremiumRide id: 'R-1002' from: 'Airport' to: 'Grand Hotel' miles: 12.0
		vehicle: 'Luxury Sedan')
	value: alex value: eli.
book value: (SharedRide id: 'R-1003' from: 'University' to: 'Tech Park' miles: 8.0
		passengers: 3)
	value: sam value: dana.
book value: (PremiumRide id: 'R-1004' from: 'Museum' to: 'Riverwalk' miles: 2.0 vehicle: 'SUV')
	value: sam value: eli.
book value: (Ride id: 'R-1005' from: 'Library' to: 'City Hall' miles: 1.5)
	value: alex value: dana.

heading value: 'Polymorphism: rideDetails on a mixed list'.
rides do: [:ride | ride rideDetails].

heading value: 'Polymorphism: fare on a mixed list'.
total := 0.
rides do: [:ride |
	total := total + ride fare.
	Ride line: '  ', (Ride pad: ride rideID to: 8), (Ride pad: ride rideType to: 10),
		(Ride padLeft: (Ride money: ride fare) to: 10)].
Ride line: '  ', (Ride pad: 'Total' to: 18), (Ride padLeft: (Ride money: total) to: 10).

heading value: 'Riders'.
alex viewRides.
sam viewRides.

dana rateTrip: 5.
eli rateTrip: 4.
heading value: 'Drivers (after trip ratings)'.
dana getDriverInfo.
eli getDriverInfo.

heading value: 'Validation'.
[Ride id: 'R-BAD' from: 'Nowhere' to: 'Nowhere' miles: 0]
	on: RideSharingError do: [:e | Ride line: '  Rejected: ', e messageText].
[dana rateTrip: 7]
	on: RideSharingError do: [:e | Ride line: '  Rejected: ', e messageText].
"Encapsulation: there is no accessor for assignedRides, so asking for it fails."
[dana assignedRides]
	on: MessageNotUnderstood do: [:e |
		Ride line: '  Blocked: Driver does not understand ',
			e message selector printString, ' - rides are private'.
		e return: nil].
Ride line: '  ', dana name, '''s rides are reachable only through Driver methods (',
	dana rideCount printString, ' assigned).'.
Transcript flush!
