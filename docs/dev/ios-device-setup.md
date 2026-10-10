# iOS device setup (free Apple ID)

Lab M0 використовує **Personal Team** (безплатний Apple ID), не Apple Developer Program ($99).

## Вимоги

- macOS з **Xcode.app** (не лише Command Line Tools)
- Apple ID
- iPhone (рекомендовано для подальших сенсорних фіч)

## Перший Run на телефон

1. Відкрити `DeadReconTaxi.xcodeproj` у Xcode.
2. **Xcode → Settings → Accounts** → додати Apple ID.
3. Target **DeadReconTaxi** → **Signing & Capabilities**:
   - Automatically manage signing = On
   - Team = Personal Team
4. Підключити iPhone USB (або мережевий debugging після першого pairing).
5. Обрати девайс як Run destination → **Run** (⌘R).
6. На iPhone:
   - **Settings → Privacy & Security → Developer Mode** → увімкнути (з’явиться після першої спроби встановлення з Xcode).
   - **Settings → General → VPN & Device Management** → Trust профіль Apple ID.

## Обмеження free provisioning

- Профіль/сертифікат ~**7 днів** — після цього app не відкриється, поки знову не зробите Run з Xcode.
- До ~3 apps на пристрій, до ~3 пристроїв (ліміти Apple Personal Team).
- Немає TestFlight / App Store.

## Simulator

Для UI shell достатньо Simulator. Core Motion / реальний GPS — лише на device (наступні фічі).

## Troubleshooting

| Симптом | Дія |
|---|---|
| `xcodebuild` / simctl: «requires Xcode» | Встановити Xcode.app; `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer` |
| Untrusted Developer | Trust у VPN & Device Management |
| Signing error Bundle ID | Унікальний Bundle ID `ua.deadrecon.taxi` (або змінити в target) |
