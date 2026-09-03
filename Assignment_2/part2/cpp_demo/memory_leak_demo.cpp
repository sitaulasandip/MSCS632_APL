// C++: isolated memory-leak demo 
#include <iostream>
using namespace std;

int main() {
    int* raw = new int(99);
    cout << "raw = " << *raw << endl;
    delete raw;

    // Deliberate LEAKS: allocated, pointer discarded, never freed
    for (int i = 0; i < 3; i++) {
        int* leaked = new int[1000];
        (void)leaked;
    }
    char* leaked_str = new char[64];
    (void)leaked_str;

    return 0;
}
