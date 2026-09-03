// Rust: ownership, borrowing, and move semantics demo
// Compile-time enforced memory safety: no GC, no manual free().

struct Buffer {
    data: Vec<i32>,
}

impl Buffer {
    fn new(size: usize) -> Self {
        // Heap allocation happens here; Rust tracks a single owner (this Buffer).
        Buffer { data: vec![0; size] }
    }

    fn sum(&self) -> i32 {
        // Borrowed immutably (&self) -- read-only access, no ownership transfer.
        self.data.iter().sum()
    }

    fn fill(&mut self, value: i32) {
        // Borrowed mutably (&mut self) -- exclusive access enforced by the compiler.
        for v in self.data.iter_mut() {
            *v = value;
        }
    }
}
// Buffer::data (the Vec's heap allocation) is freed automatically here
// when a Buffer value goes out of scope -- this is Rust's "Drop" mechanism (RAII).

fn take_ownership(buf: Buffer) -> usize {
    // 'buf' is MOVED into this function; the caller no longer owns it.
    buf.data.len()
}

fn main() {
    let mut b1 = Buffer::new(5);
    b1.fill(7);
    println!("b1 sum (before move): {}", b1.sum());

    let len = take_ownership(b1); // b1 is moved here
    println!("length reported after move: {}", len);

    // The next line, if uncommented, fails to COMPILE (not a runtime crash):
    // println!("{}", b1.sum());
    // error[E0382]: borrow of moved value: `b1`
    // This demonstrates Rust catching a use-after-move (analogous to a
    // dangling-pointer bug in C++) at compile time via the borrow checker.

    // Ownership + borrowing example with a vector:
    let numbers = vec![1, 2, 3, 4, 5];
    let total = sum_borrowed(&numbers); // borrow, not move
    println!("numbers still usable: {:?}, total = {}", numbers, total);

    // Scope-based automatic deallocation:
    {
        let temp = Buffer::new(1000);
        println!("temp buffer created, len = {}", temp.data.len());
    } // <- temp's heap memory is freed HERE, deterministically, no GC pause.
    println!("temp has been dropped; its memory is already freed");
}

fn sum_borrowed(v: &Vec<i32>) -> i32 {
    v.iter().sum()
}
