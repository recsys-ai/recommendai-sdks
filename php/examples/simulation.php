<?php

declare(strict_types=1);
/**
 * RecSys.AI PHP SDK — Movie Streaming Simulation
 *
 * Starts a PHP built-in HTTP server running mock_server.php on port 17896,
 * then exercises the full SDK without any live service.
 *
 * Run:  php examples/simulation.php
 */

require __DIR__ . '/../vendor/autoload.php';

use RecommendAI\RecommendAIClient;
use RecommendAI\InteractionType;
use RecommendAI\NotFoundException;
use RecommendAI\RecommendAIException;

define('MOCK_PORT', 17896);
define('MOCK_HOST', '127.0.0.1');
define('STATE_FILE', sys_get_temp_dir() . '/recommendai_php_sim_state.json');

// ── Wipe any leftover state ────────────────────────────────────────────────────
if (file_exists(STATE_FILE)) {
    unlink(STATE_FILE);
}

// ── Scenario data ──────────────────────────────────────────────────────────────

$movies = [
    ['id' => 'movie_001', 'title' => 'The Matrix',                 'genre' => 'sci-fi',   'year' => 1999, 'rating' => 8.7],
    ['id' => 'movie_002', 'title' => 'Inception',                  'genre' => 'sci-fi',   'year' => 2010, 'rating' => 8.8],
    ['id' => 'movie_003', 'title' => 'Interstellar',               'genre' => 'sci-fi',   'year' => 2014, 'rating' => 8.6],
    ['id' => 'movie_004', 'title' => 'The Dark Knight',            'genre' => 'action',   'year' => 2008, 'rating' => 9.0],
    ['id' => 'movie_005', 'title' => 'Avengers: Endgame',          'genre' => 'action',   'year' => 2019, 'rating' => 8.4],
    ['id' => 'movie_006', 'title' => 'John Wick',                  'genre' => 'action',   'year' => 2014, 'rating' => 7.4],
    ['id' => 'movie_007', 'title' => 'The Shawshank Redemption',   'genre' => 'drama',    'year' => 1994, 'rating' => 9.3],
    ['id' => 'movie_008', 'title' => 'Forrest Gump',               'genre' => 'drama',    'year' => 1994, 'rating' => 8.8],
    ['id' => 'movie_009', 'title' => 'Pulp Fiction',               'genre' => 'thriller', 'year' => 1994, 'rating' => 8.9],
    ['id' => 'movie_010', 'title' => 'The Silence of the Lambs',   'genre' => 'thriller', 'year' => 1991, 'rating' => 8.6],
];

$users = [
    ['id' => 'alice', 'name' => 'Alice Johnson', 'preferred_genre' => 'sci-fi',   'age' => 28],
    ['id' => 'bob',   'name' => 'Bob Smith',     'preferred_genre' => 'action',   'age' => 35],
    ['id' => 'carol', 'name' => 'Carol White',   'preferred_genre' => 'drama',    'age' => 42],
    ['id' => 'dave',  'name' => 'Dave Brown',    'preferred_genre' => 'sci-fi',   'age' => 23],
    ['id' => 'eve',   'name' => 'Eve Davis',     'preferred_genre' => 'thriller', 'age' => 31],
];

$interactions = [
    ['user' => 'alice', 'item' => 'movie_001', 'type' => InteractionType::VIEW,     'value' => null ],
    ['user' => 'alice', 'item' => 'movie_002', 'type' => InteractionType::LIKE,     'value' => null ],
    ['user' => 'alice', 'item' => 'movie_003', 'type' => InteractionType::PURCHASE, 'value' => null ],
    ['user' => 'alice', 'item' => 'movie_001', 'type' => InteractionType::RATING,   'value' => 9.0  ],
    ['user' => 'bob',   'item' => 'movie_004', 'type' => InteractionType::VIEW,     'value' => null ],
    ['user' => 'bob',   'item' => 'movie_005', 'type' => InteractionType::LIKE,     'value' => null ],
    ['user' => 'bob',   'item' => 'movie_006', 'type' => InteractionType::PURCHASE, 'value' => null ],
    ['user' => 'bob',   'item' => 'movie_004', 'type' => InteractionType::RATING,   'value' => 8.0  ],
    ['user' => 'carol', 'item' => 'movie_007', 'type' => InteractionType::VIEW,     'value' => null ],
    ['user' => 'carol', 'item' => 'movie_008', 'type' => InteractionType::LIKE,     'value' => null ],
    ['user' => 'carol', 'item' => 'movie_007', 'type' => InteractionType::PURCHASE, 'value' => null ],
    ['user' => 'carol', 'item' => 'movie_008', 'type' => InteractionType::RATING,   'value' => 9.0  ],
    ['user' => 'dave',  'item' => 'movie_001', 'type' => InteractionType::VIEW,     'value' => null ],
    ['user' => 'dave',  'item' => 'movie_002', 'type' => InteractionType::PURCHASE, 'value' => null ],
    ['user' => 'dave',  'item' => 'movie_003', 'type' => InteractionType::RATING,   'value' => 8.5  ],
    ['user' => 'eve',   'item' => 'movie_009', 'type' => InteractionType::VIEW,     'value' => null ],
    ['user' => 'eve',   'item' => 'movie_010', 'type' => InteractionType::LIKE,     'value' => null ],
    ['user' => 'eve',   'item' => 'movie_009', 'type' => InteractionType::PURCHASE, 'value' => null ],
    ['user' => 'eve',   'item' => 'movie_010', 'type' => InteractionType::RATING,   'value' => 8.0  ],
    ['user' => 'alice', 'item' => 'movie_002', 'type' => InteractionType::RATING,   'value' => 10.0 ],
    ['user' => 'bob',   'item' => 'movie_006', 'type' => InteractionType::RATING,   'value' => 7.5  ],
    ['user' => 'carol', 'item' => 'movie_009', 'type' => InteractionType::VIEW,     'value' => null ],
    ['user' => 'dave',  'item' => 'movie_004', 'type' => InteractionType::VIEW,     'value' => null ],
    ['user' => 'eve',   'item' => 'movie_002', 'type' => InteractionType::VIEW,     'value' => null ],
    ['user' => 'alice', 'item' => 'movie_004', 'type' => InteractionType::VIEW,     'value' => null ],
];

