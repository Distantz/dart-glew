<!-- 
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/tools/pub/writing-package-pages). 

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/to/develop-packages). 
-->

# Glew
Glew simplifies state management by taking a unified approach to server and client model code. Write once in Dart for both, or implement a server in any language; changes are communicated using consistent and readable JSON. Glew draws heavy inspiration from the library Mirror Networking for Unity.

## Features
- State tracking, including creation, destruction and changes to model objects.
- An easy to extend interface for creating your own trackable types/fields.
- Uses a form of delta compression, so only differences are sent.
- Special wrapper for model references, with lookups based on UUIDs.
  - This allows references to persist over both network and disk save/loads.

## Getting started
Simply install the package. The base package is for Dart specifically, but Flutter-specific code is planned to go into it's own small package.

## Usage

TODO: Include short and useful examples for package users. Add longer examples
to `/example` folder. 

```dart
const like = 'sample';
```

## Additional information
Glew wants to "glue" your server and client code together. Of course, networking code is also a bit "ew" so that's why it's named Glew!
