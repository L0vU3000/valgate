# Valgate Shared Types (Swift)

Swift Codable structs generated from the Valgate OpenAPI spec.

## Usage

Import into iOS app:
```swift
import ValgateSharedTypes
```

## Generation

```bash
# From repo root
openapi-generator generate -i packages/api-spec/valgate-api-v1.yaml \
  -g swift5 -o packages/shared-types/swift/Sources
```

## Status

🚧 Placeholder — types will be generated from API spec once it's extracted.
