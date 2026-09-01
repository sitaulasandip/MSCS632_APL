// C++: static typing + lambda "closures" + block scope demo
#include <iostream>
#include <functional>
#include <string>
using namespace std;


function<int()> makeCounter() {
    // capturing a local by reference and returning it would dangle;
    // we capture by value into a mutable lambda, and the lambda owns its copy.
    return [count = 0]() mutable {
        count += 1;
        return count;
    };
}

int main() {
    int value = 10;
    cout << "value = " << value << " | type: int" << endl;
    // value = "now a string";   // COMPILE ERROR if uncommented: cannot assign

    //   No implicit string<->number coercion like JS  
    string s = "5";
    int n = 1;
    // cout << (s + n);          // COMPILE ERROR if uncommented: no operator+
                                  // for std::string and int without conversion
    cout << "s + std::to_string(n) = " << (s + to_string(n)) << endl;

    //   Lambda closures  
    auto counterA = makeCounter();
    auto counterB = makeCounter();
    cout << "counterA: " << counterA() << " " << counterA() << " " << counterA() << endl;
    cout << "counterB: " << counterB() << endl; // independent state, prints 1

    //   Block scope  
    for (int i = 0; i < 3; i++) { /* i only visible inside the loop */ }
    // cout << i;  // COMPILE ERROR if uncommented: 'i' was not declared in this scope
    cout << "i is block-scoped and not visible here" << endl;

    return 0;
}
