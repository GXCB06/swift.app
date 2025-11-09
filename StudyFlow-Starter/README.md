StudyFlow iOS Starter (SwiftUI)

Overview
--------
This is a small SwiftUI starter scaffold for StudyFlow (Timer → Reflection → Efficiency Score). Drop these Swift files into a new Xcode iOS project (SwiftUI) targeting iOS 16+ and run on a simulator or device.

What's included
---------------
- `StudyFlowApp.swift` — App entry, environment object wiring
- `Models/Session.swift` — Session model
- `Models/Reflection.swift` — Reflection model
- `Views/DashboardView.swift` — Simple dashboard to view sessions and start timer
- `Views/TimerView.swift` — Timer UI (start/stop)
- `Views/ReflectionView.swift` — 3-second reflection UI + submit
- `Storage/LocalStore.swift` — Simple in-memory local store (ObservableObject)
- `Networking/APIClient.swift` — Network stubs (async/await)
- `Utils/EfficiencyCalculator.swift` — Efficiency score formula

How to use
----------
1. Open Xcode and create a new project: iOS > App > SwiftUI, Product Name: StudyFlow (or any name). Set Interface: SwiftUI, Language: Swift.
2. Set the project deployment target to iOS 16.0 or later.
3. Copy the `Sources` files from this folder into your Xcode project's file navigator (or add the whole `StudyFlow-Starter` folder).
4. Build and run.

Notes & next steps
------------------
- This scaffold uses an in-memory `LocalStore`. For a production app, replace with GRDB/CoreData/Realm and implement sync logic.
- Networking is stubbed; implement your REST API and token storage.
- Use SQLCipher or built-in iOS encryption for sensitive local data.

Recommended next deliverables I can create:
- GRDB local store integration + migrations
- Vapor starter backend with auth & sessions
- OpenAPI spec for REST endpoints

GRDB Integration (example)
-------------------------
To switch the scaffold to a persistent SQLite-backed store using GRDB, add the GRDB Swift package in Xcode:

1. In Xcode, File > Add Packages... and add: https://github.com/groue/GRDB.swift
2. Choose a GRDB release (e.g., `~> 5.0`) and add it to your app target.
3. See `Storage/GRDBStore.swift` for a small example DB setup and simple save/fetch helpers that store models as JSON.

Example usage (quick):

```swift
import GRDB

// Create DB in application support
let dbPath = try FileManager.default
	.urls(for: .applicationSupportDirectory, in: .userDomainMask)
	.first!
	.appendingPathComponent("studyflow.sqlite").path

let grdb = try GRDBStore(path: dbPath)
try grdb.saveSession(sampleSession)
let sessions = try grdb.fetchSessions()
```

Notes:
- This example stores models as JSON in SQLite to keep the mapping straightforward; for production you can map model properties to columns for query efficiency.
- Make sure to perform DB writes on a background queue or via GRDB's `DatabaseWriter` APIs.


