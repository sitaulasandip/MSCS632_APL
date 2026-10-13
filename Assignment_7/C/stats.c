/*
 * stats.c - Procedural statistics calculator (mean, median, mode).

 */

#include <errno.h>
#include <limits.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* Parses a base-10 integer. Returns 1 on success, 0 on invalid input. */
int parse_int(const char *text, int *out)
{
    char *end;
    long value;

    errno = 0;
    value = strtol(text, &end, 10);
    if (end == text || *end != '\0' || errno == ERANGE ||
        value < INT_MIN || value > INT_MAX) {
        return 0;
    }
    *out = (int)value;
    return 1;
}

/* Allocates a copy of the array so the caller's data is never reordered. */
int *copy_array(const int *values, size_t count)
{
    int *copy = malloc(count * sizeof *copy);
    if (copy != NULL) {
        memcpy(copy, values, count * sizeof *copy);
    }
    return copy;
}

/* Merges the sorted halves values[left..mid) and values[mid..right). */
void merge(int *values, int *buffer, size_t left, size_t mid, size_t right)
{
    size_t i = left, j = mid, k = left;

    while (i < mid && j < right) {
        buffer[k++] = (values[i] <= values[j]) ? values[i++] : values[j++];
    }
    while (i < mid) {
        buffer[k++] = values[i++];
    }
    while (j < right) {
        buffer[k++] = values[j++];
    }
    for (k = left; k < right; k++) {
        values[k] = buffer[k];
    }
}

void merge_sort_range(int *values, int *buffer, size_t left, size_t right)
{
    size_t mid;

    if (right - left < 2) {
        return;
    }
    mid = left + (right - left) / 2;
    merge_sort_range(values, buffer, left, mid);
    merge_sort_range(values, buffer, mid, right);
    merge(values, buffer, left, mid, right);
}

/* Sorts in place using a manually allocated scratch buffer. Returns 0 on failure. */
int sort_array(int *values, size_t count)
{
    int *buffer;

    if (count < 2) {
        return 1;
    }
    buffer = malloc(count * sizeof *buffer);
    if (buffer == NULL) {
        return 0;
    }
    merge_sort_range(values, buffer, 0, count);
    free(buffer);
    return 1;
}

double calculate_mean(const int *values, size_t count)
{
    long long sum = 0;
    size_t i;

    for (i = 0; i < count; i++) {
        sum += values[i];
    }
    return (double)sum / (double)count;
}

/* Expects a sorted array. */
double calculate_median(const int *sorted, size_t count)
{
    if (count % 2 == 1) {
        return sorted[count / 2];
    }
    return ((double)sorted[count / 2 - 1] + (double)sorted[count / 2]) / 2.0;
}

/*
 * Expects a sorted array, so equal values sit next to each other and can be
 * counted in a single pass. Writes every value that ties for the highest
 * frequency into *modes_out (allocated here; the caller must free it) and
 * returns how many modes were found, or 0 if allocation failed.
 */
size_t calculate_mode(const int *sorted, size_t count, int **modes_out, size_t *max_frequency)
{
    size_t i, run_length, best = 0, mode_count = 0;
    int *modes;

    /* First pass: find the highest frequency. */
    for (i = 0; i < count; i += run_length) {
        run_length = 1;
        while (i + run_length < count && sorted[i + run_length] == sorted[i]) {
            run_length++;
        }
        if (run_length > best) {
            best = run_length;
        }
    }

    /* There can never be more modes than input values. */
    modes = malloc(count * sizeof *modes);
    if (modes == NULL) {
        *modes_out = NULL;
        return 0;
    }

    /* Second pass: collect every value that reaches that frequency. */
    for (i = 0; i < count; i += run_length) {
        run_length = 1;
        while (i + run_length < count && sorted[i + run_length] == sorted[i]) {
            run_length++;
        }
        if (run_length == best) {
            modes[mode_count++] = sorted[i];
        }
    }

    *modes_out = modes;
    *max_frequency = best;
    return mode_count;
}

/* Population standard deviation. */
double calculate_std_dev(const int *values, size_t count, double mean)
{
    double squared_diffs = 0.0;
    size_t i;

    for (i = 0; i < count; i++) {
        double diff = values[i] - mean;
        squared_diffs += diff * diff;
    }
    return sqrt(squared_diffs / (double)count);
}

void print_array(const int *values, size_t count)
{
    size_t i;

    printf("[");
    for (i = 0; i < count; i++) {
        if (i > 0) {
            printf(", ");
        }
        printf("%d", values[i]);
    }
    printf("]");
}

/* Computes and prints every statistic for one dataset. Returns 0 on failure. */
int report_statistics(const char *label, const int *values, size_t count)
{
    int *sorted;
    int *modes;
    size_t mode_count, max_frequency = 0;
    double mean;

    printf("=== %s ===\n", label);
    if (count == 0) {
        printf("No values provided; statistics are undefined.\n\n");
        return 1;
    }

    sorted = copy_array(values, count);
    if (sorted == NULL || !sort_array(sorted, count)) {
        free(sorted);
        fprintf(stderr, "Error: out of memory\n");
        return 0;
    }

    mode_count = calculate_mode(sorted, count, &modes, &max_frequency);
    if (modes == NULL) {
        free(sorted);
        fprintf(stderr, "Error: out of memory\n");
        return 0;
    }

    mean = calculate_mean(values, count);

    printf("Input   : ");
    print_array(values, count);
    printf("\nSorted  : ");
    print_array(sorted, count);
    printf("\nCount   : %zu\n", count);
    printf("Mean    : %.2f\n", mean);
    printf("Median  : %.2f\n", calculate_median(sorted, count));
    printf("Mode    : ");
    print_array(modes, mode_count);
    printf(" (appears %zu time%s)\n", max_frequency, max_frequency == 1 ? "" : "s");
    printf("Range   : %d to %d (spread %lld)\n", sorted[0], sorted[count - 1],
           (long long)sorted[count - 1] - sorted[0]);
    printf("Std Dev : %.2f\n\n", calculate_std_dev(values, count, mean));

    free(modes);
    free(sorted);
    return 1;
}

int main(int argc, char *argv[])
{
    if (argc > 1) {
        size_t count = (size_t)(argc - 1);
        int *values = malloc(count * sizeof *values);
        size_t i;
        int ok;

        if (values == NULL) {
            fprintf(stderr, "Error: out of memory\n");
            return 1;
        }
        for (i = 0; i < count; i++) {
            if (!parse_int(argv[i + 1], &values[i])) {
                fprintf(stderr, "Error: '%s' is not a valid integer\n", argv[i + 1]);
                free(values);
                return 1;
            }
        }
        ok = report_statistics("User input", values, count);
        free(values);
        return ok ? 0 : 1;
    } else {
        int sample_a[] = {4, 8, 15, 16, 23, 42, 8, 15, 8};
        int sample_b[] = {10, 20, 20, 30, 30, 40};
        int sample_c[] = {-5, 3, -5, 7, 0, 3, -2, 12};

        printf("C (procedural) statistics calculator\n\n");
        if (!report_statistics("Sample A: odd count, single mode", sample_a,
                               sizeof sample_a / sizeof sample_a[0]) ||
            !report_statistics("Sample B: even count, two modes", sample_b,
                               sizeof sample_b / sizeof sample_b[0]) ||
            !report_statistics("Sample C: negative values", sample_c,
                               sizeof sample_c / sizeof sample_c[0])) {
            return 1;
        }
    }
    return 0;
}
