import { Injectable } from '@nestjs/common';
import type { BusinessSettings } from '../generated/prisma/client.js';
import { PrismaService } from '../prisma/prisma.service.js';

const CACHE_MS = 30_000;

/** Business rules live in a single database row so admins can change them without a deploy. */
@Injectable()
export class SettingsService {
  private cached: { value: BusinessSettings; at: number } | null = null;

  constructor(private readonly prisma: PrismaService) {}

  async get(): Promise<BusinessSettings> {
    if (this.cached && Date.now() - this.cached.at < CACHE_MS) return this.cached.value;
    const value = await this.prisma.businessSettings.upsert({
      where: { id: 1 },
      create: { id: 1 },
      update: {},
    });
    this.cached = { value, at: Date.now() };
    return value;
  }

  async update(data: Partial<Omit<BusinessSettings, 'id' | 'updatedAt'>>): Promise<BusinessSettings> {
    const value = await this.prisma.businessSettings.update({ where: { id: 1 }, data });
    this.cached = { value, at: Date.now() };
    return value;
  }
}
