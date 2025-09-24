import '../models/book.dart';

/// Original fictional demo metadata and short previews written for this app.
class SampleBooks {
  static List<Book> getAllBooks() => [
    Book(
      id: '1',
      title: 'The Lantern Between Towns',
      author: 'Mira Vale',
      coverImage: 'generated:midnight',
      description:
          'A lamp keeper helps two neighboring towns share a bridge after years of silence.',
      categoryIds: ['fiction', 'drama', 'classic'],
      createdAt: DateTime.utc(2026, 11, 18),
      content: '''
On the first evening of fog, Elian carried the brass lantern to the middle of the bridge. One town had painted its railings blue; the other had painted them green. At the center the colors met in a thin, unpainted line.

A child from each bank arrived with a match. Elian did not ask which town had sent them. He held the glass chimney steady while they lit the wick together, and for the first time in years both banks could see the same warm circle on the boards.
''',
    ),
    Book(
      id: '2',
      title: 'The Case of the Missing Mapmaker',
      author: 'Theo Finch',
      coverImage: 'generated:lagoon',
      description:
          'A patient archivist follows a trail of altered street maps to find a missing colleague.',
      categoryIds: ['short_stories', 'mystery', 'classic'],
      createdAt: DateTime.utc(2026, 11, 12),
      content: '''
Every map in the reading room showed a lane that did not exist. Iona checked the ink, the paper, and the dates. Each copy had been changed on a different morning, always in the same careful hand.

The absent mapmaker had left no note. But on the newest sheet Iona found a tiny compass rose with its north point facing the river instead of the hills. She folded the map, took her coat, and went to see what the river was hiding.
''',
    ),
    Book(
      id: '3',
      title: 'The Cloud Orchard',
      author: 'Nia Sol',
      coverImage: 'generated:coral',
      description:
          'A young gardener discovers that her village grows its rain in floating orchards.',
      categoryIds: ['fiction', 'fantasy', 'children'],
      createdAt: DateTime.utc(2026, 11, 3),
      content: '''
Mara planted a silver seed in a basket of moss and tied the basket to a kite. By noon it had risen above the rooftops, where the air was cool enough for the first pale leaves to open.

Her grandfather told her to listen before watering it. The leaves made a soft clinking sound. That meant the little tree was thirsty, and the village below would have rain by morning.
''',
    ),
    Book(
      id: '4',
      title: 'Letters from Cedar Pier',
      author: 'Mira Vale',
      coverImage: 'generated:sunrise',
      description:
          'Two boat builders exchange letters while restoring a pier for their coastal town.',
      categoryIds: ['short_stories', 'romance', 'classic'],
      createdAt: DateTime.utc(2026, 10, 27),
      content: '''
Nell found the first letter tucked beneath a new plank. It contained a sketch of the pier, three measurements, and one question: Would the bench face the sunrise?

She wrote her answer on the back of the sketch. For the next week the work moved forward by pencil marks and folded pages. When the bench was finally set in place, Ari was waiting there with two cups of tea.
''',
    ),
    Book(
      id: '5',
      title: "Tomorrow's Quiet Signal",
      author: 'Ivo Rell',
      coverImage: 'generated:forest',
      description:
          'An apprentice radio engineer deciphers a signal sent from a future weather station.',
      categoryIds: ['science_fiction', 'short_stories'],
      createdAt: DateTime.utc(2026, 10, 21),
      content: '''
At 6:14 each morning, the station received a burst of static lasting exactly eleven seconds. Tavi recorded it out of habit. On Thursday the pattern matched a storm warning that had not yet been issued.

The message did not name a place. It carried only pressure readings and the sound of a bell. Tavi marked every bell tower on the district map and began to plan a route before the clouds arrived.
''',
    ),
    Book(
      id: '6',
      title: 'The Last Ferry at Low Tide',
      author: 'Sera Quill',
      coverImage: 'generated:plum',
      description:
          'A ferry pilot races a closing channel to deliver a vital repair part to an island.',
      categoryIds: ['action_adventure', 'short_stories', 'thriller'],
      createdAt: DateTime.utc(2026, 10, 15),
      content: '''
The channel markers leaned hard in the wind. In less than an hour the tide would expose the stones beneath them, and the ferry would have to turn back.

Ren set the engine to its gentlest speed. The crate at her feet held one small copper valve. Across the water, the island's pump house was dark. She followed the narrow stripe of deep water and counted the markers aloud.
''',
    ),
    Book(
      id: '7',
      title: 'The Garden of Glass Moons',
      author: 'Nia Sol',
      coverImage: 'generated:midnight',
      description:
          'A caretaker tends tiny artificial moons that light a mountain greenhouse.',
      categoryIds: ['science_fiction', 'fantasy', 'classic'],
      createdAt: DateTime.utc(2026, 10, 7),
      content: '''
Each glass moon was no bigger than an orange. When Seli turned its copper ring, a soft light spread across the greenhouse roof and the sleeping vines uncurled.

One moon had gone dark overnight. Seli carried it to the workbench and found a thread of dust inside its lens. She cleaned the glass, reset the ring, and watched a row of blue flowers lift their heads.
''',
    ),
    Book(
      id: '8',
      title: 'The River Keeps Its Names',
      author: 'Ansel Reed',
      coverImage: 'generated:lagoon',
      description:
          'A courier crosses an imagined old kingdom to return lost place names to a river map.',
      categoryIds: ['action_adventure', 'historical_fiction', 'classic'],
      createdAt: DateTime.utc(2026, 9, 29),
      content: '''
The king's new map had one river and no villages. Dena's map was older, stitched from scraps of cloth, with a name beside every bend.

She traveled downstream in a narrow boat, asking the people on each bank how they called the water near their homes. At dusk she added another name with a needle and dark thread. The map grew heavier, but easier to trust.
''',
    ),
    Book(
      id: '9',
      title: 'Two Shadows at Noon',
      author: 'Theo Finch',
      coverImage: 'generated:coral',
      description:
          'A museum restorer untangles two conflicting accounts of a painting she has been asked to repair.',
      categoryIds: ['fiction', 'psychology', 'classic'],
      createdAt: DateTime.utc(2026, 9, 16),
      content: '''
The painting showed a courtyard at noon, yet both figures cast long shadows. Ada first thought the artist had made a mistake. Then she found a second sketch beneath the frame, with a different figure beside the fountain.

Her client remembered the courtyard one way; his sister remembered it another. Ada set her brush down. Before she could mend the canvas, she needed to know which memory the family wanted to keep.
''',
    ),
    Book(
      id: '10',
      title: 'The Archive of Small Weather',
      author: 'Ivo Rell',
      coverImage: 'generated:forest',
      description:
          'A city archivist stores local breezes and rainfall in a curious mechanical library.',
      categoryIds: ['science_fiction', 'short_stories'],
      createdAt: DateTime.utc(2026, 9, 4),
      content: '''
The archive kept weather in narrow brass drawers. One held the smell of a summer pavement after rain; another held a breeze from the market at dawn.

When the drawer marked Tuesday opened by itself, Lio heard a gust that had not happened yet. He checked the date wheel and found it set one day ahead. Outside, the sky was clear, so he took a notebook and went to the market.
''',
    ),
    Book(
      id: '11',
      title: "The Kite Makers' Trail",
      author: 'Sera Quill',
      coverImage: 'generated:sunrise',
      description:
          'Inventors guide a caravan through high winds with kites that chart safe paths.',
      categoryIds: ['science_fiction', 'fantasy', 'action_adventure'],
      createdAt: DateTime.utc(2026, 8, 22),
      content: '''
The first kite came back with a torn tail. Pip laid it across the worktable and read the dust caught in its seams. The upper pass was too rough for the caravan.

She built a second kite with a wider wing and sent it above the western ridge. Its line pulled steadily toward a sheltered gap. Pip drew a new trail on the slate and called the drivers together before sunrise.
''',
    ),
  ];
}
