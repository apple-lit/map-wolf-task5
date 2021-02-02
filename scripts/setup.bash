#!/bin/bash

if [! which mint >/dev/null]; then
	brew install mint
fi
mint install realm/SwiftLint@0.38.0
mint install apple/swift-format@0.50300.0
mint install SwiftGen/SwiftGen
mint install yonaskolb/xcodegen