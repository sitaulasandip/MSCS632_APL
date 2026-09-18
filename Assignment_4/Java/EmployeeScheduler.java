import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.HashSet;
import java.util.List;
import java.util.Locale;
import java.util.NoSuchElementException;
import java.util.Random;
import java.util.Scanner;
import java.util.Set;

/** Interactive weekly scheduler with simple loops, ranked preferences, and random fallback assignments. */
public class EmployeeScheduler {
    static final String[] DAYS = {"Monday", "Tuesday", "Wednesday", "Thursday",
                                  "Friday", "Saturday", "Sunday"};
    static final List<String> SHIFTS = List.of("morning", "afternoon", "evening");
    static final int CAPACITY = 2;
    static final int MAX_DAYS = 5;
    static final int DAILY_POSITIONS = SHIFTS.size() * CAPACITY;
    static final int WEEKLY_POSITIONS = DAYS.length * DAILY_POSITIONS;
    static final int MIN_EMPLOYEES = (WEEKLY_POSITIONS + MAX_DAYS - 1) / MAX_DAYS;
    static final int MAX_ATTEMPTS = 1000;

    record Employee(String name, List<List<String>> preferences) { }

    static List<String> parsePreferences(String value) {
        List<String> ranking = new ArrayList<>();
        for (String part : value.split(",", -1)) {
            String shift = part.trim().toLowerCase(Locale.ROOT);
            if (!SHIFTS.contains(shift)) {
                throw new IllegalArgumentException(
                    "Enter morning, afternoon, or evening, separated by commas.");
            }
            if (ranking.contains(shift)) {
                throw new IllegalArgumentException("Do not repeat a shift in a ranking.");
            }
            ranking.add(shift);
        }
        return ranking;
    }

    static List<List<List<Integer>>> createSchedule(List<Employee> employees, Random random) {
        return createSchedule(employees, random, MAX_ATTEMPTS);
    }

    /** A one-attempt budget uses balanced coverage immediately. */
    static List<List<List<Integer>>> createSchedule(List<Employee> employees, Random random, int attempts) {
        if (attempts < 1) {
            throw new IllegalArgumentException("At least one scheduling attempt is required.");
        }
        if (employees.size() < MIN_EMPLOYEES) {
            throw new IllegalArgumentException(
                "At least 9 employees are needed to cover 42 weekly positions.");
        }
        Set<String> names = new HashSet<>();
        for (Employee employee : employees) {
            String name = employee.name().trim().toLowerCase(Locale.ROOT);
            if (name.isEmpty() || !names.add(name)) {
                throw new IllegalArgumentException("Employee names must be nonempty and unique.");
            }
            if (employee.preferences().size() != DAYS.length) {
                throw new IllegalArgumentException("Each employee needs preferences for all seven days.");
            }
            for (List<String> ranking : employee.preferences()) {
                parsePreferences(String.join(",", ranking));
                if (!SHIFTS.containsAll(ranking)) {
                    throw new IllegalArgumentException("Stored shift names must be lowercase.");
                }
            }
        }

        // Retry the week if early choices leave too few employees for a later day.
        for (int attempt = 0; attempt < attempts; attempt++) {
            List<List<List<Integer>>> schedule = new ArrayList<>();
            int[] daysWorked = new int[employees.size()];
            boolean complete = true;

            for (int day = 0; day < DAYS.length; day++) {
                List<List<Integer>> dailyShifts = new ArrayList<>();
                for (int shift = 0; shift < SHIFTS.size(); shift++) {
                    dailyShifts.add(new ArrayList<>());
                }
                boolean[] assignedToday = new boolean[employees.size()];
                List<Integer> available = new ArrayList<>();
                for (int index = 0; index < employees.size(); index++) {
                    if (daysWorked[index] < MAX_DAYS) {
                        available.add(index);
                    }
                }
                if (available.size() < DAILY_POSITIONS) {
                    complete = false;
                    break;
                }

                // Shuffle ties and consider employees with fewer days first.
                Collections.shuffle(available, random);
                available.sort(Comparator.comparingInt(index -> daysWorked[index]));

                // On the final attempt, choose the least-worked employees first.
                // Starting from zero, this keeps totals within one of each other:
                // ceil(42 / employeeCount) <= 5, so full coverage is guaranteed.
                if (attempt == attempts - 1) {
                    available = new ArrayList<>(available.subList(0, DAILY_POSITIONS));
                }

                // Try everyone's first choice before second and third choices.
                for (int rank = 0; rank < SHIFTS.size(); rank++) {
                    for (int index : available) {
                        List<String> preferences = employees.get(index).preferences().get(day);
                        if (assignedToday[index] || rank >= preferences.size()) {
                            continue;
                        }
                        int shift = SHIFTS.indexOf(preferences.get(rank));
                        if (dailyShifts.get(shift).size() < CAPACITY) {
                            dailyShifts.get(shift).add(index);
                            assignedToday[index] = true;
                            daysWorked[index]++;
                        }
                    }
                }

                // Fill shortages randomly without exceeding either employee limit.
                for (int shift = 0; shift < SHIFTS.size(); shift++) {
                    while (dailyShifts.get(shift).size() < CAPACITY) {
                        List<Integer> candidates = new ArrayList<>();
                        for (int index : available) {
                            if (!assignedToday[index] && daysWorked[index] < MAX_DAYS) {
                                candidates.add(index);
                            }
                        }
                        int index = candidates.get(random.nextInt(candidates.size()));
                        dailyShifts.get(shift).add(index);
                        assignedToday[index] = true;
                        daysWorked[index]++;
                    }
                }
                schedule.add(dailyShifts);
            }
            if (complete) {
                return schedule;
            }
        }
        throw new IllegalStateException("Balanced coverage fallback failed.");
    }

