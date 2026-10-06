package main

import (
	"fmt"
	"log"
	"math/rand"
	"os"
	"sync"
	"time"
)

type Task struct {
	ID   int
	Data int
}

type TaskQueue struct {
	tasks chan Task
}

func NewTaskQueue(size int) *TaskQueue {
	return &TaskQueue{tasks: make(chan Task, size)}
}

func (q *TaskQueue) AddTask(t Task) {
	q.tasks <- t
}

// ok is false when the queue is closed and empty
func (q *TaskQueue) GetTask() (Task, bool) {
	t, ok := <-q.tasks
	return t, ok
}

func (q *TaskQueue) Close() {
	close(q.tasks)
}

type Results struct {
	mu    sync.Mutex
	items []string
}

func (r *Results) Add(line string) {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.items = append(r.items, line)
}

// simulates work with a delay, then squares the number
func process(t Task) (int, error) {
	time.Sleep(time.Duration(200+rand.Intn(300)) * time.Millisecond)
	if t.Data < 0 {
		return 0, fmt.Errorf("invalid data %d", t.Data)
	}
	return t.Data * t.Data, nil
}

func worker(id int, queue *TaskQueue, results *Results, wg *sync.WaitGroup) {
	defer wg.Done()
	log.Printf("Worker-%d started", id)
	count := 0

	for {
		task, ok := queue.GetTask()
		if !ok {
			break // no more tasks
		}

		result, err := process(task)
		if err != nil {
			log.Printf("ERROR: Worker-%d failed task %d - %v", id, task.ID, err)
			continue
		}
		results.Add(fmt.Sprintf("Task %d: %d -> %d (Worker-%d)", task.ID, task.Data, result, id))
		count++
		log.Printf("Worker-%d finished task %d", id, task.ID)
	}

	log.Printf("Worker-%d completed, processed %d tasks", id, count)
}

func saveResults(items []string, fileName string) error {
	file, err := os.Create(fileName)
	if err != nil {
		return err
	}
	defer file.Close()

	for _, line := range items {
		if _, err := fmt.Fprintln(file, line); err != nil {
			return err
		}
	}
	return nil
}

func main() {
	numTasks := 10
	numWorkers := 3

	queue := NewTaskQueue(numTasks)
	results := &Results{}
	var wg sync.WaitGroup

	for i := 1; i <= numWorkers; i++ {
		wg.Add(1)
		go worker(i, queue, results, &wg)
	}

	for i := 1; i <= numTasks; i++ {
		data := rand.Intn(100) + 1
		if i%4 == 0 {
			data = -i // every 4th task is bad data
		}
		queue.AddTask(Task{ID: i, Data: data})
	}
	queue.Close() // workers stop once the queue is empty
	log.Printf("Added %d tasks to the queue", numTasks)

	wg.Wait()
	log.Printf("All workers done. %d of %d tasks succeeded", len(results.items), numTasks)

	if err := saveResults(results.items, "results_go.txt"); err != nil {
		log.Printf("ERROR: could not save results - %v", err)
		os.Exit(1)
	}
	log.Println("Results saved to results_go.txt")
}
