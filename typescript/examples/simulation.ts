/**
 * RecSys.AI TypeScript SDK — Integration Simulation
 * ==================================================
 * A self-contained simulation demonstrating the full RecSys.AI recommendation
 * workflow against a local mock HTTP server. No live service required.
 *
 * Scenario: A movie-streaming service that personalises content for its users.
 *
 * Usage:
 *   cd recommendai-sdks/typescript
 *   npm install
 *   npx ts-node examples/simulation.ts
 *
 *   # Or compile first:
 *   npx tsc -p examples/tsconfig.json && node examples/dist/simulation.js
 */

import * as http from 'http';
import { URL } from 'url';
import { RecommendAIClient } from '../src/client';
import { InteractionType } from '../src/types';
import type {
  Recommendation,
  User,
  Item,
  Interaction,
} from '../src/types';

// ── Configuration ─────────────────────────────────────────────────────────────
const MOCK_PORT = 17891; // different port from the Python simulation
const MOCK_BASE_URL = `http://localhost:${MOCK_PORT}`;
const DEMO_API_KEY = 'sim_demo_ts_key_abcdef1234567890';

// ── ANSI colour helpers ────────────────────────────────────────────────────────
const isTTY = process.stdout.isTTY ?? false;
const GREEN  = isTTY ? '\x1b[92m' : '';
const CYAN   = isTTY ? '\x1b[96m' : '';
const YELLOW = isTTY ? '\x1b[93m' : '';
const BOLD   = isTTY ? '\x1b[1m'  : '';
const DIM    = isTTY ? '\x1b[2m'  : '';
const RESET  = isTTY ? '\x1b[0m'  : '';

function header(text: string): void {
  console.log(`\n${BOLD}${CYAN}${'─'.repeat(62)}${RESET}`);
  console.log(`${BOLD}${CYAN}  ${text}${RESET}`);
  console.log(`${BOLD}${CYAN}${'─'.repeat(62)}${RESET}`);
}
function step(text: string): void { console.log(`  ${GREEN}▶${RESET} ${text}`); }
function success(text: string): void { console.log(`  ${GREEN}✓${RESET} ${text}`); }

// ── In-memory store ────────────────────────────────────────────────────────────
interface StoredUser   { userId: string; properties: Record<string, any>; createdAt: string; updatedAt: string; }
interface StoredItem   { itemId: string; properties: Record<string, any>; createdAt: string; updatedAt: string; }
interface StoredInteraction {
  interactionId: string; userId: string; itemId: string;
  interactionType: string; value?: number; timestamp: string;
  metadata: Record<string, any>;
}

const store = {
  users:        new Map<string, StoredUser>(),
  items:        new Map<string, StoredItem>(),
  interactions: [] as StoredInteraction[],
};

function now(): string { return new Date().toISOString(); }

function computeRecommendations(userId: string, limit: number): Recommendation[] {
  const userIxs = store.interactions.filter(i => i.userId === userId);
  const seenIds  = new Set(userIxs.map(i => i.itemId));

  const preferredGenres = new Set<string>();
  for (const ix of userIxs) {
    if (['purchase', 'like', 'rating'].includes(ix.interactionType)) {
      const genre = store.items.get(ix.itemId)?.properties?.genre as string | undefined;
      if (genre) preferredGenres.add(genre);
    }
  }

  const candidates: Recommendation[] = [];
  for (const [itemId, item] of store.items.entries()) {
    const genre       = (item.properties?.genre as string) || '';
    const isSeen      = seenIds.has(itemId);
    const genreBonus  = preferredGenres.has(genre) ? 0.15 : 0.0;
    // Deterministic pseudo-random base in [0, 0.399]
    const base        = (Math.abs(hashCode(userId + itemId)) % 400) / 1000;
    const score       = Math.min(+(((isSeen ? 0.35 : 0.60) + base + genreBonus).toFixed(3)), 0.999);
    const reason      = isSeen ? 'watch_again'
                      : preferredGenres.has(genre) ? 'because_you_liked_genre'
                      : 'collaborative_filtering';

    candidates.push({
      itemId,
      score,
      reason,
      metadata: { genre, title: item.properties?.title ?? '' },
    });
  }

  return candidates
    .sort((a, b) => b.score - a.score)
    .slice(0, limit);
}

