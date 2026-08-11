---
paths:
  - "src/main/java/**/*.java"
  - "src/test/java/**/*.java"
---

# Spring Boot / Backend Rules

- **Java {{JAVA_VERSION}} (= Java 8) → Spring Boot 2.7.x line** (3.x requires Java 17+, so it cannot be used).
- Build tool: **Gradle** (`./gradlew`).
- Layered architecture: `controller` → `service` → `repository`. No business logic in controllers.
- Dependency injection via **constructor injection** (no field injection), lombok `@RequiredArgsConstructor`.
- Validate request DTOs with Bean Validation (`@Valid`, `@NotNull`, etc.).
- No hardcoding secrets/DB passwords in `application.yml` → use environment variables/`.env`.
- Do not expose entities directly in responses → convert to DTOs, excluding password/hash/token fields.
