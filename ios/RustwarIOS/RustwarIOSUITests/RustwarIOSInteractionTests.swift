import XCTest

final class RustwarIOSInteractionTests: XCTestCase {
    private struct Entity: Decodable {
        let id: String
        let x: Double
        let y: Double
        let order: String?
        let hp: Double?
        let rendered: Bool
        let queue: Int?
        let upgrading: Bool?
        let type: String?
        let nodeID: String?
        let progress: Double?
    }

    private struct Resource: Decodable {
        let id: String
        let x: Double
        let y: Double
        let rendered: Bool
        let claimedBy: Int?
        let guide: String?
    }

    private struct Projection: Decodable {
        let originX: Double
        let originY: Double
        let xDX: Double
        let xDY: Double
        let yDX: Double
        let yDY: Double

        var determinant: Double { xDX * yDY - yDX * xDY }

        func point(_ x: Double, _ y: Double) -> CGVector {
            CGVector(dx: originX + x * xDX + y * yDX, dy: originY + x * xDY + y * yDY)
        }

        func worldPosition(_ entity: Entity) -> (x: Double, y: Double) {
            let dx = entity.x - originX
            let dy = entity.y - originY
            return ((dx * yDY - dy * yDX) / determinant, (xDX * dy - xDY * dx) / determinant)
        }
    }

    private struct Snapshot: Decodable {
        let selected: [String]
        let units: [Entity]
        let buildings: [Entity]
        let resources: [Resource]
        let metal: Double
        let cameraX: Double
        let cameraY: Double
        let zoom: Double
        let pending: Bool
        let unitArtTypes: Int
        let buildingArtVariants: Int
        let resourceArtVariants: Int
        let explosionArtFrames: Int
        let projection: Projection

        func entity(_ id: String) -> Entity? { (units + buildings).first { $0.id == id } }
    }