/** Simple deterministic hash for strings (djb2). */
function hashCode(s: string): number {
  let h = 5381;
  for (let i = 0; i < s.length; i++) {
    h = (h * 33) ^ s.charCodeAt(i);
  }
  return h;
}

// ── Mock HTTP server ───────────────────────────────────────────────────────────
function readBody(req: http.IncomingMessage): Promise<any> {
  return new Promise((resolve, reject) => {
    let data = '';
    req.on('data', chunk => { data += chunk; });
    req.on('end', () => resolve(data ? JSON.parse(data) : {}));
    req.on('error', reject);
  });
}

function sendJson(res: http.ServerResponse, status: number, data: unknown): void {
  const body = JSON.stringify(data);
  res.writeHead(status, { 'Content-Type': 'application/json', 'Content-Length': Buffer.byteLength(body) });
  res.end(body);
}

function createMockServer(): http.Server {
  return http.createServer(async (req, res) => {
    const url    = new URL(req.url ?? '/', MOCK_BASE_URL);
    const path   = url.pathname;
    const method = req.method ?? 'GET';

    try {
      // GET /api/recommendations
      if (method === 'GET' && path === '/api/recommendations') {
        const userId = url.searchParams.get('userId') ?? 'unknown';
        const limit  = parseInt(url.searchParams.get('limit') ?? '10', 10);
        sendJson(res, 200, {
          userId,
          recommendations: computeRecommendations(userId, limit),
          requestId: crypto.randomUUID(),
        });
        return;
      }

      // GET /api/users/:id
      if (method === 'GET' && path.startsWith('/api/users/')) {
        const uid = path.slice('/api/users/'.length);
        const obj = store.users.get(uid);
        obj ? sendJson(res, 200, obj) : sendJson(res, 404, { detail: 'User not found' });
        return;
      }

      // GET /api/items/:id
      if (method === 'GET' && path.startsWith('/api/items/')) {
        const iid = path.slice('/api/items/'.length);
        const obj = store.items.get(iid);
        obj ? sendJson(res, 200, obj) : sendJson(res, 404, { detail: 'Item not found' });
        return;
      }

      // POST /api/users
      if (method === 'POST' && path === '/api/users') {
        const body = await readBody(req);
        const uid  = body.userId ?? crypto.randomUUID();
        const obj: StoredUser = { userId: uid, properties: body.properties ?? {}, createdAt: now(), updatedAt: now() };
        store.users.set(uid, obj);
        sendJson(res, 201, obj);
        return;
      }

      // POST /api/items
      if (method === 'POST' && path === '/api/items') {
        const body = await readBody(req);
        const iid  = body.itemId ?? crypto.randomUUID();
        const obj: StoredItem = { itemId: iid, properties: body.properties ?? {}, createdAt: now(), updatedAt: now() };
        store.items.set(iid, obj);
        sendJson(res, 201, obj);
        return;
      }

      // POST /api/interactions
      if (method === 'POST' && path === '/api/interactions') {
        const body = await readBody(req);
        const obj: StoredInteraction = {
          interactionId: crypto.randomUUID(),
          userId:           body.userId,
          itemId:           body.itemId,
          interactionType:  body.interactionType,
          value:            body.value,
          timestamp:        now(),
          metadata:         body.metadata ?? {},
        };
        store.interactions.push(obj);
        sendJson(res, 201, obj);
        return;
      }

      // PUT /api/users/:id
      if (method === 'PUT' && path.startsWith('/api/users/')) {
        const uid  = path.slice('/api/users/'.length);
        const body = await readBody(req);
        const obj  = store.users.get(uid);
        if (obj) {
          obj.properties = body.properties ?? {};
          obj.updatedAt  = now();
          sendJson(res, 200, obj);
        } else {
          sendJson(res, 404, { detail: 'User not found' });
        }
        return;
      }

      // PUT /api/items/:id
      if (method === 'PUT' && path.startsWith('/api/items/')) {
        const iid  = path.slice('/api/items/'.length);
        const body = await readBody(req);
        const obj  = store.items.get(iid);
        if (obj) {
          obj.properties = body.properties ?? {};
          obj.updatedAt  = now();
          sendJson(res, 200, obj);
        } else {
          sendJson(res, 404, { detail: 'Item not found' });
        }
        return;
      }

      // DELETE /api/users/:id
      if (method === 'DELETE' && path.startsWith('/api/users/')) {
        store.users.delete(path.slice('/api/users/'.length));
        res.writeHead(204);
        res.end();
        return;
      }

      // DELETE /api/items/:id
      if (method === 'DELETE' && path.startsWith('/api/items/')) {
        store.items.delete(path.slice('/api/items/'.length));
        res.writeHead(204);
        res.end();
        return;
      }

      sendJson(res, 404, { detail: 'Not found' });
    } catch (err) {
      sendJson(res, 500, { detail: 'Internal server error' });
    }
  });
}

