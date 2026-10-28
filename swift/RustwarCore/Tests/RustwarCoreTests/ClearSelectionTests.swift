import Testing
@testable import RustwarCore

struct ClearSelectionTests {
    @Test func clearingSelectionPreservesOrdersAndSavedGroups() {
        var engine = GameEngine()
        let unit = engine.state.units.first { $0.team == .player }!
        engine.select(entityID: unit.id)
        engine.storeControlGroup(1)
        let destination = WorldPoint(unit.position.x + 80, unit.position.y)
        _ = engine.issueMove(to: destination)
        let before = engine.state

        engine.clearSelection()

        #expect(engine.state.selectedEntityID == nil)
        #expect(engine.state.selectedEntityIDs.isEmpty)
        #expect(engine.state.units == before.units)
        #expect(engine.state.buildings == before.buildings)
        #expect(engine.state.controlGroups == before.controlGroups)
        #expect(engine.state.metal == before.metal)
        #expect(engine.state.elapsed == before.elapsed)
    }

    @Test func clearingSelectionIsIdempotentAndFreshSelectionWorks() {
        var engine = GameEngine()
        engine.clearSelection()
        let empty = engine.state
        engine.clearSelection()
        #expect(engine.state == empty)
        let unit = engine.state.units.first { $0.team == .player }!
        engine.select(entityID: unit.id)
        #expect(engine.state.selectedEntityIDs == [unit.id])
    }
}
