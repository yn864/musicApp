import SwiftData

let musicAppSchema = Schema([
    SwiftDataSong.self,
    SwiftDataAlbum.self,
    SwiftDataArtist.self
])

let musicAppConfiguration = ModelConfiguration(
    schema: musicAppSchema,
    // isStoredInMemoryOnly: false - данные сохраняются на устройстве, а не только в памяти
    isStoredInMemoryOnly: false
    // version: 1,
    // migrationPlan: MyMigrationPlan.self
    // ...
)

func createMusicAppContainer() throws -> ModelContainer {
    return try ModelContainer(for: musicAppSchema, configurations: [musicAppConfiguration])
}
