struct FishData {
    static let fishList: [Fish] = [
        Fish(
            id: 1,
            name: "Gold Fish",
            rarity: .common,
            totalTimeNeeded: 60,
            cost: 0,
            eggSprite: "gold_egg",
            frySprite: "gold_fry",
            adultSprite: "gold_fish"
        ),
        Fish(
            id: 2,
            name: "Carp",
            rarity: .common,
            totalTimeNeeded: 120,
            cost: 100,
            eggSprite: "carp_egg",
            frySprite: "carp_fry",
            adultSprite: "carp_fish"
        ),
        Fish(
            id: 3,
            name: "Beta",
            rarity: .rare,
            totalTimeNeeded: 180,
            cost: 200,
            eggSprite: "beta_egg",
            frySprite: "beta_fry",
            adultSprite: "beta_fish"
        )
    ]
}
