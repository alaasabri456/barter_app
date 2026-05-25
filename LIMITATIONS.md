# Project Limitations

This section outlines the technical, data, scope, scalability, security, and resource limitations of the Barter Application prototype. Documenting these constraints is critical for understanding the current operational boundaries of the system and outlining concrete directions for future production-level development.

---

## 1. Technical Limitations

### 1.1. High Client-Side Processing and Memory Overhead
*   **Description**: Image uploads require reading full-resolution media files from the device storage, converting them into Base64-encoded strings within the application memory space, and transmitting them over a standard HTTP POST request.
*   **Rationale**: Direct client-to-ImgBB API integration was selected to keep the backend serverless. However, this approach bypasses chunked file streaming and intermediate server-side compression, leading to significant RAM usage peaks. On lower-end mobile devices, this can trigger Out-of-Memory (OOM) crashes during multi-image listings.
*   **Future Directions**: Migrate the file-upload pipeline to direct multipart stream uploading to Firebase Cloud Storage, coupled with background Cloud Functions to handle image compression, resizing, and WebP format conversion.

### 1.2. Native Platform Dependencies
*   **Description**: Key hardware-dependent features—specifically location tracking (Geolocator API), image capture/cropping, and background push notifications (Firebase Cloud Messaging)—rely on native platform channels.
*   **Rationale**: As a cross-platform Flutter application, the codebase abstracts operating-system-specific tasks via plugins. However, background execution limits, power-saving mode restrictions, and permission model updates on newer Android (API level 33+) and iOS versions introduce variance in notification delivery and background sync reliability.
*   **Future Directions**: Implement robust state-restoration handlers, include local database fallbacks (e.g., SQLite or Hive) to queue transactions offline, and construct custom native platform handlers for strict background task synchronization.

---

## 2. Data Limitations

### 2.1. Spatial Querying and Geolocation Precision
*   **Description**: Search and filtering based on user proximity rely on raw GPS coordinates, without advanced spatial indexes or distance joins.
*   **Rationale**: Google Cloud Firestore, a NoSQL document database, does not natively support spatial querying capabilities (like SQL `ST_Distance`). While bounding box queries can be simulated, searching for nearby items requires either downloading a large set of coordinates to filter client-side or building highly complex composite indexes.
*   **Future Directions**: Integrate a geospatial indexing library like Geohashes (e.g., `geoflutterfire`) or offload location-based index searching to a dedicated service like Algolia or Elasticsearch.

### 2.2. Placeholders in Billing and Transaction Metadata
*   **Description**: Integrated payment metadata sent to the Paymob gateway uses hardcoded values (e.g., phone defaulted to `"0123456789"` and address attributes set to `"NA"`).
*   **Rationale**: To streamline the user check-out flow for an academic sandbox demonstration, comprehensive billing forms were omitted. However, this prevents the payment provider from conducting real-time geographic validation or fraud risk scoring.
*   **Future Directions**: Implement a dedicated checkout wizard that captures, validates, and stores official billing data, ensuring compliance with international payment standards and anti-money laundering (AML) regulations.

### 2.3. Absence of Image Content Moderation
*   **Description**: The system accepts and renders user-uploaded product images without verifying the legitimacy, safety, or quality of the content.
*   **Rationale**: Designing and training an image moderation model or paying for a third-party moderation API (like Google Cloud Vision or AWS Rekognition) fell outside the core scope and budget of this graduation project.
*   **Future Directions**: Incorporate server-side hooks that trigger lightweight image classification APIs to detect duplicate listings, classify appropriate categories, and automatically flag offensive or copyright-infringing content.

---

## 3. Scope Limitations

### 3.1. Manual Agent-Based Delivery Infrastructure
*   **Description**: The delivery subsystem operates on a manual, self-reported dashboard. A "delivery agent" must manually claim orders and update statuses via the application's admin interfaces.
*   **Rationale**: Commercial shipping API integration (e.g., DHL, FedEx, or Aramex) requires commercial registration, deposit accounts, and production credentials, which were inaccessible for this prototype.
*   **Future Directions**: Integrate third-party logistics (3PL) aggregators or official APIs to fetch live shipping rates, automate delivery label creation, and receive webhook updates directly from shipping carriers.

### 3.2. Binary Trade Proposals Without Automated Valuation
*   **Description**: The barter negotiation module is restricted to simple peer-to-peer offers (binary accept/reject responses), lacking automated trade suggestions or value verification.
*   **Rationale**: The implementation prioritizes establishing secure channels for user exchange rather than designing automated value-matching engines.
*   **Future Directions**: Implement a machine learning model to estimate item market values based on category, description, and condition. The model can suggest fair counter-offers or calculate the exact "cash top-up" required to balance asymmetric trades.

---

## 4. Scalability Limitations

### 4.1. Firestore Operational Cost and Read/Write Limits
*   **Description**: Real-time streams (chats, notifications, trade status updates) depend on continuous Firestore active listeners, creating a high volume of document reads.
*   **Rationale**: Firebase Firestore charging is directly tied to the number of document reads, writes, and deletes. While scalable in performance, this architecture scales operating costs linearly with user interactions, making it financially unsustainable for high-concurrency public systems without a caching layer.
*   **Future Directions**: Transition high-velocity operations (like real-time chat messaging and notification badges) to a WebSocket server or a Redis-backed in-memory database to decouple real-time communication costs from Firestore.

### 4.2. Concurrency and Distributed Lock Constraints
*   **Description**: Simultaneous trade offers or checkout actions on the same product may lead to race conditions if multiple users attempt to finalize transactions concurrently.
*   **Rationale**: The prototype performs updates using direct client-side requests. Without backend-enforced queues, double-allocation of an item could occur under high transaction concurrency.
*   **Future Directions**: Enforce strict optimistic concurrency checks by using Firestore database transactions (`runTransaction`) and moving trade completion logic to server-validated Firebase Cloud Functions.

---

## 5. Security & Privacy Limitations

### 5.1. Client-Side Payment Tokenization and Configuration Secrets
*   **Description**: Secret keys and gateway parameters are initialized directly in the client application configuration files rather than being masked by a backend proxy.
*   **Rationale**: A serverless client-direct model was implemented to minimize infrastructure management and response latency.
*   **Future Directions**: Migrate checkout token generation to a secure cloud function or backend controller, ensuring that payment gateway secret keys are never exposed within the decompiled mobile application binary.

### 5.2. Lack of Two-Factor Authentication and Session Auditing
*   **Description**: User authentication relies on standard password or Google Sign-In options without additional multi-factor validation (MFA) or session auditing.
*   **Rationale**: Development prioritized standard user onboarding experiences; adding complex multi-step security challenges was out of scope.
*   **Future Directions**: Enable Firebase multi-factor authentication (MFA) via SMS/Email verification and implement IP-based session logging to alert users of suspicious logins.

---

## 6. Time and Resource Constraints

### 6.1. Limited Real-World Network and Device Testing
*   **Description**: System verification was conducted on emulators and a small pool of local physical devices connected to stable developer networks.
*   **Rationale**: Graduation project timelines and budget constraints restricted the execution of wide-scale physical field testing, multi-user concurrency stress tests, or tests under low-bandwidth networks (e.g., 2G/3G connections).
*   **Future Directions**: Deploy the application to a wider group of beta testers using Google Play Console (Internal Testing) or Apple TestFlight to collect telemetry on battery usage, network timeout handling, and user interface responsiveness across various screen sizes.
