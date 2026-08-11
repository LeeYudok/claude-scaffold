---
paths:
  - "src/main/java/**/*.java"
  - "src/test/java/**/*.java"
---

# Spring Boot / 백엔드 규칙

- **Java {{JAVA_VERSION}} (= Java 8) → Spring Boot 2.7.x 계열** (3.x는 Java 17+ 필요하므로 사용 불가).
- 빌드툴 **Gradle** (`./gradlew`).
- 레이어드 아키텍처: `controller` → `service` → `repository`. 컨트롤러에 비즈니스 로직 금지.
- 의존성 주입은 **생성자 주입**(필드 주입 금지), lombok `@RequiredArgsConstructor`.
- 요청 DTO는 Bean Validation(`@Valid`, `@NotNull` 등)으로 검증.
- 시크릿·DB 비번은 `application.yml` 하드코딩 금지 → 환경변수/`.env`.
- 응답에 엔티티 직접 노출 금지 → DTO 변환. 비번/해시/토큰 필드 제외.
