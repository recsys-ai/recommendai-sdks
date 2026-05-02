<?php

declare(strict_types=1);
/**
 * Self-contained mock HTTP server for RecSys.AI PHP simulation.
 * Run via the PHP built-in server:
 *   php -S localhost:17896 examples/mock_server.php
 */

// ── In-memory state stored in tmp files to survive between requests ───────────

$state_file = sys_get_temp_dir() . '/recommendai_php_sim_state.json';

function load_state(string $file): array
{
    if (file_exists($file)) {
        $data = json_decode(file_get_contents($file), true);
        if (is_array($data)) {
            return $data;
        }
    }
    return ['users' => [], 'items' => [], 'interactions' => []];
}

function save_state(string $file, array $state): void
{
    file_put_contents($file, json_encode($state), LOCK_EX);
}

function djb2(string $str): int
{
    $h = 5381;
    for ($i = 0; $i < strlen($str); $i++) {
        $h = (($h << 5) + $h + ord($str[$i])) & 0x7FFFFFFF;
    }
    return $h;
}

function json_out(int $status, mixed $data): never
{
    http_response_code($status);
    header('Content-Type: application/json');
    echo json_encode($data);
    exit;
}

$method = $_SERVER['REQUEST_METHOD'];
$path   = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
$query  = [];
parse_str($_SERVER['QUERY_STRING'] ?? '', $query);
$body   = json_decode(file_get_contents('php://input'), true) ?? [];
$state  = load_state($state_file);

// ── Route: POST /api/users ────────────────────────────────────────────────────
if ($method === 'POST' && $path === '/api/users') {
    $uid    = $body['user_id'] ?? '';
    $record = [
        'user_id'    => $uid,
        'properties' => $body['properties'] ?? [],
        'created_at' => date('c'),
        'updated_at' => date('c'),
    ];
    $state['users'][$uid] = $record;
    save_state($state_file, $state);
    json_out(201, $record);
}

// ── Route: GET /api/users/{id} ────────────────────────────────────────────────
if ($method === 'GET' && preg_match('#^/api/users/([^/]+)$#', $path, $m)) {
    $uid = urldecode($m[1]);
    if (!isset($state['users'][$uid])) {
        json_out(404, ['detail' => "User not found: {$uid}"]);
    }
    json_out(200, $state['users'][$uid]);
}

// ── Route: PUT /api/users/{id} ────────────────────────────────────────────────
if ($method === 'PUT' && preg_match('#^/api/users/([^/]+)$#', $path, $m)) {
    $uid = urldecode($m[1]);
    if (!isset($state['users'][$uid])) {
        json_out(404, ['detail' => "User not found: {$uid}"]);
    }
    $state['users'][$uid]['properties'] = $body['properties'] ?? [];
    $state['users'][$uid]['updated_at'] = date('c');
    save_state($state_file, $state);
    json_out(200, $state['users'][$uid]);
}

// ── Route: DELETE /api/users/{id} ─────────────────────────────────────────────
if ($method === 'DELETE' && preg_match('#^/api/users/([^/]+)$#', $path, $m)) {
    $uid = urldecode($m[1]);
    if (!isset($state['users'][$uid])) {
        json_out(404, ['detail' => "User not found: {$uid}"]);
    }
    unset($state['users'][$uid]);
    save_state($state_file, $state);
    http_response_code(204);
    exit;
}

// ── Route: POST /api/items ────────────────────────────────────────────────────
if ($method === 'POST' && $path === '/api/items') {
    $iid    = $body['item_id'] ?? '';
    $record = [
        'item_id'    => $iid,
        'properties' => $body['properties'] ?? [],
        'created_at' => date('c'),
        'updated_at' => date('c'),
    ];
    $state['items'][$iid] = $record;
    save_state($state_file, $state);
    json_out(201, $record);
}

// ── Route: GET /api/items/{id} ────────────────────────────────────────────────
if ($method === 'GET' && preg_match('#^/api/items/([^/]+)$#', $path, $m)) {
    $iid = urldecode($m[1]);
    if (!isset($state['items'][$iid])) {
        json_out(404, ['detail' => "Item not found: {$iid}"]);
    }
    json_out(200, $state['items'][$iid]);
}

// ── Route: PUT /api/items/{id} ────────────────────────────────────────────────
if ($method === 'PUT' && preg_match('#^/api/items/([^/]+)$#', $path, $m)) {
    $iid = urldecode($m[1]);
    if (!isset($state['items'][$iid])) {
        json_out(404, ['detail' => "Item not found: {$iid}"]);
    }
    $state['items'][$iid]['properties'] = $body['properties'] ?? [];
    $state['items'][$iid]['updated_at'] = date('c');
    save_state($state_file, $state);
    json_out(200, $state['items'][$iid]);
}

// ── Route: DELETE /api/items/{id} ─────────────────────────────────────────────
if ($method === 'DELETE' && preg_match('#^/api/items/([^/]+)$#', $path, $m)) {
    $iid = urldecode($m[1]);
    if (!isset($state['items'][$iid])) {
        json_out(404, ['detail' => "Item not found: {$iid}"]);
    }
    unset($state['items'][$iid]);
    save_state($state_file, $state);
    http_response_code(204);
    exit;
}

// ── Route: POST /api/interactions ─────────────────────────────────────────────
if ($method === 'POST' && $path === '/api/interactions') {
    $ia                    = $body;
    $ia['interaction_id']  = 'ia_' . uniqid();
    $ia['timestamp']       = date('c');
    $state['interactions'][] = $ia;
    save_state($state_file, $state);
    json_out(201, $ia);
}

// ── Route: GET /api/recommendations ──────────────────────────────────────────
if ($method === 'GET' && $path === '/api/recommendations') {
    $uid   = $query['user_id'] ?? '';
    $limit = (int) ($query['limit'] ?? 10);
    if ($limit <= 0) { $limit = 10; }

    $seen = [];
    foreach ($state['interactions'] as $ia) {
        if ($ia['user_id'] === $uid) {
            $seen[$ia['item_id']] = true;
        }
    }

    $preferred_genre = '';
    if (isset($state['users'][$uid])) {
        $preferred_genre = $state['users'][$uid]['properties']['preferred_genre'] ?? '';
    }

    $candidates = [];
    foreach ($state['items'] as $item_id => $item) {
        if (isset($seen[$item_id])) { continue; }
        $props  = $item['properties'] ?? [];
        $rating = (float) ($props['rating'] ?? 0.0);
        $genre  = $props['genre'] ?? '';
        $score  = $rating / 10.0;
        if ($preferred_genre !== '' && $genre === $preferred_genre) { $score += 0.2; }
        $score += djb2($uid . $item_id) % 100 / 1000.0;
        $score  = min(round($score, 4), 1.0);
        $reason = ($preferred_genre !== '' && $genre === $preferred_genre)
                ? "Matches preferred genre: {$preferred_genre}"
                : 'Highly rated content';
        $candidates[] = [
            'item_id'  => $item_id,
            'score'    => $score,
            'reason'   => $reason,
            'metadata' => ['title' => $props['title'] ?? ''],
        ];
    }

    usort($candidates, fn($a, $b) => $b['score'] <=> $a['score']);
    $recs = array_slice($candidates, 0, $limit);
    json_out(200, ['user_id' => $uid, 'recommendations' => $recs]);
}

json_out(404, ['detail' => 'Not found']);
