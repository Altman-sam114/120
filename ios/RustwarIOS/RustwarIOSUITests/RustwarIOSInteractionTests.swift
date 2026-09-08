import XCTest

final class RustwarIOSInteractionTests: XCTestCase {
    private struct Entity: Decodable {
        let id: String
        let x: Double
        let y: Double
        let order: String?
        let hp: Double?
        let queue: Int?
        let upgrading: Bool?
    }

    private struct Snapshot: Decodable {
        let selected: [String]
        let units: [Entity]
        let buildings: [Entity]
        let metal: Double
        let cameraX: Double
        let cameraY: Double
        let zoom: Double
        let pending: Bool

        func entity(_ id: String) -> Entity? { (units + buildings).first { $0.id == id } }
    }

    @MainActor
    private func launch(lowMetal: Bool = false) async throws -> XCUIApplication {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launchArguments = ["--rustwar-ci-interaction-tests", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        if lowMetal { app.launchArguments.append("--rustwar-ci-low-metal") }
        app.launch()
        XCTAssertTrue(battlefield(app).waitForExistence(timeout: 15))
        try await waitFor(app, "fixture loaded") { $0.units.count == 4 }
        XCTAssertGreaterThan(app.frame.width, app.frame.height)
        return app
    }

    @MainActor
    private func battlefield(_ app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: "battlefield").firstMatch
    }

    @MainActor
    private func snapshot(_ app: XCUIApplication) throws -> Snapshot {
        let value = try XCTUnwrap(battlefield(app).value as? String)
        return try JSONDecoder().decode(Snapshot.self, from: Data(value.utf8))
    }

    @MainActor
    private func waitFor(_ app: XCUIApplication, _ message: String, predicate: (Snapshot) -> Bool) async throws {
        for _ in 0..<80 {
            if let state = try? snapshot(app), predicate(state) { return }
            try await Task.sleep(for: .milliseconds(100))
        }
        XCTFail("Timed out: \(message). Battlefield: \(String(describing: battlefield(app).value))")
    }

    @MainActor
    private func tapEntity(_ id: String, in app: XCUIApplication) throws {
        let entity = try XCTUnwrap(snapshot(app).entity(id))
        XCTAssertTrue((0.05...0.95).contains(entity.x) && (0.05...0.95).contains(entity.y))
        battlefield(app).coordinate(withNormalizedOffset: CGVector(dx: entity.x, dy: entity.y)).tap()
    }

    @MainActor
    private func worldCoordinate(_ x: Double, _ y: Double, in app: XCUIApplication) throws -> XCUICoordinate {
        let state = try snapshot(app)
        let field = battlefield(app)
        let point = CGVector(dx: 0.5 + (x - state.cameraX) * state.zoom / Double(field.frame.width),
                             dy: 0.5 - (y - state.cameraY) * state.zoom / Double(field.frame.height))
        return field.coordinate(withNormalizedOffset: point)
    }

    @MainActor
    func testTankTapGroundAutomaticallyEngagesEnemy() async throws {
        let app = try await launch()
        try tapEntity("input-tank", in: app)
        try await waitFor(app, "tank selected") { $0.selected == ["input-tank"] }
        try worldCoordinate(1_540, 1_740, in: app).tap()
        try await waitFor(app, "ground tap issues attack move") { $0.entity("input-tank")?.order == "attackMove" }
        let health = try XCTUnwrap(snapshot(app).entity("input-enemy")?.hp)
        app.buttons["Play"].tap()
        try await waitFor(app, "attack move damages enemy through simulation") {
            ($0.entity("input-enemy")?.hp ?? 0) < health
        }
    }

    @MainActor
    func testBuilderTapGroundIssuesMove() async throws {
        let app = try await launch()
        try tapEntity("input-builder", in: app)
        try await waitFor(app, "builder selected") { $0.selected == ["input-builder"] }
        try worldCoordinate(1_520, 1_890, in: app).tap()
        try await waitFor(app, "builder move") { $0.entity("input-builder")?.order == "move" }
        XCTAssertEqual(try snapshot(app).entity("input-tank")?.order, "idle")
    }

    @MainActor
    func testDragPansWithoutOrdersAndFreshTapWorks() async throws {
        let app = try await launch()
        try tapEntity("input-tank", in: app)
        try await waitFor(app, "tank selected") { $0.selected == ["input-tank"] }
        let before = try snapshot(app)
        let field = battlefield(app)
        field.coordinate(withNormalizedOffset: CGVector(dx: 0.48, dy: 0.3))
            .press(forDuration: 0.05, thenDragTo: field.coordinate(withNormalizedOffset: CGVector(dx: 0.63, dy: 0.3)))
        try await waitFor(app, "camera pan") { abs($0.cameraX - before.cameraX) > 20 }
        XCTAssertEqual(try snapshot(app).entity("input-tank")?.order, "idle")
        try tapEntity("input-wing", in: app)
        try await waitFor(app, "fresh tap after pan") { $0.selected == ["input-wing"] }
    }

