public struct TeamEconomy: Codable, Equatable, Sendable {
    public let metal: Double
    public let income: Double
    public let supplyUsed: Int
    public let supplyCap: Int

    public init(metal: Double, income: Double, supplyUsed: Int, supplyCap: Int) {
        self.metal = metal
        self.income = income
        self.supplyUsed = supplyUsed
        self.supplyCap = supplyCap
    }
}
