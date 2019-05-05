# Realm Sync Helper Classes
Set of simple classes to make life easier with Realm Sync.

IMPORTANT: this is just a proof of concept and is WORK IN PROGRESS! 

## Revelant Classes

### SyncManager
Help us to know if realm is:
* `synced`: **Everything**  is synced and up to date with the server.
* `syncing`: Syncying.
* `notSynced`: Some change have not been synced, or there is no connection (we don't know if server changed).

We can listen to the changes of this status, or just use the flag `isEverythingSynced`.

### DisposableSyncQuery
Allows you to create a "temporal/disposable subscription" in a safe way. 

For example, you want to do a search by user while the user is typing. This is not trivial because: 
1. You need to subscribe to a query and wait
2. You need to listen when it completes, and if something goes wrong
3. You have to be sure to unsubscribe the subscriptions, or they will be hanging forever

Using `DisposableSyncQuery` you can just:
```
let query = DisposableSyncQuery<User>()

// When user input changes:
query.sync(query: { $0.filter("username CONTAINS '\(text)'") }, notify: .oneTime) { result in
    switch result {
    case .synced(let results): show(results)
    case .noConnection: showNoConnection()
    case .failed: showError()
    }
}
```

The class unsyncs the queries automatically when doing a new query over the same `query` object, or on the `deinit` of the class. It also buffers the last used query so results don't disappear before next response arrives.

In case the app crashes or closes before unsyncing these subscriptions, on launch we call `SyncManager.shared.purgeDisposableQueries()` and unsubscribes all pending disposable subscriptions.

### SyncQuery
A query subcription wrapper class. It gives us a handy API like:

```
let query = SyncQuery<User>(query: { $0.filter("username = 'john'") })
query.sync()

// Or
query.sync(notify: .indefinetly) { [weak self] result in
    guard let self = self else { return }
    switch result {
    case .synced(let results): print(results.count)
    case .noConnection: print("no connection")
    case .failed: print("error")
    }
}

// to unsubscribe
query.unsync()
```

## Example

In the example, we do a user search using a `DisposableSyncQuery`. We also change the Status Bar color depending on the `syncStatus`: clear for `synced`, yellow for `syncing` and red when `notSynced`. Please refer to the attached gif:

![](example.gif)
