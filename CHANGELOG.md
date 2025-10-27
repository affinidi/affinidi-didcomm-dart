## 2.0.3

 - **FIX**: close connections at the end of each test.
 - **FIX**: allow sequential connections.

## 2.0.2

 - **FIX**: code generation.
 - **FIX**: use compatible syncronized package.
 - **FIX**: add lock to prevent steam closing when messages are still processing.
 - **FIX**: use acl for tests and examples.

## 2.0.1

 - **FIX**: changelog after breaking changes.

## 2.0.0

> Note: This release has breaking changes.

**1. MediatorClient Refactoring**
- Introduced a new `MediatorClient.init` factory for easier and safer instantiation, handling key agreement and signer resolution internally.
- All authentication and access token logic is now handled via a new `AuthorizationProvider` abstraction.
- Methods like `sendMessage`, `fetchMessages`, `listInboxMessageIds`, etc., no longer require explicit access tokens; tokens are managed automatically.
- WebSocket connection management is now handled via a new `Connection` class and a singleton `ConnectionPool` for concurrent connections.

**2. AuthorizationProvider Abstraction**
- Added `AuthorizationProvider` and `AffinidiAuthorizationProvider` for pluggable, extensible token management.
- Token refresh and challenge-response authentication are now encapsulated and reusable.
- All mediator flows (REST and WebSocket) now support authenticated mediators out of the box.

**3. Connection & ConnectionPool**
- New `Connection` class manages a single WebSocket connection and message stream.
- New `ConnectionPool` singleton manages multiple concurrent connections, subscriptions, and lifecycle.
- **Important:** All mediator clients must be registered with the pool before calling `ConnectionPool.startConnections()`. Clients added after `startConnections()` will not be managed.

**4. API and Example Updates**
- All examples and tests updated to use the new `MediatorClient.init` and `AffinidiAuthorizationProvider.init` flows.
- Removed legacy extension-based authentication methods.
- Simplified message sending, receiving, and inbox management APIs.

**Migration Notes**

- Replace direct `MediatorClient` constructors with `MediatorClient.init`.
- Use `AffinidiAuthorizationProvider` for Affinidi mediator authentication.
- Use `ConnectionPool` for managing multiple concurrent WebSocket connections.
- Remove any manual access token handling in your code.

## 1.1.1

 - **FIX**: fetch by date and time.

## 1.1.0

 - **FEAT**: pass close code and reason to channel onDone method.

## 1.0.3

 - **FIX**: qeuery message.

## 1.0.2

 - **FIX**: running tests on windows.

## 1.0.1

 - **FIX**: release version.

## 1.0.0-dev.15

 - **FIX**: prevent from header  to be non null for anoncrypt.
 - **FEAT**: add packIntoAnoncryptAndAuthcryptMessages. check skid and apu to be null for anoncrypt.

## 1.0.0-dev.14

 - **FEAT**: delete messages on websockets.

## 1.0.0-dev.13

 - **FEAT**: add oob on mediator.
 - **FEAT**: fetch and delete messages.

## 1.0.0-dev.12

 - **FEAT**: add ping interval option to listenForIncomingMessages method (#59).

    * feat: add ping interval option to listenForIncomingMessages method
    
    * refactor: move ping interval to web socket options
    
    * refactor: use web socket options in toWebSocketChannel
    
    * refactor: remove nullable from pingIntervalInSeconds
    
    * docs: parameter description webSocketOptions


## 1.0.0-dev.11

 - **FEAT**: organize exports.

## 1.0.0-dev.10

 - **FEAT**: organzie package exports.

## 1.0.0-dev.9

 - **FIX**: update to latest dart ssi.

## 1.0.0-dev.8

 - **FIX**: analyzer issues.

## 1.0.0-dev.7

 - **FIX**: formatted.
 - **FIX**: doc added.
 - **FIX**: reverted #2.
 - **FIX**: reverted #1.
 - **FIX**: moved acl mgmt to extensions.
 - **FIX**: logs removed.
 - **FEAT**: test/examples constants updated.
 - **FEAT**: config file renamed.
 - **FEAT**: config file renamed.
 - **FEAT**: test evns vars updated.
 - **FEAT**: TEST_MEDIATOR_WITH_ACL_DID added.
 - **FEAT**: acl example added.
 - **FEAT**: forward message abstracted in mediator client.

## 1.0.0-dev.6

 - **FIX**: package publish.

## 1.0.0-dev.5

 - **FIX**: a256gcp should be used only for ecdh-es.
 - **FEAT**: add disclose message.
 - **FEAT**: add query message.

## 1.0.0-dev.4

 - **FIX**: use a256gcm only for anoncrypt.

## 1.0.0-dev.3

 - **FEAT**: support p384 and p521.

## 1.0.0-dev.2

 - **FEAT**: add problem report message.

## 1.0.0-dev.1

 - **FEAT**: initial release