    @MainActor
    private func launch(lowMetal: Bool = false, tech2: Bool = false, centeredUnit: Bool = false,
                        stationaryDefense: Bool = false, commandCenterVisible: Bool = false,
                        navigationObstacle: Bool = false, woundedUnit: Bool = false,
                        closeOpponents: Bool = false, heavySquad: Bool = false,
                        resourceBuild: Bool = false) async throws -> XCUIApplication {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launchArguments = ["--rustwar-ci-interaction-tests", "-AppleLanguages", "(zh-Hans)", "-AppleLocale", "zh_CN"]
        if lowMetal { app.launchArguments.append("--rustwar-ci-low-metal") }
        if tech2 { app.launchArguments.append("--rustwar-ci-factory-tech2") }
        if centeredUnit { app.launchArguments.append("--rustwar-ci-centered-unit") }
        if stationaryDefense { app.launchArguments.append("--rustwar-ci-stationary-defense") }
        if commandCenterVisible { app.launchArguments.append("--rustwar-ci-visible-command-center") }
        if navigationObstacle { app.launchArguments.append("--rustwar-ci-navigation-obstacle") }
        if woundedUnit { app.launchArguments.append("--rustwar-ci-wounded-unit") }
        if closeOpponents { app.launchArguments.append("--rustwar-ci-close-opponents") }
        if heavySquad { app.launchArguments.append("--rustwar-ci-heavy-squad") }
        if resourceBuild { app.launchArguments.append("--rustwar-ci-resource-build") }
        app.launch()
        XCTAssertTrue(battlefield(app).waitForExistence(timeout: 15))
        try await waitFor(app, "fixture and rendered anchors loaded") {
            $0.units.count == 4 && $0.entity("input-tank")?.rendered == true &&
                $0.entity("input-builder")?.rendered == true && $0.entity("input-factory")?.rendered == true
        }
        XCTAssertGreaterThan(abs(try snapshot(app).projection.determinant), 0.000_000_000_001)
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
    private func waitFor(_ app: XCUIApplication, _ message: String, attempts: Int = 80,
                         predicate: (Snapshot) -> Bool) async throws {
        for _ in 0..<attempts {
            if let state = try? snapshot(app), predicate(state) { return }
            try await Task.sleep(for: .milliseconds(100))
        }
        XCTFail("Timed out: \(message). Battlefield: \(String(describing: battlefield(app).value))")
    }

    @MainActor
    private func tapEntity(_ id: String, in app: XCUIApplication) throws {
        let entity = try XCTUnwrap(snapshot(app).entity(id))
        XCTAssertTrue(entity.rendered, "A real tap must target an entity drawn by SpriteKit")
        XCTAssertTrue((0.05...0.95).contains(entity.x) && (0.05...0.95).contains(entity.y))
        battlefield(app).coordinate(withNormalizedOffset: CGVector(dx: entity.x, dy: entity.y)).tap()
    }

    @MainActor
    private func worldCoordinate(_ x: Double, _ y: Double, in app: XCUIApplication) throws -> XCUICoordinate {
        let field = battlefield(app)
        let point = try snapshot(app).projection.point(x, y)
        return field.coordinate(withNormalizedOffset: point)
    }

    @MainActor
    private func assertFullyVisible(_ button: XCUIElement, in app: XCUIApplication,
                                    file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(button.exists, file: file, line: line)
        XCTAssertTrue(button.isHittable, "No scrolling should be needed: \(button.identifier)", file: file, line: line)
        let viewport = app.scrollViews["command-dock-scroll"].frame
        XCTAssertTrue(viewport.contains(button.frame), "Card clipped: \(button.frame), viewport \(viewport)", file: file, line: line)
        XCTAssertGreaterThanOrEqual(button.frame.height, 44, file: file, line: line)
    }

    @MainActor
    func testMineralDepositBuildGuidesAndExtractorRemainPlayable() async throws {
        let app = try await launch(resourceBuild: true)
        XCTAssertEqual(try snapshot(app).resourceArtVariants, 4, "All real mineral patches must decode; geometry fallback cannot satisfy this gate")
        try await waitFor(app, "mineral patch actually rendered") {
            $0.resources.first?.rendered == true && $0.resources.first?.claimedBy == nil
        }
        let resource = try XCTUnwrap(snapshot(app).resources.first)
        XCTAssertEqual(resource.id, "input-resource")
        XCTAssertTrue((0.05...0.95).contains(resource.x) && (0.05...0.95).contains(resource.y))
        let resourcePoint = battlefield(app).coordinate(withNormalizedOffset: CGVector(dx: resource.x, dy: resource.y))
        let initialMetal = try snapshot(app).metal
        try tapEntity("input-builder", in: app)
        try await waitFor(app, "Builder selected") { $0.selected == ["input-builder"] }
        let build = app.buttons["建造提取器"]
        assertFullyVisible(build, in: app)
        build.tap()
        try await waitFor(app, "real placement mode draws an available mineral guide") {
            $0.pending && $0.resources.first?.guide == "available"
        }
        resourcePoint.tap()
        try await waitFor(app, "real resource tap pays 260 and creates exactly one extractor") {
            !$0.pending && abs($0.metal - (initialMetal - 260)) < 0.01 &&
                $0.entity("input-builder")?.order == "build" && $0.resources.first?.claimedBy == 0 &&
                $0.buildings.filter { $0.nodeID == resource.id && $0.type == "extractor" }.count == 1
        }
        let extractor = try XCTUnwrap(snapshot(app).buildings.first { $0.nodeID == resource.id })
        XCTAssertEqual(extractor.progress, 0, "Paused placement must not fake construction progress")
        build.tap()
        try await waitFor(app, "claimed resource changes the actual renderer guide to occupied") {
            $0.pending && $0.resources.first?.guide == "occupied"
        }
        resourcePoint.tap()
        try await waitFor(app, "occupied deposit refuses a duplicate without payment or lost target mode") {
            $0.pending && abs($0.metal - (initialMetal - 260)) < 0.01 &&
                $0.buildings.filter { $0.nodeID == resource.id }.count == 1 &&
                $0.entity("input-builder")?.order == "build"
        }
        app.buttons["取消提取器放置"].tap()
        try await waitFor(app, "cancel hides placement guide but preserves the paid construction order") {
            !$0.pending && $0.resources.first?.guide == nil && $0.entity("input-builder")?.order == "build"
        }
        app.buttons["继续"].tap()
        try await waitFor(app, "normal simulation completes the real ten-second construction", attempts: 160) {
            $0.entity(extractor.id)?.progress == 1 && $0.entity(extractor.id)?.rendered == true &&
                $0.entity("input-builder")?.order == "idle"
        }
        app.buttons["暂停"].tap()
        try tapEntity(extractor.id, in: app)
        try await waitFor(app, "completed extractor selected through its real model") { $0.selected == [extractor.id] }
        let upgrade = app.buttons["升级资源提取器"]
        assertFullyVisible(upgrade, in: app)
        let beforeUpgrade = try snapshot(app).metal
        upgrade.tap()
        try await waitFor(app, "extractor upgrade uses the real 650-metal action") {
            $0.entity(extractor.id)?.upgrading == true && abs($0.metal - (beforeUpgrade - 650)) < 0.01
        }
        let cancelUpgrade = app.buttons["取消提取器升级"]
        assertFullyVisible(cancelUpgrade, in: app)
        cancelUpgrade.tap()
        try await waitFor(app, "paused upgrade cancellation refunds its unchanged progress") {
            $0.entity(extractor.id)?.upgrading == false && abs($0.metal - beforeUpgrade) < 0.01
        }
        try tapEntity("input-builder", in: app)
        try worldCoordinate(1_500, 1_880, in: app).tap()
        try await waitFor(app, "fresh Builder movement after mineral build and upgrade controls") {
            $0.entity("input-builder")?.order == "move"
        }
        print("MINERAL_BUILD variants=4 firstScreenBuild/availableGuide/pay260/occupiedGuide/duplicateReject/naturalCompletion/upgrade650/refund/freshMove=passed")
    }

    @MainActor
    func testFourDigitSquadHealthStaysReadableWithFirstScreenOrders() async throws {
        let app = try await launch(heavySquad: true)
        try tapEntity("input-tank", in: app)
        app.buttons["command-select-area"].tap()
        let start = try worldCoordinate(1_390, 1_840, in: app)
        let end = try worldCoordinate(1_510, 1_780, in: app)
        start.press(forDuration: 0.05, thenDragTo: end)
        try await waitFor(app, "two real Heavy Tanks selected with four-digit squad health") {
            Set($0.selected) == Set(["input-tank", "input-wing"]) && !$0.pending
        }
        let health = app.descendants(matching: .any).matching(identifier: "selection-health").firstMatch
        XCTAssertTrue(health.exists)
        XCTAssertEqual(health.value as? String, "当前生命 1040，上限 1040")
        XCTAssertLessThanOrEqual(health.frame.height, 18, "Normal-size health must remain a single caption line")
        XCTAssertGreaterThan(health.frame.width, 60, "Do not hide the numeric health to pass the height gate")
        for command in ["移动", "进攻移动", "攻击", "停止", "command-select-area", "选择同类单位"] {
            assertFullyVisible(app.buttons.matching(identifier: command).firstMatch, in: app)
        }
        try worldCoordinate(1_550, 1_740, in: app).tap()
        try await waitFor(app, "readable squad HUD still issues real movement to both units") {
            $0.entity("input-tank")?.order == "move" && $0.entity("input-wing")?.order == "move"
        }
        print("FOUR_DIGIT_HEALTH height=\(health.frame.height) value=1040/1040 firstScreenOrders=6 realSquadMove=passed")
    }

    @MainActor
    func testChineseHUDAndLayeredArtRemainPlayable() async throws {
        let app = try await launch()
        XCTAssertEqual(try snapshot(app).unitArtTypes, 8, "Every bundled layered model must decode; fallback art cannot satisfy this gate")
        XCTAssertEqual(try snapshot(app).buildingArtVariants, 9, "All building tiers and the independent turret layers must decode; geometry fallback cannot satisfy this gate")
        XCTAssertEqual(try snapshot(app).explosionArtFrames, 8, "The actual explosion atlas must decode all animation frames")
        XCTAssertEqual(app.buttons["pause-play"].label, "继续")
        let metal = app.descendants(matching: .any).matching(identifier: "status-metric-metal").firstMatch
        XCTAssertEqual(metal.label, "金属")

        try tapEntity("input-tank", in: app)
        let before = try snapshot(app)
        app.buttons.matching(identifier: "移动").firstMatch.tap()
        try await waitFor(app, "Chinese Move opens the real target mode") { $0.pending }
        let clear = app.buttons["selection-clear"]
        assertFullyVisible(clear, in: app)
        XCTAssertEqual(clear.label, "取消选择")
        clear.tap()
        try await waitFor(app, "clear cancels targeting without issuing an order") {
            $0.selected.isEmpty && !$0.pending && $0.entity("input-tank")?.order == "idle"
        }
        XCTAssertEqual(try snapshot(app).metal, before.metal)

        try tapEntity("input-tank", in: app)
        try worldCoordinate(1_550, 1_740, in: app).tap()
        try await waitFor(app, "fresh direct ground tap still issues ordinary Move") {
            $0.entity("input-tank")?.order == "move"
        }
        app.buttons["selection-clear"].tap()
        try await waitFor(app, "deselecting must not stop a moving unit") {
            $0.selected.isEmpty && $0.entity("input-tank")?.order == "move"
        }
        try tapEntity("input-factory", in: app)
        let card = app.buttons["produce-tank"]
        assertFullyVisible(card, in: app)
        XCTAssertTrue(card.label.contains("轻型坦克"))
        card.tap()
        try await waitFor(app, "Chinese unit card queues a real paid production order") {
            $0.entity("input-factory")?.queue == 1 && $0.metal < before.metal
        }
        print("CHINESE_LAYERED_ART units=8 buildings=9 realClear/targetCancel/orderPreserved/freshMove/paidProduction=passed")
    }

    @MainActor
    func testFriendlyTapWinsOverAdjacentEnemyHalo() async throws {
        let app = try await launch(closeOpponents: true)
        let initial = try snapshot(app)
        let wing = try XCTUnwrap(initial.entity("input-wing"))
        let enemy = try XCTUnwrap(initial.entity("input-enemy"))
        XCTAssertTrue(wing.rendered && enemy.rendered)
        let frame = battlefield(app).frame
        let separation = hypot((wing.x - enemy.x) * Double(frame.width), (wing.y - enemy.y) * Double(frame.height))
        XCTAssertGreaterThan(separation, 23, "Actual models must be distinct")
        XCTAssertLessThan(separation, 28, "Enemy touch halo must cover the friendly center")
        XCTAssertEqual(initial.zoom, 0.7, accuracy: 0.01)
        try tapEntity("input-tank", in: app)
        try await waitFor(app, "initial Tank selected before close target switch") { $0.selected == ["input-tank"] }
        try tapEntity("input-wing", in: app)
        try await waitFor(app, "friendly model wins over adjacent enemy halo") { $0.selected == ["input-wing"] }
        let switched = try snapshot(app)
        XCTAssertEqual(switched.entity("input-tank")?.order, "idle")
        XCTAssertEqual(switched.entity("input-wing")?.order, "idle")
        XCTAssertEqual(switched.entity("input-enemy")?.hp, enemy.hp)
        try tapEntity("input-enemy", in: app)
        try await waitFor(app, "actual enemy tap still issues manual Attack") {
            $0.selected == ["input-wing"] && $0.entity("input-wing")?.order == "attack"
        }
        let health = try XCTUnwrap(enemy.hp)
        app.buttons["继续"].tap()
        try await waitFor(app, "manual Attack damages enemy while other units Hold Fire") {
            ($0.entity("input-enemy")?.hp ?? 0) < health
        }
        app.buttons["暂停"].tap()
        let damaged = try XCTUnwrap(snapshot(app).entity("input-enemy")?.hp)
        XCTAssertLessThan(damaged, health)
        try tapEntity("input-builder", in: app)
        try await waitFor(app, "fresh Builder selection after close fighting") { $0.selected == ["input-builder"] }
        try worldCoordinate(1_520, 1_890, in: app).tap()
        try await waitFor(app, "fresh Builder Move after close fighting") { $0.entity("input-builder")?.order == "move" }
        print("ADJACENT_ENEMY_SELECTION separation=\(separation) zoom=\(initial.zoom) enemyHP=\(health)->\(damaged) friendlySelect/manualAttack/freshBuilder=passed")
    }

    @MainActor
    func testSelectedForceHealthAndOrdersRemainVisible() async throws {
        let app = try await launch(woundedUnit: true)
        try tapEntity("input-tank", in: app)
        try await waitFor(app, "real wounded Tank selected") { $0.selected == ["input-tank"] }
        let health = app.descendants(matching: .any).matching(identifier: "selection-health").firstMatch
        XCTAssertTrue(health.waitForExistence(timeout: 5))
        XCTAssertEqual(health.value as? String, "当前生命 122，上限 245")
        XCTAssertEqual(try snapshot(app).entity("input-tank")?.hp, 122)
        for command in ["移动", "进攻移动", "攻击", "停止", "command-select-area", "选择同类单位"] {
            assertFullyVisible(app.buttons.matching(identifier: command).firstMatch, in: app)
        }
        app.buttons["command-select-area"].tap()
        try await waitFor(app, "area mode before squad console") { $0.pending }
        let start = try worldCoordinate(1_390, 1_840, in: app)
        let end = try worldCoordinate(1_510, 1_780, in: app)
        start.press(forDuration: 0.05, thenDragTo: end)
        try await waitFor(app, "two Tanks selected for real squad summary") {
            Set($0.selected) == Set(["input-tank", "input-wing"]) && !$0.pending
        }
        XCTAssertEqual(health.value as? String, "当前生命 367，上限 490")
        let composition = app.descendants(matching: .any).matching(identifier: "selection-type-tank").firstMatch
        XCTAssertTrue(composition.exists)
        XCTAssertEqual(composition.value as? String, "2")
        for command in ["移动", "进攻移动", "攻击", "停止", "command-select-area", "选择同类单位"] {
            assertFullyVisible(app.buttons.matching(identifier: command).firstMatch, in: app)
        }
        app.buttons.matching(identifier: "移动").firstMatch.tap()
        try await waitFor(app, "real squad Move waits for target") { $0.pending }
        let cancel = app.buttons["取消移动目标"]
        assertFullyVisible(cancel, in: app)
        assertFullyVisible(app.buttons.matching(identifier: "停止").firstMatch, in: app)
        cancel.tap()
        try await waitFor(app, "target cancellation keeps squad selected") {
            !$0.pending && Set($0.selected) == Set(["input-tank", "input-wing"])
        }
        try worldCoordinate(1_540, 1_740, in: app).tap()
        try await waitFor(app, "direct tap still moves the selected squad") {
            $0.entity("input-tank")?.order == "move" && $0.entity("input-wing")?.order == "move"
        }
        let stop = app.buttons.matching(identifier: "停止").firstMatch
        assertFullyVisible(stop, in: app)
        stop.tap()
        try await waitFor(app, "real Stop clears both squad orders") {
            $0.entity("input-tank")?.order == "idle" && $0.entity("input-wing")?.order == "idle"
        }
        print("SELECTED_FORCE_CONSOLE singleHP=122/245 squadHP=367/490 tanks=2 firstScreenOrders=6 cancelAndStop=passed")
    }

    @MainActor
    func testRenderedUnitDetoursAroundBuildingAndArrives() async throws {
        let app = try await launch(navigationObstacle: true)
        try await waitFor(app, "actual turret obstacle rendered") { $0.entity("input-obstacle")?.rendered == true }
        try tapEntity("input-tank", in: app)
        try await waitFor(app, "rendered routing Tank selected") { $0.selected == ["input-tank"] }
        try worldCoordinate(1_580, 1_810, in: app).tap()
        try await waitFor(app, "real Move crosses the obstacle's line") { $0.entity("input-tank")?.order == "move" }
        app.buttons["继续"].tap()
        var maximumDetour = 0.0
        var observed = 0
        var arrived = false
        for _ in 0..<100 {
            let state = try snapshot(app)
            let tank = try XCTUnwrap(state.entity("input-tank"))
            XCTAssertTrue(tank.rendered)
            let point = state.projection.worldPosition(tank)
            let dx = max(0, abs(point.x - 1_500) - 24)
            let dy = max(0, abs(point.y - 1_810) - 24)
            XCTAssertGreaterThanOrEqual(dx * dx + dy * dy, 14.5 * 14.5, "Actual hull overlaps the turret")
            maximumDetour = max(maximumDetour, abs(point.y - 1_810))
            observed += 1
            if tank.order == "idle" {
                XCTAssertEqual(point.x, 1_580, accuracy: 1)
                XCTAssertEqual(point.y, 1_810, accuracy: 1)
                arrived = true
                break
            }
            try await Task.sleep(for: .milliseconds(100))
        }
        XCTAssertTrue(arrived, "Tank must arrive at the originally tapped point")
        XCTAssertGreaterThan(maximumDetour, 35, "The real model must visibly travel around the obstacle")
        print("NAVIGATION_DETOUR samples=\(observed) maximumOffset=\(maximumDetour) arrival=1580,1810")
        app.buttons["暂停"].tap()
        try tapEntity("input-builder", in: app)
        try await waitFor(app, "fresh Builder selected after actual detour") { $0.selected == ["input-builder"] }
        try worldCoordinate(1_520, 1_890, in: app).tap()
        try await waitFor(app, "fresh Move after actual detour") { $0.entity("input-builder")?.order == "move" }
    }

    @MainActor
    func testTankTapGroundAutomaticallyEngagesEnemy() async throws {
        let app = try await launch()
        try tapEntity("input-tank", in: app)
        try await waitFor(app, "tank selected") { $0.selected == ["input-tank"] }
        try worldCoordinate(1_540, 1_740, in: app).tap()
        try await waitFor(app, "ground tap issues ordinary move") { $0.entity("input-tank")?.order == "move" }
        let health = try XCTUnwrap(snapshot(app).entity("input-enemy")?.hp)
        app.buttons["继续"].tap()
        try await waitFor(app, "ordinary move damages enemy through simulation") {
            ($0.entity("input-enemy")?.hp ?? 0) < health
        }
        try await waitFor(app, "unit reaches the requested waypoint without chasing") {
            $0.entity("input-tank")?.order == "idle"
        }
        let after = try snapshot(app)
        let tank = try XCTUnwrap(after.entity("input-tank"))
        let position = after.projection.worldPosition(tank)
        XCTAssertEqual(position.x, 1_540, accuracy: 1)
        XCTAssertEqual(position.y, 1_740, accuracy: 1)
    }

    @MainActor
    func testStopRetainsStationaryInRangeDefense() async throws {
        let app = try await launch(stationaryDefense: true)
        try tapEntity("input-tank", in: app)
        try await waitFor(app, "defender selected") { $0.selected == ["input-tank"] }
        try worldCoordinate(1_540, 1_740, in: app).tap()
        try await waitFor(app, "move before stop") { $0.entity("input-tank")?.order == "move" }
        let stop = app.buttons.matching(identifier: "停止").firstMatch
        XCTAssertTrue(stop.isHittable)
        stop.tap()
        try await waitFor(app, "stop clears movement") { $0.entity("input-tank")?.order == "idle" }
        let before = try snapshot(app)
        let defender = try XCTUnwrap(before.entity("input-tank"))
        let health = try XCTUnwrap(before.entity("input-enemy")?.hp)
        app.buttons["继续"].tap()
        try await waitFor(app, "stopped defender fires through real simulation") {
            ($0.entity("input-enemy")?.hp ?? 0) < health
        }
        let after = try snapshot(app)
        let stationary = try XCTUnwrap(after.entity("input-tank"))
        XCTAssertEqual(stationary.order, "idle")
        XCTAssertEqual(stationary.x, defender.x, accuracy: 0.001)
        XCTAssertEqual(stationary.y, defender.y, accuracy: 0.001)
        XCTAssertEqual(after.selected, ["input-tank"])
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
    func testRenderedSelectionAndVerticalPanFollowTheFinger() async throws {
        let app = try await launch()
        let initial = try snapshot(app)
        let builder = try XCTUnwrap(initial.entity("input-builder"))
        let tank = try XCTUnwrap(initial.entity("input-tank"))
        XCTAssertGreaterThan(builder.y, tank.y + 0.15, "The real renderer places this Builder below the Tank")
        try tapEntity("input-builder", in: app)
        try await waitFor(app, "actual rendered Builder tap selects it") { $0.selected == ["input-builder"] }
        let before = try snapshot(app)
        let field = battlefield(app)
        field.coordinate(withNormalizedOffset: CGVector(dx: 0.6, dy: 0.35))
            .press(forDuration: 0.05, thenDragTo: field.coordinate(withNormalizedOffset: CGVector(dx: 0.6, dy: 0.48)))
        try await waitFor(app, "downward drag moves the rendered battlefield with the finger") {
            $0.cameraY < before.cameraY - 20 && ($0.entity("input-builder")?.y ?? 0) > builder.y + 0.08
        }
        let after = try snapshot(app)
        print("RENDERED_VERTICAL_PAN builderY=\(builder.y)->\(after.entity("input-builder")?.y ?? -1) cameraY=\(before.cameraY)->\(after.cameraY)")
        XCTAssertEqual(after.cameraX, before.cameraX, accuracy: 1)
        XCTAssertEqual(after.entity("input-builder")?.order, "idle")
        XCTAssertEqual(after.entity("input-tank")?.order, "idle")
        try tapEntity("input-tank", in: app)
        try await waitFor(app, "fresh rendered Tank tap after vertical pan") { $0.selected == ["input-tank"] }
        try worldCoordinate(1_540, 1_740, in: app).tap()
        try await waitFor(app, "real ground tap after vertical pan") { $0.entity("input-tank")?.order == "move" }
    }

    @MainActor
    func testProductionCardsReflectQueueProgressAndCancellation() async throws {
        let app = try await launch(tech2: true)
        try tapEntity("input-factory", in: app)
        try await waitFor(app, "factory selected for live card feedback") { $0.selected == ["input-factory"] }
        let tank = app.buttons["produce-tank"]
        let scout = app.buttons["produce-scout"]
        let cancel = app.buttons["撤销队尾生产订单"]
        for type in ["scout", "tank", "hover", "artillery", "aaTank", "heavyTank"] {
            assertFullyVisible(app.buttons["produce-\(type)"], in: app)
        }
        let metal = try snapshot(app).metal
        tank.tap()
        tank.tap()
        scout.tap()
        try await waitFor(app, "three real production actions and per-type card counts") {
            $0.entity("input-factory")?.queue == 3 && abs($0.metal - (metal - 450)) < 0.01 &&
                (tank.value as? String)?.contains("排队 2 辆") == true &&
                (scout.value as? String)?.contains("排队 1 辆") == true
        }
        XCTAssertTrue((tank.value as? String)?.contains("生产进度 0%") == true)
        assertFullyVisible(cancel, in: app)
        cancel.tap()
        try await waitFor(app, "cancel last refunds Scout and clears only its card count") {
            $0.entity("input-factory")?.queue == 2 && abs($0.metal - (metal - 360)) < 0.01 &&
                (scout.value as? String)?.contains("排队 0 辆") == true &&
                (tank.value as? String)?.contains("排队 2 辆") == true
        }
        cancel.tap()
        try await waitFor(app, "cancel second Light Tank refunds and updates its live count") {
            $0.entity("input-factory")?.queue == 1 && abs($0.metal - (metal - 180)) < 0.01 &&
                (tank.value as? String)?.contains("排队 1 辆") == true
        }
        app.buttons["继续"].tap()
        try await waitFor(app, "normal production clock advances the current card") {
            let value = tank.value as? String ?? ""
            return $0.entity("input-factory")?.queue == 1 &&
                value.range(of: "生产进度 [1-9][0-9]?%", options: .regularExpression) != nil
        }
        app.buttons["暂停"].tap()
        let progressValue = tank.value as? String ?? ""
        XCTAssertNotNil(progressValue.range(of: "生产进度 [1-9][0-9]?%", options: .regularExpression))
        for type in ["scout", "tank", "hover", "artillery", "aaTank", "heavyTank"] {
            assertFullyVisible(app.buttons["produce-\(type)"], in: app)
        }
        try tapEntity("input-builder", in: app)
        try await waitFor(app, "fresh Builder selected after queue controls") { $0.selected == ["input-builder"] }
        try worldCoordinate(1_520, 1_890, in: app).tap()
        try await waitFor(app, "fresh Builder Move after production feedback") { $0.entity("input-builder")?.order == "move" }
        print("PRODUCTION_CARD_FEEDBACK initial=Light2/Scout1 cancelled=Scout1/Light1 refunds=90/180 current=\(progressValue) firstScreenCards=6 freshBuilder=passed")
    }

    @MainActor
    func testFactoryTapShowsProductionAndQueuesUnit() async throws {
        let app = try await launch()
        try tapEntity("input-factory", in: app)
        try await waitFor(app, "factory selected") { $0.selected == ["input-factory"] }
        let scout = app.buttons["produce-scout"]
        XCTAssertTrue(scout.waitForExistence(timeout: 5))
        assertFullyVisible(scout, in: app)
        XCTAssertTrue(scout.isEnabled)
        let metal = try snapshot(app).metal
        scout.tap()
        try await waitFor(app, "production queue and charge") {
            $0.entity("input-factory")?.queue == 1 && $0.metal == metal - 90
        }
    }

    @MainActor
    func testCommandCenterShowsAndQueuesBuilderThenFreshMoveWorks() async throws {
        let app = try await launch(commandCenterVisible: true)
        try await waitFor(app, "command center actually rendered") { $0.entity("input-command")?.rendered == true }
        try tapEntity("input-command", in: app)
        try await waitFor(app, "command center selected") { $0.selected == ["input-command"] }
        let builderCard = app.buttons["produce-builder"]
        assertFullyVisible(builderCard, in: app)
        XCTAssertTrue(builderCard.label.contains("工程车"))
        let before = try snapshot(app)
        let oldQueue = try XCTUnwrap(before.entity("input-command")?.queue)
        builderCard.tap()
        try await waitFor(app, "real command-center action queues a Builder and spends 180") {
            $0.entity("input-command")?.queue == oldQueue + 1 && abs($0.metal - (before.metal - 180)) < 0.01
        }
        let existingIDs = Set(before.units.map(\.id))
        app.buttons["继续"].tap()
        try await waitFor(app, "queued Builder completes and is actually drawn", attempts: 160) {
            $0.entity("input-command")?.queue == oldQueue &&
                $0.units.contains { !existingIDs.contains($0.id) && $0.rendered }
        }
        app.buttons["暂停"].tap()
        let completed = try snapshot(app)
        let produced = try XCTUnwrap(completed.units.first { !existingIDs.contains($0.id) })
        XCTAssertTrue(produced.rendered)
        try tapEntity(produced.id, in: app)
        try await waitFor(app, "newly produced Builder selected through its rendered model") { $0.selected == [produced.id] }
        try worldCoordinate(1_550, 1_890, in: app).tap()
        try await waitFor(app, "newly produced Builder accepts a ground Move") { $0.entity(produced.id)?.order == "move" }
        app.buttons["继续"].tap()
        try await waitFor(app, "newly produced Builder reaches the actual tapped destination") {
            $0.entity(produced.id)?.order == "idle"
        }
        app.buttons["暂停"].tap()
        let arrived = try snapshot(app)
        let position = arrived.projection.worldPosition(try XCTUnwrap(arrived.entity(produced.id)))
        XCTAssertEqual(position.x, 1_550, accuracy: 1)
        XCTAssertEqual(position.y, 1_890, accuracy: 1)
        print("COMMAND_CENTER_BUILDER id=\(produced.id) queue=\(oldQueue + 1)->\(oldQueue) arrived=\(position.x),\(position.y)")
        try tapEntity("input-builder", in: app)
        try await waitFor(app, "fresh Builder selected after command-center production") { $0.selected == ["input-builder"] }
        try worldCoordinate(1_510, 1_890, in: app).tap()
        try await waitFor(app, "fresh Builder moves after command-center production") { $0.entity("input-builder")?.order == "move" }
    }

    @MainActor
    func testFactoryUpgradeUsesRealAction() async throws {
        let app = try await launch()
        try tapEntity("input-factory", in: app)
        try await waitFor(app, "factory selected") { $0.selected == ["input-factory"] }
        let upgrade = app.buttons["将陆军工厂升级至 T2"]
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
        assertFullyVisible(scout, in: app)
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
        let save = app.buttons["保存编队 1"]
        XCTAssertTrue(save.isHittable)
        save.tap()
        XCTAssertTrue(app.buttons["召回编队 1"].isEnabled)
        app.buttons["dock-navigation-selection"].tap()
        let builders = app.buttons["选择空闲工程车"]
        XCTAssertTrue(builders.isHittable)
        builders.tap()
        try await waitFor(app, "selection tools action") { $0.selected == ["input-builder"] }
        app.buttons["dock-navigation-session"].tap()
        XCTAssertTrue(app.buttons["保存对局"].isHittable)
        try tapEntity("input-factory", in: app)
        try await waitFor(app, "new factory selection") { $0.selected == ["input-factory"] }
        XCTAssertTrue(app.buttons["将陆军工厂升级至 T2"].isHittable)
        app.buttons["dock-navigation-groups"].tap()
        app.buttons["dock-navigation-orders"].tap()
        XCTAssertTrue(app.buttons["将陆军工厂升级至 T2"].isHittable)
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
            $0.entity("input-tank")?.order == "move" && $0.entity("input-wing")?.order == "move"
        }
    }

    @MainActor
    func testFactoryPaletteAndUpgradeVisibleWithoutScrolling() async throws {
        let app = try await launch()
        try tapEntity("input-factory", in: app)
        try await waitFor(app, "factory selected") { $0.selected == ["input-factory"] }
        for unit in ["scout", "tank", "hover", "artillery", "aaTank"] {
            assertFullyVisible(app.buttons["produce-\(unit)"], in: app)
        }
        assertFullyVisible(app.buttons["将陆军工厂升级至 T2"], in: app)
    }

    @MainActor
    func testStatusResourcesVisibleBeforeAndAfterFactoryFocus() async throws {
        let app = try await launch()
        for factoryFocused in [false, true] {
            if factoryFocused {
                try tapEntity("input-factory", in: app)
                try await waitFor(app, "factory selected") { $0.selected == ["input-factory"] }
            }
            let viewport = app.scrollViews["status-metrics"].frame
            XCTAssertGreaterThan(viewport.width, 300, "Resource strip collapsed behind speed control")
            for metric in ["metal", "income", "pop", "radar"] {
                let element = app.descendants(matching: .any)
                    .matching(identifier: "status-metric-\(metric)").firstMatch
                XCTAssertTrue(element.exists)
                XCTAssertGreaterThan(element.frame.width, 20)
                XCTAssertTrue(viewport.contains(element.frame), "Resource hidden: \(metric)")
            }
            XCTAssertTrue(app.buttons["继续"].isHittable)
        }
    }

    @MainActor
    func testTech2PaletteQueuesHeavyThenReturnsToBattlefield() async throws {
        let app = try await launch(tech2: true)
        try tapEntity("input-factory", in: app)
        try await waitFor(app, "T2 factory selected") { $0.selected == ["input-factory"] }
        for unit in ["scout", "tank", "hover", "artillery", "aaTank", "heavyTank"] {
            assertFullyVisible(app.buttons["produce-\(unit)"], in: app)
        }
        app.buttons["produce-heavyTank"].tap()
        try await waitFor(app, "heavy queued through actual button") {
            $0.entity("input-factory")?.queue == 1 && $0.metal == 4_580
        }
        try tapEntity("input-tank", in: app)
        try await waitFor(app, "production panel does not trap selection") { $0.selected == ["input-tank"] }
        try worldCoordinate(1_540, 1_740, in: app).tap()
        try await waitFor(app, "fresh ground command after production") { $0.entity("input-tank")?.order == "move" }
    }

    @MainActor
    func testPinchZoomDoesNotIssueOrdersAndFreshTapWorks() async throws {
        let app = try await launch()
        try tapEntity("input-tank", in: app)
        try await waitFor(app, "tank selected") { $0.selected == ["input-tank"] }
        let before = try snapshot(app)
        battlefield(app).pinch(withScale: 1.3, velocity: 1)
        print("PINCH_TOUCH_TRACE \(String(describing: battlefield(app).value))")
        try await waitFor(app, "real two-finger pinch changes camera and renderer") {
            $0.zoom > before.zoom * 1.1 && abs($0.projection.xDX) > abs(before.projection.xDX) * 1.1
        }
        let after = try snapshot(app)
        XCTAssertLessThan(after.zoom, before.zoom * 1.6, "A small pinch must not launch the camera")
        XCTAssertEqual(after.selected, ["input-tank"])
        XCTAssertEqual(after.entity("input-tank")?.order, "idle")
        try tapEntity("input-builder", in: app)
        try await waitFor(app, "fresh tap after pinch") { $0.selected == ["input-builder"] }
        try worldCoordinate(1_520, 1_890, in: app).tap()
        try await waitFor(app, "fresh command after pinch") { $0.entity("input-builder")?.order == "move" }
    }

    @MainActor
    func testTwoFingerTapDoesNotIssueOrdersAndFreshTapWorks() async throws {
        let app = try await launch(centeredUnit: true)
        try tapEntity("input-builder", in: app)
        try await waitFor(app, "builder selected") { $0.selected == ["input-builder"] }
        let before = try snapshot(app)
        battlefield(app).twoFingerTap()
        try await waitFor(app, "two-finger corners select the centered tank") {
            $0.selected.contains("input-tank") && !$0.selected.contains("input-builder")
        }
        let after = try snapshot(app)
        XCTAssertEqual(after.entity("input-tank")?.order, "idle")
        XCTAssertEqual(after.entity("input-wing")?.order, "idle")
        XCTAssertEqual(after.cameraX, before.cameraX)
        XCTAssertEqual(after.cameraY, before.cameraY)
        XCTAssertEqual(after.zoom, before.zoom)
        try tapEntity("input-builder", in: app)
        try await waitFor(app, "fresh tap after two-finger release") { $0.selected == ["input-builder"] }
        try worldCoordinate(1_520, 1_890, in: app).tap()
        try await waitFor(app, "fresh command after two-finger release") { $0.entity("input-builder")?.order == "move" }
    }
}
