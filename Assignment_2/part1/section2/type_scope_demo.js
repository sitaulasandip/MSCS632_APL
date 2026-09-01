// JavaScript: dynamic typing + type coercion + closures demo
function makeCounter() {
    let count = 0;              // captured by closure via lexical scope
    return function increment() {
        count += 1;
        return count;
    };
}

// --- Dynamic typing ---
let value = 10;
console.log("value =", value, "| type:", typeof value);
value = "now a string";
console.log("value =", value, "| type:", typeof value);
value = [1, 2, 3];
console.log("value =", value, "| type:", typeof value); // note: "object", not "array"

// --- Implicit type coercion (JS-specific quirk) ---
console.log("1" + 1);   // "11"  -> string concatenation
console.log("5" - 1);   // 4     -> numeric coercion
console.log(1 == "1");  // true  -> loose equality coerces types
console.log(1 === "1"); // false -> strict equality does not

// --- Closures ---
const counterA = makeCounter();
const counterB = makeCounter();
console.log("counterA:", counterA(), counterA(), counterA()); // 1 2 3
console.log("counterB:", counterB());                          // 1 (independent state)

// --- var vs let scoping ---
function scopeDemo() {
    for (var i = 0; i < 3; i++) {}
    console.log("var i after loop:", i); // 3, leaks out of block
    for (let j = 0; j < 3; j++) {}
    try {
        console.log(j); // ReferenceError: j is block-scoped
    } catch (e) {
        console.log("let j after loop: ReferenceError -", e.message);
    }
}
scopeDemo();
