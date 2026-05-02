import axios, { AxiosInstance, AxiosError } from 'axios';
import {
  ClientConfig,
  GetRecommendationsParams,
  GetSimilarItemsParams,
  GetPopularItemsParams,
  UpsertItemsParams,
  Recommendation,
  CreateInteractionParams,
  Interaction,
  CreateUserParams,
  User,
  CreateItemParams,
  Item
} from './types';
import {
  RecommendAIError,
  AuthenticationError,
  NotFoundError,
  ValidationError,
  RateLimitError,
  ServerError
} from './errors';

export class RecommendAIClient {
  private client: AxiosInstance;

  constructor(config: ClientConfig) {
    const baseUrl = config.baseUrl || 'http://localhost:8080';

    this.client = axios.create({
      baseURL: baseUrl,
      timeout: config.timeout || 30000,
      headers: {
        'Authorization': `Bearer ${config.apiKey}`,
        'User-Agent': 'recommendai-typescript/1.0.0',
        'Content-Type': 'application/json'
      }
    });

    this.client.interceptors.response.use(
      response => response,
      error => this.handleError(error)
    );

    this.recommendations = {
      get: this.getRecommendations.bind(this),
      similar: this.getSimilarItems.bind(this),
      popular: this.getPopularItems.bind(this),
    };

    this.interactions = {
      create: this.createInteraction.bind(this)
    };

    this.users = {
      create: this.createUser.bind(this),
      get: this.getUser.bind(this),
      update: this.updateUser.bind(this),
      delete: this.deleteUser.bind(this)
    };

    this.items = {
      create: this.createItem.bind(this),
      get: this.getItem.bind(this),
      update: this.updateItem.bind(this),
      delete: this.deleteItem.bind(this),
      upsert: this.upsertItems.bind(this),
    };
  }

  private handleError(error: AxiosError): never {
    if (error.response) {
      const status = error.response.status;
      const message = (error.response.data as any)?.detail || error.message;

      switch (status) {
        case 401: throw new AuthenticationError(message);
        case 404: throw new NotFoundError(message);
        case 400:
        case 422: throw new ValidationError(message);
        case 429: throw new RateLimitError(message);
        default:
          if (status >= 500) throw new ServerError(message);
          throw new RecommendAIError(message, status);
      }
    }
    throw new RecommendAIError(error.message);
  }

  public recommendations: {
    get(params: GetRecommendationsParams): Promise<Recommendation[]>;
    similar(params: GetSimilarItemsParams): Promise<Recommendation[]>;
    popular(params?: GetPopularItemsParams): Promise<Recommendation[]>;
  };

  public interactions: {
    create(params: CreateInteractionParams): Promise<Interaction>;
  };

  public users: {
    create(params: CreateUserParams): Promise<User>;
    get(userId: string): Promise<User>;
    update(userId: string, properties: Record<string, any>): Promise<User>;
    delete(userId: string): Promise<void>;
  };

  public items: {
    create(params: CreateItemParams): Promise<Item>;
    get(itemId: string): Promise<Item>;
    update(itemId: string, properties: Record<string, any>): Promise<Item>;
    delete(itemId: string): Promise<void>;
    upsert(params: UpsertItemsParams): Promise<Item[]>;
  };

  async ping(): Promise<boolean> {
    try {
      const response = await this.client.get('/health');
      return response.status === 200;
    } catch {
      return false;
    }
  }

  private async getRecommendations(params: GetRecommendationsParams): Promise<Recommendation[]> {
    const response = await this.client.get('/api/recommendations', { params });
    return response.data.recommendations || [];
  }

  private async getSimilarItems(params: GetSimilarItemsParams): Promise<Recommendation[]> {
    const { itemId, limit = 10 } = params;
    const response = await this.client.get(`/api/recommendations/similar/${itemId}`, { params: { limit } });
    return response.data.recommendations || [];
  }

  private async getPopularItems(params: GetPopularItemsParams = {}): Promise<Recommendation[]> {
    const response = await this.client.get('/api/recommendations/popular', { params });
    return response.data.recommendations || [];
  }

  private async createInteraction(params: CreateInteractionParams): Promise<Interaction> {
    const response = await this.client.post('/api/interactions', params);
    return response.data;
  }

  private async createUser(params: CreateUserParams): Promise<User> {
    const response = await this.client.post('/api/users', params);
    return response.data;
  }

  private async getUser(userId: string): Promise<User> {
    const response = await this.client.get(`/api/users/${userId}`);
    return response.data;
  }

  private async updateUser(userId: string, properties: Record<string, any>): Promise<User> {
    const response = await this.client.put(`/api/users/${userId}`, { properties });
    return response.data;
  }

  private async deleteUser(userId: string): Promise<void> {
    await this.client.delete(`/api/users/${userId}`);
  }

  private async createItem(params: CreateItemParams): Promise<Item> {
    const response = await this.client.post('/api/items', params);
    return response.data;
  }

  private async getItem(itemId: string): Promise<Item> {
    const response = await this.client.get(`/api/items/${itemId}`);
    return response.data;
  }

  private async updateItem(itemId: string, properties: Record<string, any>): Promise<Item> {
    const response = await this.client.put(`/api/items/${itemId}`, { properties });
    return response.data;
  }

  private async deleteItem(itemId: string): Promise<void> {
    await this.client.delete(`/api/items/${itemId}`);
  }

  private async upsertItems(params: UpsertItemsParams): Promise<Item[]> {
    const response = await this.client.post('/api/items/bulk', params);
    return response.data.items || [];
  }
}

