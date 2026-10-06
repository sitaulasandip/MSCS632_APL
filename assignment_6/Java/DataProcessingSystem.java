import java.io.FileWriter;
import java.io.IOException;
import java.io.PrintWriter;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.LinkedList;
import java.util.List;
import java.util.NoSuchElementException;
import java.util.Queue;
import java.util.Random;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.locks.ReentrantLock;

public class DataProcessingSystem {

    static class Task {
        int id;
        int data;

        Task(int id, int data) {
            this.id = id;
            this.data = data;
        }
    }

    static class TaskQueue {
        private Queue<Task> tasks = new LinkedList<>();
        private ReentrantLock lock = new ReentrantLock();

        public void addTask(Task task) {
            lock.lock();
            try {
                tasks.add(task);
            } finally {
                lock.unlock();
            }
        }

        // throws NoSuchElementException when the queue is empty
        public Task getTask() {
            lock.lock();
            try {
                return tasks.remove();
            } finally {
                lock.unlock();
            }
        }
    }

    static class Worker implements Runnable {
        private String name;
        private TaskQueue queue;
        private List<String> results;

        Worker(int id, TaskQueue queue, List<String> results) {
            this.name = "Worker-" + id;
            this.queue = queue;
            this.results = results;
        }

        public void run() {
            log(name + " started");
            int count = 0;

            while (true) {
                Task task;
                try {
                    task = queue.getTask();
                } catch (NoSuchElementException e) {
                    break; // no more tasks
                }

                try {
                    int result = process(task);
                    synchronized (results) {
                        results.add("Task " + task.id + ": " + task.data + " -> " + result + " (" + name + ")");
                    }
                    count++;
                    log(name + " finished task " + task.id);
                } catch (IllegalArgumentException e) {
                    log("ERROR: " + name + " failed task " + task.id + " - " + e.getMessage());
                } catch (InterruptedException e) {
                    log("ERROR: " + name + " was interrupted");
                    Thread.currentThread().interrupt();
                    break;
                }
            }

            log(name + " completed, processed " + count + " tasks");
        }

        // simulates work with a delay, then squares the number
        private int process(Task task) throws InterruptedException {
            Thread.sleep(200 + new Random().nextInt(300));
            if (task.data < 0) {
                throw new IllegalArgumentException("invalid data " + task.data);
            }
            return task.data * task.data;
        }
    }

    static void log(String message) {
        System.out.println(LocalTime.now().withNano(0) + " " + message);
    }

    static void saveResults(List<String> results, String fileName) {
        try (PrintWriter writer = new PrintWriter(new FileWriter(fileName))) {
            for (String line : results) {
                writer.println(line);
            }
            log("Results saved to " + fileName);
        } catch (IOException e) {
            log("ERROR: could not write to " + fileName + " - " + e.getMessage());
        }
    }

    public static void main(String[] args) {
        int numTasks = 10;
        int numWorkers = 3;

        TaskQueue queue = new TaskQueue();
        List<String> results = new ArrayList<>();
        Random random = new Random();

        for (int i = 1; i <= numTasks; i++) {
            int data = (i % 4 == 0) ? -i : random.nextInt(100) + 1; // every 4th task is bad data
            queue.addTask(new Task(i, data));
        }
        log("Added " + numTasks + " tasks to the queue");

        ExecutorService executor = Executors.newFixedThreadPool(numWorkers);
        for (int i = 1; i <= numWorkers; i++) {
            executor.submit(new Worker(i, queue, results));
        }

        executor.shutdown();
        try {
            if (!executor.awaitTermination(30, TimeUnit.SECONDS)) {
                log("ERROR: workers took too long, forcing shutdown");
                executor.shutdownNow();
            }
        } catch (InterruptedException e) {
            log("ERROR: main thread interrupted");
            executor.shutdownNow();
        }

        log("All workers done. " + results.size() + " of " + numTasks + " tasks succeeded");
        saveResults(results, "results_java.txt");
    }
}