function startMockServer(): Promise<http.Server> {
  return new Promise((resolve, reject) => {
    const server = createMockServer();
    server.listen(MOCK_PORT, 'localhost', () => resolve(server));
    server.on('error', reject);
  });
}

// ── Sample data ────────────────────────────────────────────────────────────────
const USERS = [
  { id: 'alice',  name: 'Alice Chen',    tier: 'premium',  ageGroup: '25-34' },
  { id: 'bob',    name: 'Bob Martinez',  tier: 'standard', ageGroup: '35-44' },
  { id: 'carol',  name: 'Carol Johnson', tier: 'premium',  ageGroup: '18-24' },
  { id: 'dave',   name: 'Dave Kim',      tier: 'standard', ageGroup: '45-54' },
  { id: 'eve',    name: 'Eve Thompson',  tier: 'premium',  ageGroup: '25-34' },
] as const;

const MOVIES = [
  { id: 'movie-001', title: 'Galactic Odyssey',  genre: 'sci-fi',  year: 2023, rating: 8.5 },
  { id: 'movie-002', title: 'The Last Garden',   genre: 'drama',   year: 2022, rating: 7.9 },
  { id: 'movie-003', title: 'Laugh Factory',     genre: 'comedy',  year: 2023, rating: 7.2 },
  { id: 'movie-004', title: 'Quantum Protocol',  genre: 'sci-fi',  year: 2021, rating: 8.1 },
  { id: 'movie-005', title: 'City Lights',       genre: 'drama',   year: 2023, rating: 8.3 },
  { id: 'movie-006', title: 'Thunder Force',     genre: 'action',  year: 2022, rating: 7.5 },
  { id: 'movie-007', title: 'Weekend Escape',    genre: 'comedy',  year: 2021, rating: 6.8 },
  { id: 'movie-008', title: 'Neural Divide',     genre: 'sci-fi',  year: 2023, rating: 9.0 },
  { id: 'movie-009', title: 'Beneath the Storm', genre: 'action',  year: 2022, rating: 7.7 },
  { id: 'movie-010', title: 'Whispered Truths',  genre: 'drama',   year: 2021, rating: 8.6 },
] as const;

interface InteractionSeed {
  userId: string;
  itemId: string;
  type: InteractionType;
  value?: number;
}

