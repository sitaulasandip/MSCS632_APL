import math
import sys


class StatisticsCalculator:
    """Encapsulates a list of integers and the statistics derived from it."""

    def __init__(self, values, label="Dataset"):
        if not all(isinstance(v, int) and not isinstance(v, bool) for v in values):
            raise TypeError("StatisticsCalculator only accepts integers")
        self._values = list(values)
        self.label = label

    @classmethod
    def from_strings(cls, tokens, label="User input"):
        values = []
        for token in tokens:
            try:
                values.append(int(token))
            except ValueError:
                raise ValueError(f"'{token}' is not a valid integer") from None
        return cls(values, label)

    @property
    def values(self):
        return list(self._values)

    @property
    def count(self):
        return len(self._values)

    def _require_data(self):
        if not self._values:
            raise ValueError("statistics are undefined for an empty list")

    def sorted_values(self):
        return sorted(self._values)

    def mean(self):
        self._require_data()
        return sum(self._values) / self.count

    def median(self):
        self._require_data()
        ordered = self.sorted_values()
        middle = self.count // 2
        if self.count % 2 == 1:
            return float(ordered[middle])
        return (ordered[middle - 1] + ordered[middle]) / 2

    def frequencies(self):
        counts = {}
        for value in self._values:
            counts[value] = counts.get(value, 0) + 1
        return counts

    def mode(self):
        """Returns every value tied for the highest frequency, and that frequency."""
        self._require_data()
        counts = self.frequencies()
        highest = max(counts.values())
        modes = sorted(value for value, count in counts.items() if count == highest)
        return modes, highest

    def value_range(self):
        self._require_data()
        return min(self._values), max(self._values)

    def std_dev(self):
        """Population standard deviation."""
        mean = self.mean()
        return math.sqrt(sum((v - mean) ** 2 for v in self._values) / self.count)

    def summary(self):
        if not self._values:
            return f"=== {self.label} ===\nNo values provided; statistics are undefined.\n"
        modes, highest = self.mode()
        low, high = self.value_range()
        plural = "" if highest == 1 else "s"
        return "\n".join([
            f"=== {self.label} ===",
            f"Input   : {self._values}",
            f"Sorted  : {self.sorted_values()}",
            f"Count   : {self.count}",
            f"Mean    : {self.mean():.2f}",
            f"Median  : {self.median():.2f}",
            f"Mode    : {modes} (appears {highest} time{plural})",
            f"Range   : {low} to {high} (spread {high - low})",
            f"Std Dev : {self.std_dev():.2f}",
            "",
        ])

    def __len__(self):
        return self.count

    def __repr__(self):
        return f"StatisticsCalculator({self._values!r}, label={self.label!r})"


SAMPLES = [
    StatisticsCalculator([4, 8, 15, 16, 23, 42, 8, 15, 8], "Sample A: odd count, single mode"),
    StatisticsCalculator([10, 20, 20, 30, 30, 40], "Sample B: even count, two modes"),
    StatisticsCalculator([-5, 3, -5, 7, 0, 3, -2, 12], "Sample C: negative values"),
]


def main(argv):
    if argv:
        try:
            calculator = StatisticsCalculator.from_strings(argv)
        except ValueError as error:
            print(f"Error: {error}", file=sys.stderr)
            return 1
        print(calculator.summary())
        return 0

    print("Python (object-oriented) statistics calculator\n")
    for calculator in SAMPLES:
        print(calculator.summary())
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
