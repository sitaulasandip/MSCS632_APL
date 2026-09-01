// JavaScript: Calculate the sum of an array (deliberate syntax error)
function calculateSum(arr) {
    let total = 0;
    for (let num of arr) {
        total += num;
    // <-- missing closing brace for the for-loop
    return total;
}

let numbers = [1, 2, 3, 4, 5];
let result = calculateSum(numbers);
console.log("Sum in JavaScript:", result);
