#include <iomanip>
#include <iostream>
#include <memory>
#include <sstream>
#include <stdexcept>
#include <string>
#include <utility>
#include <vector>

/** Formats a number with two decimals without touching std::cout's settings. */
std::string fixed2(double value) {
    std::ostringstream out;
    out << std::fixed << std::setprecision(2) << value;
    return out.str();
}

/** Formats a dollar amount, e.g. 12.5 -> "$12.50". */
std::string money(double amount) { return "$" + fixed2(amount); }

/** Base ride: holds trip details privately and provides a default per-mile fare. */
class Ride {
public:
    Ride(std::string id, std::string pickup, std::string dropoff, double miles)
        : rideID(std::move(id)), pickupLocation(std::move(pickup)),
          dropoffLocation(std::move(dropoff)), distance(miles) {
        if (miles <= 0) {
            throw std::invalid_argument("Ride " + rideID + ": distance must be positive.");
        }
    }
    virtual ~Ride() = default;

    virtual double fare() const { return 2.50 + 1.00 * distance; }
    virtual std::string rideType() const { return "Basic"; }

    virtual void rideDetails(std::ostream& out = std::cout) const {
        out << "  [" << rideType() << "] " << rideID << "  "
            << pickupLocation << " -> " << dropoffLocation << '\n'
            << "    Distance: " << distance << " mi   Fare: " << money(fare()) << '\n';
    }

    const std::string& getRideID() const { return rideID; }
    double getDistance() const { return distance; }

private:
    std::string rideID;
    std::string pickupLocation;
    std::string dropoffLocation;
    double distance;
};

/** Everyday ride: higher base and per-mile rate than the generic ride. */
class StandardRide : public Ride {
public:
    using Ride::Ride;

    double fare() const override { return 3.00 + 1.50 * getDistance(); }
    std::string rideType() const override { return "Standard"; }
};

/** Luxury ride: premium per-mile rate with a minimum fare. */
class PremiumRide : public Ride {
public:
    PremiumRide(std::string id, std::string pickup, std::string dropoff, double miles,
                std::string vehicleClass)
        : Ride(std::move(id), std::move(pickup), std::move(dropoff), miles),
          vehicle(std::move(vehicleClass)) { }

    double fare() const override {
        constexpr double minimumFare = 15.00;
        double computed = 5.00 + 2.75 * getDistance();
        return computed < minimumFare ? minimumFare : computed;
    }
    std::string rideType() const override { return "Premium"; }

    void rideDetails(std::ostream& out = std::cout) const override {
        Ride::rideDetails(out);
        out << "    Vehicle: " << vehicle << " (minimum fare " << money(15.00) << ")\n";
    }

private:
    std::string vehicle;
};

/** Pooled ride: a Standard ride discounted 40% because passengers share the car. */
class SharedRide : public StandardRide {
public:
    SharedRide(std::string id, std::string pickup, std::string dropoff, double miles,
               int poolSize)
        : StandardRide(std::move(id), std::move(pickup), std::move(dropoff), miles),
          passengers(poolSize) {
        if (poolSize < 2) {
            throw std::invalid_argument("A shared ride needs at least 2 passengers.");
        }
    }

    double fare() const override { return StandardRide::fare() * 0.60; }
    std::string rideType() const override { return "Shared"; }

    void rideDetails(std::ostream& out = std::cout) const override {
        StandardRide::rideDetails(out);
        out << "    Pool: " << passengers << " passengers (40% off Standard)\n";
    }

private:
    int passengers;
};

/** Driver whose ride list and rating can change only through its public methods. */
class Driver {
public:
    Driver(std::string id, std::string driverName, double startingRating)
        : driverID(std::move(id)), name(std::move(driverName)), rating(startingRating) {
        if (startingRating < 0 || startingRating > 5) {
            throw std::invalid_argument("Rating must be between 0 and 5.");
        }
    }

    void addRide(std::shared_ptr<const Ride> ride) {
        if (!ride) {
            throw std::invalid_argument("Cannot assign an empty ride.");
        }
        assignedRides.push_back(std::move(ride));
    }

    /** Folds a 1-5 star trip rating into the running average. */
    void rateTrip(int stars) {
        if (stars < 1 || stars > 5) {
            throw std::invalid_argument("Trip rating must be 1-5 stars.");
        }
        rating = (rating * ratingCount + stars) / (ratingCount + 1);
        ++ratingCount;
    }

    double totalEarnings() const {
        double total = 0;
        for (const auto& ride : assignedRides) {
            total += ride->fare();
        }
        return total;
    }