const INTERACTIONS: InteractionSeed[] = [
  // Alice loves sci-fi
  { userId: 'alice', itemId: 'movie-001', type: InteractionType.VIEW },
  { userId: 'alice', itemId: 'movie-001', type: InteractionType.RATING,   value: 9.0 },
  { userId: 'alice', itemId: 'movie-004', type: InteractionType.VIEW },
  { userId: 'alice', itemId: 'movie-004', type: InteractionType.LIKE },
  { userId: 'alice', itemId: 'movie-008', type: InteractionType.VIEW },
  { userId: 'alice', itemId: 'movie-008', type: InteractionType.RATING,   value: 9.5 },
  // Bob prefers drama & action
  { userId: 'bob',   itemId: 'movie-002', type: InteractionType.VIEW },
  { userId: 'bob',   itemId: 'movie-002', type: InteractionType.PURCHASE },
  { userId: 'bob',   itemId: 'movie-005', type: InteractionType.VIEW },
  { userId: 'bob',   itemId: 'movie-005', type: InteractionType.RATING,   value: 8.0 },
  { userId: 'bob',   itemId: 'movie-006', type: InteractionType.VIEW },
  { userId: 'bob',   itemId: 'movie-009', type: InteractionType.LIKE },
  // Carol enjoys comedy & action
  { userId: 'carol', itemId: 'movie-003', type: InteractionType.VIEW },
  { userId: 'carol', itemId: 'movie-003', type: InteractionType.RATING,   value: 7.5 },
  { userId: 'carol', itemId: 'movie-006', type: InteractionType.VIEW },
  { userId: 'carol', itemId: 'movie-007', type: InteractionType.VIEW },
  { userId: 'carol', itemId: 'movie-007', type: InteractionType.PURCHASE },
  // Dave watches a mix
  { userId: 'dave',  itemId: 'movie-001', type: InteractionType.VIEW },
  { userId: 'dave',  itemId: 'movie-002', type: InteractionType.VIEW },
  { userId: 'dave',  itemId: 'movie-010', type: InteractionType.RATING,   value: 9.0 },
  // Eve is a premium power-user
  { userId: 'eve',   itemId: 'movie-001', type: InteractionType.VIEW },
  { userId: 'eve',   itemId: 'movie-003', type: InteractionType.VIEW },
  { userId: 'eve',   itemId: 'movie-005', type: InteractionType.LIKE },
  { userId: 'eve',   itemId: 'movie-008', type: InteractionType.RATING,   value: 8.5 },
  { userId: 'eve',   itemId: 'movie-010', type: InteractionType.PURCHASE },
];

