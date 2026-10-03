import { Injectable } from '@nestjs/common';
import { AppError } from '../common/errors.js';
import type { CatalogCategory, CatalogItem } from '../generated/prisma/client.js';
import { PrismaService } from '../prisma/prisma.service.js';
import type { CreateCategoryDto, CreateItemDto, UpdateCategoryDto, UpdateItemDto } from './catalog.dto.js';

type CategoryWithItems = CatalogCategory & { items: CatalogItem[] };

@Injectable()
export class CatalogService {
  constructor(private readonly prisma: PrismaService) {}

  /** Categories with their items. `activeOnly` hides inactive categories and items (customer view). */
  list(activeOnly: boolean): Promise<CategoryWithItems[]> {
    return this.prisma.catalogCategory.findMany({
      where: activeOnly ? { isActive: true } : {},
      orderBy: [{ sortOrder: 'asc' }, { name: 'asc' }],
      include: {
        items: {
          where: activeOnly ? { isActive: true } : {},
          orderBy: [{ sortOrder: 'asc' }, { name: 'asc' }],
        },
      },
    });
  }

  createCategory(dto: CreateCategoryDto): Promise<CatalogCategory> {
    return this.prisma.catalogCategory.create({ data: dto });
  }

  updateCategory(id: string, dto: UpdateCategoryDto): Promise<CatalogCategory> {
    return this.prisma.catalogCategory.update({ where: { id }, data: dto });
  }

  /** Only empty categories can be deleted; otherwise deactivate them. */
  async deleteCategory(id: string): Promise<void> {
    const items = await this.prisma.catalogItem.count({ where: { categoryId: id } });
    if (items > 0) {
      throw AppError.conflict('CATEGORY_NOT_EMPTY', 'Move or delete its items first, or deactivate it');
    }
    await this.prisma.catalogCategory.delete({ where: { id } });
  }

  async createItem(dto: CreateItemDto): Promise<CatalogItem> {
    this.checkOfferPrice(dto.pricePaise, dto.offerPricePaise);
    return this.prisma.catalogItem.create({ data: dto });
  }

  async updateItem(id: string, dto: UpdateItemDto): Promise<CatalogItem> {
    const current = await this.prisma.catalogItem.findUnique({ where: { id } });
    if (!current) throw AppError.notFound('Item');
    const offer = dto.offerPricePaise === undefined ? current.offerPricePaise : dto.offerPricePaise;
    this.checkOfferPrice(dto.pricePaise ?? current.pricePaise, offer);
    return this.prisma.catalogItem.update({ where: { id }, data: dto });
  }

  /** Items used in past orders are deactivated rather than deleted. */
  async deleteItem(id: string): Promise<{ deleted: boolean }> {
    const used = await this.prisma.orderItem.count({ where: { catalogItemId: id } });
    if (used > 0) {
      await this.prisma.catalogItem.update({ where: { id }, data: { isActive: false } });
      return { deleted: false };
    }
    await this.prisma.catalogItem.delete({ where: { id } });
    return { deleted: true };
  }

  private checkOfferPrice(price: number, offer: number | null | undefined): void {
    if (offer != null && offer >= price) {
      throw AppError.badRequest('INVALID_OFFER_PRICE', 'Offer price must be lower than the price');
    }
  }
}