    std::size_t rideCount() const { return assignedRides.size(); }
    const std::string& getName() const { return name; }

    void getDriverInfo(std::ostream& out = std::cout) const {
        out << "Driver " << driverID << ": " << name << '\n'
            << "  Rating: " << fixed2(rating) << "   Rides: " << rideCount()
            << "   Earnings: " << money(totalEarnings()) << '\n';
        for (const auto& ride : assignedRides) {
            ride->rideDetails(out);
        }
    }

private:
    std::string driverID;
    std::string name;
    double rating;
    int ratingCount = 1;
    std::vector<std::shared_ptr<const Ride>> assignedRides;
};

/** Rider whose requested-ride history is private to the class. */
class Rider {
public:
    Rider(std::string id, std::string riderName)
        : riderID(std::move(id)), name(std::move(riderName)) { }

    void requestRide(std::shared_ptr<const Ride> ride) {
        if (!ride) {
            throw std::invalid_argument("Cannot request an empty ride.");
        }
        requestedRides.push_back(std::move(ride));
    }

    double totalSpent() const {
        double total = 0;
        for (const auto& ride : requestedRides) {
            total += ride->fare();
        }
        return total;
    }

    void viewRides(std::ostream& out = std::cout) const {
        out << "Rider " << riderID << ": " << name << " - " << requestedRides.size()
            << " ride(s), total spent " << money(totalSpent()) << '\n';
        for (const auto& ride : requestedRides) {
            ride->rideDetails(out);
        }
    }

private:
    std::string riderID;
    std::string name;
    std::vector<std::shared_ptr<const Ride>> requestedRides;
};

/** Records a booking on both the rider and the driver, and in the system-wide list. */
void bookRide(std::vector<std::shared_ptr<Ride>>& rides, const std::shared_ptr<Ride>& ride,
              Rider& rider, Driver& driver) {
    rider.requestRide(ride);
    driver.addRide(ride);
    rides.push_back(ride);
}

void printHeading(const std::string& title) {
    std::cout << "\n=== " << title << " ===\n";
}

int main() {
    Driver dana("D-01", "Dana Lopez", 4.90);
    Driver eli("D-02", "Eli Brooks", 4.60);
    Rider alex("U-101", "Alex Kim");
    Rider sam("U-102", "Sam Patel");

    std::vector<std::shared_ptr<Ride>> rides;
    bookRide(rides, std::make_shared<StandardRide>("R-1001", "Union Station", "Midtown", 4.2),
             alex, dana);
    bookRide(rides, std::make_shared<PremiumRide>("R-1002", "Airport", "Grand Hotel", 12.0,
                                                  "Luxury Sedan"),
             alex, eli);
    bookRide(rides, std::make_shared<SharedRide>("R-1003", "University", "Tech Park", 8.0, 3),
             sam, dana);
    bookRide(rides, std::make_shared<PremiumRide>("R-1004", "Museum", "Riverwalk", 2.0, "SUV"),
             sam, eli);
    bookRide(rides, std::make_shared<Ride>("R-1005", "Library", "City Hall", 1.5), alex, dana);

    printHeading("Polymorphism: rideDetails() on a mixed list");
    for (const auto& ride : rides) {
        ride->rideDetails();
    }

    printHeading("Polymorphism: fare() on a mixed list");
    double total = 0;
    for (const auto& ride : rides) {
        double fare = ride->fare();
        total += fare;
        std::cout << "  " << std::left << std::setw(8) << ride->getRideID()
                  << std::setw(10) << ride->rideType()
                  << std::right << std::setw(10) << money(fare) << '\n';
    }
    std::cout << "  " << std::left << std::setw(18) << "Total"
              << std::right << std::setw(10) << money(total) << '\n';

    printHeading("Riders");
    alex.viewRides();
    sam.viewRides();

    dana.rateTrip(5);
    eli.rateTrip(4);
    printHeading("Drivers (after trip ratings)");
    dana.getDriverInfo();
    eli.getDriverInfo();

    printHeading("Validation");
    try {
        Ride("R-BAD", "Nowhere", "Nowhere", 0);
    } catch (const std::invalid_argument& error) {
        std::cout << "  Rejected: " << error.what() << '\n';
    }
    try {
        dana.rateTrip(7);
    } catch (const std::invalid_argument& error) {
        std::cout << "  Rejected: " << error.what() << '\n';
    }
    // Encapsulation: `dana.assignedRides` would not compile because the member is private.
    std::cout << "  " << dana.getName() << "'s rides are reachable only through Driver methods ("
              << dana.rideCount() << " assigned).\n";
    return 0;
}
