// C++: dangling pointer demo
#include <iostream>
using namespace std;

class Buffer {
public:
    int* data;
    int size;
    Buffer(int n) : size(n) {
        data = new int[n];
        for (int i = 0; i < n; i++) data[i] = 0;
    }
    ~Buffer() {
        delete[] data;
        cout << "Buffer destructor: memory freed" << endl;
    }
    int sum() {
        int total = 0;
        for (int i = 0; i < size; i++) total += data[i];
        return total;
    }
};

int* makeDanglingPointer() {
    int local = 42;
    return &local;   // address of a stack variable that is destroyed
                      // the moment this function returns -> dangling pointer
}

int main() {
    {
        Buffer b(5);
        for (int i = 0; i < 5; i++) b.data[i] = 7;
        cout << "b.sum() = " << b.sum() << endl;
    }
    int* dangling = makeDanglingPointer();
    cout << "Dangling pointer value (undefined behavior): " << *dangling << endl;
    return 0;
}
