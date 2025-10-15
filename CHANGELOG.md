## 2.0.0

> Note: This release has breaking changes.

 - **FIX**: tests timeout.
 - **FIX**: tests timeout.
 - **FIX**: tests timeout.
 - **FIX**: test concurrency on ci.
 - **FIX**: build deps.
 - **FIX**: authorization provider path.
 - **FEAT**: add authorization provider.
 - **BREAKING** **CHANGE**: add connection pool.

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