// ── Main simulation ────────────────────────────────────────────────────────────
async function runSimulation(client: RecommendAIClient): Promise<void> {

  // ── 1. Seed catalog ─────────────────────────────────────────────────────────
  header('Step 1 · Seeding Movie Catalog');
  for (const movie of MOVIES) {
    const item: Item = await client.items.create({
      itemId: movie.id,
      properties: { title: movie.title, genre: movie.genre, year: movie.year, rating: movie.rating },
    });
    step(`Created item  ${String(item.itemId).padEnd(14)}  [${movie.genre.padEnd(7)}]  ${movie.title}`);
  }
  success(`Catalog seeded with ${MOVIES.length} movies`);

  // ── 2. Register users ────────────────────────────────────────────────────────
  header('Step 2 · Registering Users');
  for (const u of USERS) {
    const user: User = await client.users.create({
      userId: u.id,
      properties: { name: u.name, tier: u.tier, ageGroup: u.ageGroup },
    });
    step(`Registered user  ${String(user.userId).padEnd(8)}  (${u.name}, tier=${u.tier})`);
  }
  success(`Registered ${USERS.length} users`);

  // ── 3. Record interactions ───────────────────────────────────────────────────
  header('Step 3 · Recording User Interactions');
  for (const ix of INTERACTIONS) {
    const interaction: Interaction = await client.interactions.create({
      userId:          ix.userId,
      itemId:          ix.itemId,
      interactionType: ix.type,
      value:           ix.value,
    });
    const movieTitle = MOVIES.find(m => m.id === ix.itemId)?.title ?? ix.itemId;
    const valStr     = ix.value !== undefined ? `  (value=${ix.value})` : '';
    step(`${ix.userId.padEnd(6)}  →  ${ix.type.padEnd(9)}  ${movieTitle}${valStr}`);
  }
  success(`Recorded ${INTERACTIONS.length} interactions`);

  // ── 4. Personalised recommendations ──────────────────────────────────────────
  header('Step 4 · Personalised Recommendations');
  for (const u of USERS) {
    const recs: Recommendation[] = await client.recommendations.get({ userId: u.id, limit: 5 });
    console.log(`\n  ${BOLD}${YELLOW}${u.name}${RESET}'s top ${recs.length} picks:`);
    for (const [i, rec] of recs.entries()) {
      const item  = await client.items.get(rec.itemId);
      const title = (item.properties?.title as string) ?? rec.itemId;
      const genre = (item.properties?.genre as string) ?? '?';
      console.log(
        `    ${i + 1}. ${title.padEnd(32)}  score=${rec.score.toFixed(3)}`
        + `  [${genre.padEnd(7)}]  (${rec.reason ?? 'n/a'})`,
      );
    }
  }

  // ── 5. Update item metadata ───────────────────────────────────────────────────
  header('Step 5 · Updating Item Metadata');
  const updated: Item = await client.items.update('movie-001', {
    title: 'Galactic Odyssey: Remastered', genre: 'sci-fi', year: 2024, rating: 8.7,
  });
  step(`Updated title → ${String(updated.properties?.title)!}`);

  // ── 6. Update user profile ───────────────────────────────────────────────────
  header('Step 6 · Updating User Profile');
  const refreshed: User = await client.users.update('alice', { tier: 'elite', ageGroup: '25-34' });
  step(`alice's tier is now: ${refreshed.properties?.tier as string}`);

  // ── 7. Error handling demo ────────────────────────────────────────────────────
  header('Step 7 · Error Handling Demo');
  const { NotFoundError } = await import('../src/errors');
  try {
    await client.users.get('nonexistent-user-xyz');
  } catch (err) {
    if (err instanceof NotFoundError) {
      success(`NotFoundError caught correctly: status=${err.statusCode}, msg="${err.message}"`);
    }
  }

  // ── 8. Parallel fetches ───────────────────────────────────────────────────────
  header('Step 8 · Parallel Recommendation Fetches');
  const [aliceRecs, eveRecs] = await Promise.all([
    client.recommendations.get({ userId: 'alice', limit: 3 }),
    client.recommendations.get({ userId: 'eve',   limit: 3 }),
  ]);
  console.log(`\n  ${BOLD}${YELLOW}Alice${RESET} (parallel fetch):`);
  aliceRecs.forEach((r, i) =>
    console.log(`    ${i + 1}. itemId=${String(r.itemId).padEnd(14)}  score=${r.score.toFixed(3)}  (${r.reason})`),
  );
  console.log(`\n  ${BOLD}${YELLOW}Eve${RESET} (parallel fetch):`);
  eveRecs.forEach((r, i) =>
    console.log(`    ${i + 1}. itemId=${String(r.itemId).padEnd(14)}  score=${r.score.toFixed(3)}  (${r.reason})`),
  );

  // ── 9. Clean-up ───────────────────────────────────────────────────────────────
  header('Step 9 · Clean-up');
  await client.users.delete('dave');
  step(`Deleted test user 'dave'`);
  success('Simulation complete');
}

// ── Entry point ────────────────────────────────────────────────────────────────
(async () => {
  console.log(`\n${BOLD}${'='.repeat(62)}${RESET}`);
  console.log(`${BOLD}  RecSys.AI TypeScript SDK — Integration Simulation${RESET}`);
  console.log(`${BOLD}${'='.repeat(62)}${RESET}`);
  console.log(`\n${DIM}Starting in-process mock API server on port ${MOCK_PORT} ...${RESET}`);

  const server = await startMockServer();
  console.log(`${GREEN}✓${RESET} Mock server running at ${BOLD}${MOCK_BASE_URL}${RESET}\n`);

  const client = new RecommendAIClient({ apiKey: DEMO_API_KEY, baseUrl: MOCK_BASE_URL });

  try {
    await runSimulation(client);
    console.log(`\n${BOLD}${GREEN}${'='.repeat(62)}${RESET}`);
    console.log(`${BOLD}${GREEN}  All simulations completed successfully!${RESET}`);
    console.log(`${BOLD}${GREEN}${'='.repeat(62)}${RESET}\n`);
  } finally {
    server.close();
  }
})();
