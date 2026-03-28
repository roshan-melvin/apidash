### About

1. Full Name: Roshan Melvin G A
2. Contact info (public email): rocroshanga@gmail.com
3. Discord handle in our server (mandatory): roshanmelvin
4. Home page (if any): N/A
5. Blog (if any): N/A
6. GitHub profile link: https://github.com/roshan-melvin 
7. Twitter, LinkedIn, other socials: https://www.linkedin.com/in/roshan-melvin-tyech5/
8. Time zone: IST (UTC +5:30)
9. Link to a resume: https://drive.google.com/file/d/195X3Ix5Q1sqyCQkNf_FjvrRBmP6azFIO/view?usp=sharing

### University Info

1. University name: Sri Sairam Engineering College
2. Program you are enrolled in: Bachelor of Engineering in Computer Science and Engineering with specialization Internet of Things
3. Year: 3rd year
4. Expected graduation date: 2027

### Motivation & Past Experience

1. **Have you worked on or contributed to a FOSS project before? Can you attach repo links or relevant PRs?**
   Yes. My most significant open-source contribution so far has been working heavily on API Dash. I have implemented a massive architectural update to add support for multiple new protocols including gRPC, WebSockets, and MQTT (PR [#1529](https://github.com/foss42/apidash/pull/1529)). This PR establishes the core foundation for this GSoC proposal.

   [PLACEHOLDER - Add any other open-source projects or links you've worked on]

2. **What is your one project/achievement that you are most proud of? Why?**
   [PLACEHOLDER - Write a short paragraph about your proudest achievement, it could be a past project, an internship, or even the protocol PR itself.]

3. **What kind of problems or challenges motivate you the most to solve them?**
   [PLACEHOLDER - e.g., I love solving complex architectural problems and building seamless tools for developers. Integrating diverse network protocols natively into a clean Flutter UI motivates me because...]

4. **Will you be working on GSoC full-time? In case not, what will you be studying or working on while working on the project?**
   [PLACEHOLDER - Yes, I will be working full-time on GSoC committing 30-40 hours a week...]

5. **Do you mind regularly syncing up with the project mentors?**
   Not at all. In fact, I highly encourage it to ensure we stay aligned on architectural decisions and project milestones.

6. **What interests you the most about API Dash?**
   I appreciate API Dash's mission to provide a high-quality, open-source alternative to tools like Postman, written entirely in Flutter. Building developer tooling is fascinating, and expanding API Dash beyond standard REST into a Universal API Client is an exciting technical challenge.

7. **Can you mention some areas where the project can be improved?**
   Currently, API Dash is predominantly a REST and GraphQL client. In a modern development landscape, developers frequently interact with microservices (gRPC), real-time services (WebSockets, SSE), and IoT brokers (MQTT). Incorporating native, robust support for these protocols is the biggest area for improvement, which is exactly what my proposal addresses.

8. **Have you interacted with and helped API Dash community? (GitHub/Discord links)**
   - I have actively participated in the development of the multi-protocol support feature.
   - [PLACEHOLDER - Add links to your Discord messages, issues, or PRs]

### Project Proposal Information

1. **Proposal Title:** Universal API Client: Integrating gRPC, WebSockets, and MQTT

2. **Abstract:**
   As modern architectures evolve, developers increasingly rely on non-REST protocols like gRPC for microservices, WebSockets for real-time web applications, and MQTT for IoT. Currently, developers have to switch between multiple specialized tools to test these different endpoints. This project aims to transform API Dash into a true "Universal API Client" by introducing native, first-class support for gRPC, WebSockets, and MQTT. The project involves building the underlying network communication layers, state management, and intuitive Flutter user interfaces to craft, send, and inspect these diverse requests seamlessly within the API Dash workspace.

3. **Detailed Description:**

   **The Problem:**
   Testing different network protocols usually means fragmented workflows. A developer might use Postman for REST, a CLI tool like `grpcurl` for gRPC, a browser extension for WebSockets, and a desktop tool like MQTT Explorer for MQTT. This context-switching reduces productivity.

   **Project Demonstration & Videos:**
   You can view the full working demonstration of the three protocols and the UI changes in the custom Drive folder linked below:
   [Watch Demonstration Videos Here](https://drive.google.com/drive/folders/1Z7EYSo1tfBuiQFm4gLXbVxEF2iwIC9iV?usp=sharing)

   **High-Level Architecture:**
   The implementation relies heavily on extending the Riverpod state models. Each protocol gets a dedicated request model, keeping the state modular while reusing existing visual components where possible.
   
   ![Architecture Diagram](./images/architecture_diagram.png)

   **What I Will Build:**
   Building on my initial PR (#1529) that established the architectural groundwork, I will fully implement and polish support for three new protocols:

   **1. gRPC Support:**
   ![gRPC UI Flow](./images/grpc_ui_flow.png)
   
   *   Implementing full support for Unary, Client Streaming, Server Streaming, and Bidirectional Streaming calls.
   *   UI to dynamically load and parse `.proto` files via Server Reflection or manual upload.
   *   Rich request body editors tailored for gRPC message structures.

   **2. WebSocket Support:**
   ![WebSocket UI Flow](./images/websocket_ui_flow.png)

   *   A persistent, interactive terminal-like interface to continuously send and receive messages.
   *   Connection lifecycle management (Connect, Disconnect, Reconnect).
   *   Support for headers and query parameters during the initial handshake.

   **3. MQTT Support:**
   ![MQTT UI Flow](./images/mqtt_ui_flow.png)

   *   Comprehensive broker connection configurations (Client ID, Keep Alive, Clean Session, Authentication, TLS/SSL).
   *   A publisher interface with QoS (Quality of Service) and Retain flag settings.
   *   A subscription manager to view topics, incoming payloads, and a real-time message stream.
   *   Will message configuration support.

   **State Management & Persistence:**
   ![State Management Diagram](./images/state_management.png)

   *   Expanding Riverpod providers to handle the persistent state of real-time connections without blocking the main UI thread.
   *   Extending Hive database models to save, load, and organize these new request types.

4. **Weekly Timeline:**

   **Community Bonding (Weeks 1-2):**
   *   Finalize the specific UI/UX designs with the mentors for the new protocol panes.
   *   Merge and resolve any outstanding conflicts on PR #1529.
   *   Set up automated testing environments for local gRPC and MQTT servers to be used during development.

   **Weeks 3-5: WebSockets Implementation & Polish:**
   *   Finalize WebSocket connection lifecycle management.
   *   Implement the real-time message stream UI.
   *   Add connection persistence and error handling.
   *   Write unit and integration tests for WS logic.

   **Weeks 6-8: gRPC Implementation & Polish:**
   *   Integrate Server Reflection for dynamic method discovery.
   *   Implement the `.proto` file upload and parsing logic.
   *   Complete the UI for executing Unary and Streaming calls.
   *   Write comprehensive tests for gRPC services.

   **Weeks 9-11: MQTT Implementation & Polish:**
   *   Solidify the Broker connection UI and background service.
   *   Implement the Subscription manager and real-time message viewing.
   *   Implement Publisher with QoS and Retain flags.
   *   Test against various public and local MQTT brokers.

   **Week 12: Final Review, Documentation & Buffer:**
   *   Buffer week for any unexpected bugs or complex edge-cases with real-time state management.
   *   Comprehensive testing across all supported platforms (Linux, macOS, Windows).
   *   Writing user documentation for the new protocols to be added to `doc/user_guide/`.
   *   Finalizing the GSoC submission and merging all final code into the main branch.
