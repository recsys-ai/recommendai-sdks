import { RecommendAIClient } from './client';
import { AuthenticationError, NotFoundError } from './errors';

describe('RecommendAIClient', () => {
  let client: RecommendAIClient;

  beforeEach(() => {
    client = new RecommendAIClient({
      apiKey: 'test_key',
      baseUrl: 'https://api.test.com'
    });
  });

  describe('initialization', () => {
    it('should create client with correct config', () => {
      expect(client).toBeInstanceOf(RecommendAIClient);
      expect(client.recommendations).toBeDefined();
      expect(client.users).toBeDefined();
      expect(client.items).toBeDefined();
      expect(client.interactions).toBeDefined();
    });
  });

  describe('recommendations', () => {
    it('should have get method', () => {
      expect(typeof client.recommendations.get).toBe('function');
    });
  });

  describe('users', () => {
    it('should have CRUD methods', () => {
      expect(typeof client.users.create).toBe('function');
      expect(typeof client.users.get).toBe('function');
      expect(typeof client.users.update).toBe('function');
      expect(typeof client.users.delete).toBe('function');
    });
  });

  describe('items', () => {
    it('should have CRUD methods', () => {
      expect(typeof client.items.create).toBe('function');
      expect(typeof client.items.get).toBe('function');
      expect(typeof client.items.update).toBe('function');
      expect(typeof client.items.delete).toBe('function');
    });
  });

  describe('interactions', () => {
    it('should have create method', () => {
      expect(typeof client.interactions.create).toBe('function');
    });
  });
});