    @MainActor
    func testFactoryTapShowsProductionAndQueuesUnit() async throws {
        let app = try await launch()
        try tapEntity("input-factory", in: app)
        try await waitFor(app, "factory selected") { $0.selected == ["input-factory"] }
        let scout = app.buttons["produce-scout"]
        XCTAssertTrue(scout.waitForExistence(timeout: 5))
        if !scout.isHittable { app.scrollViews["command-dock-scroll"].swipeUp() }
        XCTAssertTrue(scout.isEnabled)
        let metal = try snapshot(app).metal
        scout.tap()
        try await waitFor(app, "production queue and charge") {
            $0.entity("input-factory")?.queue == 1 && $0.metal == metal - 90
        }
    }

    @MainActor
    func testFactoryUpgradeUsesRealAction() async throws {
        let app = try await launch()
        try tapEntity("input-factory", in: app)
        try await waitFor(app, "factory selected") { $0.selected == ["input-factory"] }
        let upgrade = app.buttons["Upgrade land factory to tech level 2"]
        XCTAssertTrue(upgrade.waitForExistence(timeout: 5))
        XCTAssertTrue(upgrade.isEnabled)
        upgrade.tap()
        try await waitFor(app, "upgrade queued and charged") {
            $0.entity("input-factory")?.upgrading == true && $0.metal < 5_000
        }
    }

    @MainActor
    func testUnavailableProductionDoesNotQueue() async throws {
        let app = try await launch(lowMetal: true)
        try tapEntity("input-factory", in: app)
        try await waitFor(app, "factory selected") { $0.selected == ["input-factory"] }
        let scout = app.buttons["produce-scout"]
        XCTAssertTrue(scout.waitForExistence(timeout: 5))
        if !scout.isHittable { app.scrollViews["command-dock-scroll"].swipeUp() }
        XCTAssertFalse(scout.isEnabled)
        scout.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        XCTAssertEqual(try snapshot(app).entity("input-factory")?.queue, 0)
        XCTAssertEqual(try snapshot(app).metal, 0)
    }

    @MainActor
    func testDockNavigationAndFactoryRefocus() async throws {
        let app = try await launch()
        try tapEntity("input-tank", in: app)
        try await waitFor(app, "tank selected") { $0.selected == ["input-tank"] }
        app.buttons["dock-navigation-groups"].tap()
        let save = app.buttons["Save control group 1"]
        XCTAssertTrue(save.isHittable)
        save.tap()
        XCTAssertTrue(app.buttons["Recall control group 1"].isEnabled)
        app.buttons["dock-navigation-selection"].tap()
        let builders = app.buttons["Select idle Builders"]
        XCTAssertTrue(builders.isHittable)
        builders.tap()
        try await waitFor(app, "selection tools action") { $0.selected == ["input-builder"] }
        app.buttons["dock-navigation-session"].tap()
        XCTAssertTrue(app.buttons["Save game"].isHittable)
        try tapEntity("input-factory", in: app)
        try await waitFor(app, "new factory selection") { $0.selected == ["input-factory"] }
        XCTAssertTrue(app.buttons["Upgrade land factory to tech level 2"].isHittable)
        app.buttons["dock-navigation-groups"].tap()
        app.buttons["dock-navigation-orders"].tap()
        XCTAssertTrue(app.buttons["Upgrade land factory to tech level 2"].isHittable)
    }

    @MainActor
    func testAreaSelectionThenGroundOrder() async throws {
        let app = try await launch()
        let selectArea = app.buttons["command-select-area"]
        XCTAssertTrue(selectArea.waitForExistence(timeout: 5))
        selectArea.tap()
        try await waitFor(app, "area mode active") { $0.pending }
        let start = try worldCoordinate(1_390, 1_840, in: app)
        let end = try worldCoordinate(1_510, 1_780, in: app)
        start.press(forDuration: 0.05, thenDragTo: end)
        try await waitFor(app, "two tanks selected") { Set($0.selected) == Set(["input-tank", "input-wing"]) && !$0.pending }
        try worldCoordinate(1_540, 1_740, in: app).tap()
        try await waitFor(app, "fresh ground order after area selection") {
            $0.entity("input-tank")?.order == "attackMove" && $0.entity("input-wing")?.order == "attackMove"
        }
    }
}
