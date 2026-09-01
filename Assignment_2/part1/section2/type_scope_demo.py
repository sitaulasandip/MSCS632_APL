# Python: dynamic typing + closures demo
def make_counter():
    count = 0                     # captured by closure, mutated via 'nonlocal'
    def increment():
        nonlocal count
        count += 1
        return count
    return increment

#   Dynamic typing  
value = 10
print("value =", value, "| type:", type(value).__name__)
value = "now a string"            # legal: name rebound to a different type at runtime
print("value =", value, "| type:", type(value).__name__)
value = [1, 2, 3]
print("value =", value, "| type:", type(value).__name__)

#   Closures  
counter_a = make_counter()
counter_b = make_counter()
print("counter_a:", counter_a(), counter_a(), counter_a())  # 1 2 3
print("counter_b:", counter_b())                            # 1 (independent state)

#   Duck typing (no interfaces required)  
class Duck:
    def speak(self):
        return "Quack"

class Person:
    def speak(self):
        return "I'm quacking"

for creature in [Duck(), Person()]:
    print(creature.speak())
