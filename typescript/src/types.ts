export interface ClientConfig {
  apiKey: string;
  baseUrl?: string;
  timeout?: number;
  maxRetries?: number;
}

export enum InteractionType {
  VIEW = 'view',
  CLICK = 'click',
  PURCHASE = 'purchase',
  LIKE = 'like',
  DISLIKE = 'dislike',
  RATING = 'rating',
  CART_ADD = 'cart_add',
  CART_REMOVE = 'cart_remove'
}

export interface Recommendation {
  itemId: string;
  score: number;
  reason?: string;
  metadata?: Record<string, any>;
}

export interface User {
  userId: string;
  properties?: Record<string, any>;
  createdAt: Date;
  updatedAt: Date;
}

export interface Item {
  itemId: string;
  properties?: Record<string, any>;
  createdAt: Date;
  updatedAt: Date;
}

export interface Interaction {
  interactionId?: string;
  userId: string;
  itemId: string;
  interactionType: InteractionType;
  value?: number;
  timestamp: Date;
  metadata?: Record<string, any>;
}

export interface GetRecommendationsParams {
  userId: string;
  limit?: number;
  context?: Record<string, any>;
  filters?: Record<string, any>;
}

export interface CreateInteractionParams {
  userId: string;
  itemId: string;
  interactionType: InteractionType | string;
  value?: number;
  metadata?: Record<string, any>;
}

export interface CreateUserParams {
  userId: string;
  properties?: Record<string, any>;
}

export interface CreateItemParams {
  itemId: string;
  properties?: Record<string, any>;
}

export interface GetSimilarItemsParams {
  itemId: string;
  limit?: number;
}

export interface GetPopularItemsParams {
  limit?: number;
  category?: string;
}

export interface UpsertItemsParams {
  items: Array<{ itemId: string; properties?: Record<string, any> }>;
}
