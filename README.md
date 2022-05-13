# LKOperation

LKOperation is a concurrent task solution written in Swift. 

## Feature
- LKAsyncOperation solve Operation will turn to finish state before asynchronous task completed
- LKAsyncSequenceOperationQueue monitor collection of LKAsyncSequenceOperations with concurrent/serial execution. 
    - Any operation in the collection rising an error will cancel remain operations and notify user with error 
    - Notify user when all process is completed successfully


## Usage
- [Build asynchronous operation](#AsyncOperation)
- [Monitor operations collection](#Monitor-Operations-Colletion)
- [Arrange the sequence of operations](#Arrange-Sequence)

## Note 
- [Memory Leak](#Memory-Leak)
- [License](#License)

### AsyncOperation

**Scenario 1:**

1. Create a custom class inherits from `LKAsyncOperation`.

2. Override `main()` method and implement async task in it.

3. Make sure to call `completeBlock()` closure in every **return** point and the **defer** function in the callBack closure.

4. Inside the main() method, you can check property `isCancelled` property to determine keeping process going or ending process immediately.

```swift
class DemoAsyncOperation: LKAsyncOperation {
    
    override func main() {
        
        guard !isCancelled else {
            //return point
            completeBlock()
            return
        }
        
        URLSession.shared.dataTask(
            with: URL(string: "https://jsonplaceholder.typicode.com/todos/1")!,
            completionHandler: { [weak self] data, response, error in

                //defer function in the callBack closure
                defer {
                    self?.completeBlock()
                }
                
                guard let self = self else { return }
                
                guard !self.isCancelled else {
                    return
                }
                
                guard error == nil else {
                    return
                }
                    
                let json = try! JSONSerialization.jsonObject(with: data!, options: .allowFragments)
                
                print(json)
                
            }
        ).resume()
    }
}

let operationQueue = OperationQueue()
        
operationQueue.addOperation(DemoAsyncOperation())
```

**Scenario 2:**
1. Create an operation object from `LKAsyncBlockOperation`.
2. Make sure to call `completeBlock()` closure in every **return** point and the **defer** function in the callBack closure.

```swift
let demoOperation = LKAsyncBlockOperation { op in

    guard !op.isCancelled else {
        op.completeBlock()
        return
    }

    URLSession.shared.dataTask(
        with: URL(string: "https://jsonplaceholder.typicode.com/todos/1")!,
        completionHandler: { data, response, error in

            defer {
                op.completeBlock()
            }

            guard !op.isCancelled else {
                return
            }

            guard error == nil else {
                return
            }

            let json = try! JSONSerialization.jsonObject(with: data!, options: .allowFragments)

            print(json)

        }
    ).resume()
}

let operationQueue = OperationQueue()
operationQueue.addOperation(demoOperation)
```

### Monitor-Operations-Colletion
Take `LKSequenceAsyncOperation` and `LKAsyncSequenceOperationQueue` to achieve monitoring group of tasks's state

- Run group of operations concurrently
1. Implement your asynchronous operation through `LKSequenceAsyncOperation`
2. Put all the operations into an array
3. Take `addAsyncOperationsWithExecuteConcurrently(_:)` method in `LKAsyncSequenceOperationQueue` to execute the array
4. The completion block you added to `LKAsyncSequenceOperationQueue` will be executed when all operations are finished or any one of the operation rose an error.

Note: Run this sample code and observe the console, you will discover the whole process complete in 1 seconds, not 5.5 seconds. This result proof these operations executed concurrently.

```swift
var operationCollections: [LKAsyncSequenceOperation] = []

for i in 0...10 {
    
    let op = LKAsyncSequenceOperation{ controller in
        
        DispatchQueue.global().asyncAfter(deadline: .now() + Double(i) / 10.0) {
            
            defer {
                controller.complete()
            }

            print("This is the \(i) task")
        }
    }
    
    operationCollections.append(op)
}

let operationQueue = LKAsyncSequenceOperationQueue()
    .completion{ result in
        switch result {
        case .success:
            print("Complete all the task successfully")
        case .failure(let error):
            print("Receive error \(error)")
        }
    }

operationQueue.addAsyncOperationsWithExecuteConcurrently(operationCollections)
```

- Concurrently run task with receiving error

```swift
var operationCollections: [LKAsyncSequenceOperation] = []

for i in 0...10 {
    
    let op = LKAsyncSequenceOperation{ controller in
        
        DispatchQueue.global().asyncAfter(deadline: .now() + Double(i) / 10.0) {
            
            defer {
                controller.complete()
            }
            
            guard !controller.isCancelled() else {
                return
            }
            
            print("This is the \(i) task")
            
            if i == 5 {
                controller.failure(
                    NSError(
                        domain: "LKAsyncSequenceOperation",
                        code: 99,
                        userInfo: nil
                    )
                )
            }
        }
    }
    
    operationCollections.append(op)
}

let operationQueue = LKAsyncSequenceOperationQueue()
    .completion{ result in
        switch result {
        case .success:
            print("Complete all the task successfully")
        case .failure(let error):
            print("Receive error \(error)")
        }
    }

operationQueue.addAsyncOperationsWithExecuteConcurrently(operationCollections)
```

- Run group of operations serially
1. Implement your asynchronous operation through `LKSequenceAsyncOperation`
2. Put all the operations into an array
3. Take `addAsyncOperationsWithExecuteSerially(_:)` method in `LKAsyncSequenceOperationQueue` to execute the array
4. The completion block you added to `LKAsyncSequenceOperationQueue` will be executed when all operations are finished or any one of the operation rose an error.

```swift
var operationCollections: [LKAsyncSequenceOperation] = []

for i in 0...10 {
    
    let op = LKAsyncSequenceOperation{ controller in
        
        DispatchQueue.global().asyncAfter(deadline: .now() + Double(i) / 10.0) {
            
            defer {
                controller.complete()
            }
        
            print("This is the \(i) task")
        }
    }
    
    operationCollections.append(op)
}

let operationQueue = LKAsyncSequenceOperationQueue()
    .completion{ result in
        switch result {
        case .success:
            print("Complete all the task successfully")
        case .failure(let error):
            print("Receive error \(error)")
        }
    }

operationQueue.addAsyncOperationsWithExecuteSerially(operationCollections)
```

### Arrange-Sequence

`LKAsyncOperation`, `LKAsyncBlockOperation`, `LKAsyncSequenceOperation` all inherit from iOS native class `Operation` and `LKAsyncSequenceOperationQueue` inherits from iOS native class `OperationQueue`. You can chain your operation through native way - Add them as dependency to control the sequence of operations. This characteristic run correctly with LKOperation framework as well. 

### Memory-Leak
Operation and OperationQueue will retain each other until the operation is finished. So remember to set your operation state to `finished` after you finished your work or left the process (In `LKSequenceAsyncOperation`, remember to invoke `completeBlock`). If you miss this, you probably has produced a memory leak inadvertently.

### License
LKOperation is released under the MIT license.