# Python: Calculate the sum of an array (deliberate syntax error)
def calculate_sum(arr)               # <-- missing colon at end of def header
    total = 0
    for num in arr:
        total += num
    return total

numbers = [1, 2, 3, 4, 5]
result = calculate_sum(numbers)
print("Sum in Python:", result)
