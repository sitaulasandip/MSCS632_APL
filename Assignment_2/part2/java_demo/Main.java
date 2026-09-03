// Java: garbage collection demo
// The JVM allocates on the heap with 'new'; the programmer never frees memory
// manually -- the Garbage Collector reclaims objects with no reachable references.

import java.lang.ref.WeakReference;

public class Main {

    static class Buffer {
        int[] data;
        Buffer(int size) {
            data = new int[size];   // heap allocation
        }
        int sum() {
            int total = 0;
            for (int v : data) total += v;
            return total;
        }
    }

    public static void main(String[] args) throws InterruptedException {
        Buffer b1 = new Buffer(5);
        for (int i = 0; i < b1.data.length; i++) b1.data[i] = 7;
        System.out.println("b1 sum: " + b1.sum());

        // Track b1's object with a WeakReference so we can observe when the
        // collector reclaims it once there are no strong references left.
        WeakReference<Buffer> tracker = new WeakReference<>(b1);

        b1 = null; // drop the only strong reference -- object becomes eligible for GC

        System.gc(); // request (not force) a collection cycle
        Thread.sleep(200);

        if (tracker.get() == null) {
            System.out.println("Buffer was garbage collected (no manual free() call).");
        } else {
            System.out.println("Buffer not yet collected (GC timing is non-deterministic).");
        }

        // Demonstrate heap growth and reporting via Runtime stats
        Runtime rt = Runtime.getRuntime();
        long before = rt.totalMemory() - rt.freeMemory();
        java.util.List<int[]> hog = new java.util.ArrayList<>();
        for (int i = 0; i < 200; i++) {
            hog.add(new int[100_000]); // allocate ~80 MB total across iterations
        }
        long after = rt.totalMemory() - rt.freeMemory();
        System.out.println("Heap used before large alloc: " + before / 1024 + " KB");
        System.out.println("Heap used after large alloc: " + after / 1024 + " KB");

        hog = null; // release references; GC will reclaim on its own schedule
        System.gc();
        Thread.sleep(200);
        long afterGc = rt.totalMemory() - rt.freeMemory();
        System.out.println("Heap used after dropping refs + gc(): " + afterGc / 1024 + " KB");
    }
}
