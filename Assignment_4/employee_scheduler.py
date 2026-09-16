
import random
import sys
from dataclasses import dataclass

DAYS = ("Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday")
SHIFTS = ("morning", "afternoon", "evening")
CAPACITY = 2  # A shift is full when both required positions are assigned
MAX_DAYS = 5


@dataclass
class Employee:
    name: str
    preferences: list  # Seven ranked shift lists, Monday through Sunday.


def parse_preferences(value):
    ranking = [part.strip().lower() for part in value.split(",")]
    if not ranking or any(shift not in SHIFTS for shift in ranking):
        raise ValueError("Enter morning, afternoon, or evening, separated by commas.")
    if len(set(ranking)) != len(ranking):
        raise ValueError("Do not repeat a shift in a ranking.")
    return ranking


def create_schedule(employees, seed=None):
    required = len(DAYS) * len(SHIFTS) * CAPACITY
    if len(employees) * MAX_DAYS < required:
        raise ValueError("At least 9 employees are needed to cover 42 weekly positions.")
    names = [employee.name.strip().casefold() for employee in employees]
    if any(not name for name in names) or len(set(names)) != len(names):
        raise ValueError("Employee names must be nonempty and unique.")
    for employee in employees:
        if len(employee.preferences) != 7:
            raise ValueError("Each employee needs preferences for all seven days.")
        for ranking in employee.preferences:
            parse_preferences(",".join(ranking))
            if any(shift not in SHIFTS for shift in ranking):
                raise ValueError("Stored shift names must be lowercase.")

    rng = random.Random(seed)

    # Random choices can leave a later day short. Try a new week if that happens.
    for attempt in range(1000):
        schedule = []
        days_worked = {index: 0 for index in range(len(employees))}
        complete = True

        for day in range(7):
            daily_shifts = [[], [], []]  # Morning, afternoon, evening.
            assigned_today = []
            available = []

            for index, employee in enumerate(employees):
                if days_worked[index] < MAX_DAYS:
                    available.append(index)

            if len(available) < 6:
                complete = False
                break

            # Shuffle ties; consider employees with fewer working days first.
            rng.shuffle(available)
            available.sort(key=lambda index: days_worked[index])

            # Give everyone a chance at their first choice before second/third.
            for rank in range(3):
                for index in available:
                    preferences = employees[index].preferences[day]
                    if index in assigned_today or rank >= len(preferences):
                        continue
                    shift = SHIFTS.index(preferences[rank])
                    if len(daily_shifts[shift]) < CAPACITY:
                        daily_shifts[shift].append(index)
                        assigned_today.append(index)
                        days_worked[index] += 1

            # Fill shortages randomly using employees still eligible that day.
            for shift in range(3):
                while len(daily_shifts[shift]) < CAPACITY:
                    candidates = []
                    for index in available:
                        if index not in assigned_today and days_worked[index] < MAX_DAYS:
                            candidates.append(index)
                    index = rng.choice(candidates)
                    daily_shifts[shift].append(index)
                    assigned_today.append(index)
                    days_worked[index] += 1

            schedule.append(daily_shifts)

        if complete:
            return schedule

    raise ValueError("No complete schedule found after 1000 attempts. "
                     "Try again with new random choices. No partial schedule was accepted.")


def read_employees():
    while True:
        try:
            count = int(input("Number of employees (at least 9): "))
            if count < 9:
                raise ValueError()
            break
        except ValueError:
            print("Enter a whole number of at least 9.")
    print("For each day, enter one shift or a comma-separated ranking.")
    print("Example: morning, evening, afternoon. Unlisted shifts are fallbacks.")
    print("Enter preferences for all 7 days because the company operates every day.")
    print("These are preferences, not assignments. You will work at most 5 days.")
    print("The scheduler chooses your days off and lists them in the final output.")
    employees = []
    names = set()
    for index in range(count):
        while True:
            name = input(f"Employee {index + 1} name: ").strip()
            if name and name.casefold() not in names:
                names.add(name.casefold())
                break
            print("Enter a nonempty, unique name.")
        preferences = []
        for day in DAYS:
            while True:
                try:
                    preferences.append(parse_preferences(input(f"  {day}: ")))
                    break
                except ValueError as error:
                    print(error)
        employees.append(Employee(name, preferences))
    return employees


def print_schedule(employees, schedule):
    print("\nFINAL WEEKLY SCHEDULE (two employees per shift)")
    totals = [0] * len(employees)
    for day, shifts in enumerate(schedule):
        print(f"\n{DAYS[day]}")
        for shift, assigned in enumerate(shifts):
            labels = []
            for index in assigned:
                totals[index] += 1
                employee = employees[index]
                marker = " *" if SHIFTS[shift] != employee.preferences[day][0] else ""
                labels.append(employee.name + marker)
            print(f"  {SHIFTS[shift].capitalize():10}: {', '.join(labels)}")
    print("\n* Assigned an alternative shift to resolve competing preferences/coverage.")
    print("\nDAYS WORKED (unassigned days are days off)")
    for index, employee in enumerate(employees):
        total = totals[index]
        print(f"  {employee.name}: {total}/5")
        days_off = []
        for day, shifts in enumerate(schedule):
            if all(index not in assigned for assigned in shifts):
                days_off.append(DAYS[day])
        print(f"    Days off: {', '.join(days_off)}")


def demo_employees(count=9):
    employees = []
    for index in range(count):
        ranking = []
        for rank in range(3):
            ranking.append(SHIFTS[(index + rank) % 3])
        preferences = []
        for day in DAYS:
            preferences.append(ranking.copy())
        employees.append(Employee(f"Employee {index + 1}", preferences))
    return employees


if __name__ == "__main__":
    try:
        if not sys.argv[1:] or sys.argv[1:] == ["--demo"]:
            roster = demo_employees() if sys.argv[1:] else read_employees()
            print_schedule(roster, create_schedule(roster))
        else:
            print("Usage: python employee_scheduler.py [--demo]", file=sys.stderr)
            sys.exit(1)
    except (EOFError, KeyboardInterrupt):
        print("\nInput cancelled.")
        sys.exit(1)
    except ValueError as error:
        print(f"Error: {error}", file=sys.stderr)
        sys.exit(1)