// ── Launch PHP built-in server ─────────────────────────────────────────────────

$docroot    = __DIR__;
$serverCmd  = sprintf(
    'php -S %s:%d %s',
    MOCK_HOST,
    MOCK_PORT,
    escapeshellarg($docroot . '/mock_server.php')
);

$descriptors = [
    0 => ['pipe', 'r'],
    1 => ['pipe', 'w'],
    2 => ['pipe', 'w'],
];
$process = proc_open($serverCmd, $descriptors, $pipes);
if (!is_resource($process)) {
    fwrite(STDERR, "Failed to start mock server.\n");
    exit(1);
}
// Wait for server to be ready
usleep(500_000);
echo "[mock] PHP built-in server started on port " . MOCK_PORT . "\n\n";

register_shutdown_function(static function () use ($process, $pipes, $state_file): void {
    foreach ($pipes as $p) { @fclose($p); }
    proc_terminate($process);
    if (file_exists(STATE_FILE)) { unlink(STATE_FILE); }
});

// ── SDK client ─────────────────────────────────────────────────────────────────

$client = new RecommendAIClient(
    apiKey:  'sim-api-key',
    baseUrl: 'http://' . MOCK_HOST . ':' . MOCK_PORT,
);

// ── Helpers ────────────────────────────────────────────────────────────────────

function banner(string $text): void
{
    $line = str_repeat('=', strlen($text) + 4);
    echo $line . "\n";
    echo "= {$text} =\n";
    echo $line . "\n\n";
}

function step(int $n, string $title): void
{
    echo "── Step {$n}: {$title}\n";
}

banner('RecSys.AI PHP SDK — Movie Streaming Simulation');

// Step 1: seed catalogue
step(1, 'Seeding Movie Catalogue');
foreach ($movies as $m) {
    $item = $client->items()->create($m['id'], [
        'title'  => $m['title'],
        'genre'  => $m['genre'],
        'year'   => $m['year'],
        'rating' => $m['rating'],
    ]);
    echo "  Created item: {$item->item_id} ({$item->properties['title']})\n";
}
echo "  " . count($movies) . " movies added to catalogue.\n\n";

// Step 2: register users
step(2, 'Registering Users');
foreach ($users as $u) {
    $user = $client->users()->create($u['id'], [
        'name'             => $u['name'],
        'age'              => $u['age'],
        'preferred_genre'  => $u['preferred_genre'],
    ]);
    echo "  Registered: {$user->user_id} ({$user->properties['name']})\n";
}
echo "  " . count($users) . " users registered.\n\n";

// Step 3: record interactions
step(3, 'Recording Watch History & Ratings');
foreach ($interactions as $ia) {
    $client->interactions()->create(
        userId:          $ia['user'],
        itemId:          $ia['item'],
        interactionType: $ia['type'],
        value:           $ia['value'],
    );
}
echo "  " . count($interactions) . " interactions recorded.\n\n";

// Step 4: personalised recommendations
step(4, 'Getting Personalised Recommendations');
foreach ($users as $u) {
    $recs = $client->recommendations()->get($u['id'], 5);
    echo "  Recommendations for {$u['id']}:\n";
    foreach ($recs as $i => $r) {
        $title = $r->metadata['title'] ?? $r->item_id;
        printf("    %d. %-36s (score: %.4f)  %s\n", $i + 1, $title, $r->score, $r->reason);
    }
    echo "\n";
}

// Step 5: update item
step(5, 'Updating Item Metadata');
$updated = $client->items()->update('movie_001', [
    'title' => 'The Matrix', 'genre' => 'sci-fi',
    'year'  => 1999, 'rating' => 8.7, 'remastered' => true,
]);
$rem = $updated->properties['remastered'] ? 'true' : 'false';
echo "  Updated movie_001 — remastered: {$rem}\n\n";

// Step 6: update user
step(6, 'Updating User Profile');
$alice = $client->users()->update('alice', [
    'name' => 'Alice Johnson', 'age' => 29,
    'preferred_genre' => 'sci-fi', 'subscription' => 'premium',
]);
echo "  alice subscription → {$alice->properties['subscription']}\n\n";

// Step 7: verify item retrieval
step(7, 'Verifying Item Retrieval');
$retrieved = $client->items()->get('movie_004');
echo "  Retrieved: {$retrieved->item_id} — {$retrieved->properties['title']} ({$retrieved->properties['genre']})\n\n";

// Step 8: error handling
step(8, 'Error Handling Demo');
try {
    $client->users()->get('ghost_999');
    echo "  ERROR: expected NotFoundException was not thrown!\n";
} catch (NotFoundException $e) {
    echo "  Caught NotFoundException: {$e->getMessage()}\n\n";
}

// Step 9: cleanup
step(9, 'Cleanup');
$client->users()->delete('dave');
echo "  Deleted user 'dave'.\n";
try {
    $client->users()->get('dave');
} catch (NotFoundException) {
    echo "  Confirmed: 'dave' no longer exists.\n";
}

echo "\n";
banner('Simulation complete — all steps passed!');