    static List<Employee> readEmployees(Scanner input) {
        int count;
        while (true) {
            System.out.print("Number of employees (at least 9): ");
            try {
                count = Integer.parseInt(input.nextLine().trim());
                if (count < MIN_EMPLOYEES) {
                    throw new NumberFormatException();
                }
                break;
            } catch (NumberFormatException error) {
                System.out.println("Enter a whole number of at least 9.");
            }
        }
        System.out.println("For each day, enter one shift or a comma-separated ranking.");
        System.out.println("Example: morning, evening, afternoon. Unlisted shifts are fallbacks.");
        System.out.println("Enter preferences for all 7 days because the company operates every day.");
        System.out.println("These are preferences, not assignments. You will work at most 5 days.");
        System.out.println("The scheduler chooses your days off and lists them in the final output.");
        List<Employee> employees = new ArrayList<>();
        Set<String> names = new HashSet<>();
        for (int index = 0; index < count; index++) {
            String name;
            while (true) {
                System.out.printf("Employee %d name: ", index + 1);
                name = input.nextLine().trim();
                if (!name.isEmpty() && names.add(name.toLowerCase(Locale.ROOT))) {
                    break;
                }
                System.out.println("Enter a nonempty, unique name.");
            }
            List<List<String>> preferences = new ArrayList<>();
            for (String day : DAYS) {
                while (true) {
                    System.out.printf("  %s: ", day);
                    try {
                        preferences.add(parsePreferences(input.nextLine()));
                        break;
                    } catch (IllegalArgumentException error) {
                        System.out.println(error.getMessage());
                    }
                }
            }
            employees.add(new Employee(name, preferences));
        }
        return employees;
    }

    static void printSchedule(List<Employee> employees, List<List<List<Integer>>> schedule) {
        System.out.println("\nFINAL WEEKLY SCHEDULE (two employees per shift)");
        int[] totals = new int[employees.size()];
        for (int day = 0; day < DAYS.length; day++) {
            System.out.println("\n" + DAYS[day]);
            for (int shift = 0; shift < SHIFTS.size(); shift++) {
                List<String> labels = new ArrayList<>();
                for (int index : schedule.get(day).get(shift)) {
                    totals[index]++;
                    Employee employee = employees.get(index);
                    String marker = SHIFTS.get(shift).equals(employee.preferences().get(day).get(0))
                                    ? "" : " *";
                    labels.add(employee.name() + marker);
                }
                System.out.printf("  %-10s: %s%n", SHIFTS.get(shift), String.join(", ", labels));
            }
        }
        System.out.println("\n* Assigned an alternative shift to resolve competing preferences/coverage.");
        System.out.println("\nDAYS WORKED (unassigned days are days off)");
        for (int index = 0; index < employees.size(); index++) {
            System.out.printf("  %s: %d/5%n", employees.get(index).name(), totals[index]);
            List<String> daysOff = new ArrayList<>();
            for (int day = 0; day < DAYS.length; day++) {
                boolean working = false;
                for (List<Integer> shift : schedule.get(day)) {
                    if (shift.contains(index)) {
                        working = true;
                        break;
                    }
                }
                if (!working) {
                    daysOff.add(DAYS[day]);
                }
            }
            System.out.println("    Days off: " + String.join(", ", daysOff));
        }
    }

    static List<Employee> demoEmployees(int count, boolean conflicting) {
        List<Employee> employees = new ArrayList<>();
        for (int index = 0; index < count; index++) {
            List<List<String>> preferences = new ArrayList<>();
            for (int day = 0; day < DAYS.length; day++) {
                List<String> ranking = new ArrayList<>();
                if (conflicting) {
                    ranking.add("morning");
                } else {
                    for (int rank = 0; rank < SHIFTS.size(); rank++) {
                        ranking.add(SHIFTS.get((index + rank) % 3));
                    }
                }
                preferences.add(ranking);
            }
            employees.add(new Employee("Employee " + (index + 1), preferences));
        }
        return employees;
    }

    public static void main(String[] args) {
        try (Scanner input = new Scanner(System.in)) {
            if (args.length == 0 || (args.length == 1 && args[0].equals("--demo"))) {
                List<Employee> employees = args.length == 1 ? demoEmployees(9, false) : readEmployees(input);
                printSchedule(employees, createSchedule(employees, new Random()));
            } else {
                System.err.println("Usage: java EmployeeScheduler [--demo]");
                System.exit(1);
            }
        } catch (NoSuchElementException error) {
            System.err.println("Input cancelled.");
            System.exit(1);
        } catch (IllegalArgumentException error) {
            System.err.println("Error: " + error.getMessage());
            System.exit(1);
        }
    }
}
