import { Body, Controller, Delete, Get, HttpCode, Param, ParseUUIDPipe, Patch, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { AuditService } from '../audit/audit.service.js';
import { CurrentUser, Public, Roles } from '../auth/decorators.js';
import { DeleteResultDto } from '../common/pagination.js';
import type { User } from '../generated/prisma/client.js';
import { Role } from '../generated/prisma/enums.js';
import {
  CatalogCategoryDto,
  CatalogItemDto,
  CreateCategoryDto,
  CreateItemDto,
  toCategoryDto,
  toItemDto,
  UpdateCategoryDto,
  UpdateItemDto,
} from './catalog.dto.js';
import { CatalogService } from './catalog.service.js';

@ApiTags('catalog')
@Controller('catalog')
export class CatalogController {
  constructor(private readonly catalog: CatalogService) {}

  /** Active categories and items with prices, for the customer app and website. */
  @Public()
  @Get()
  async list(): Promise<CatalogCategoryDto[]> {
    return (await this.catalog.list(true)).map(toCategoryDto);
  }
}

@ApiTags('admin · catalog')
@ApiBearerAuth()
@Roles(Role.ADMIN, Role.SUPER_ADMIN)
@Controller('admin/catalog')
export class AdminCatalogController {
  constructor(
    private readonly catalog: CatalogService,
    private readonly audit: AuditService,
  ) {}

  @Get()
  async list(): Promise<CatalogCategoryDto[]> {
    return (await this.catalog.list(false)).map(toCategoryDto);
  }

  @Post('categories')
  async createCategory(@CurrentUser() actor: User, @Body() dto: CreateCategoryDto): Promise<CatalogCategoryDto> {
    const c = await this.catalog.createCategory(dto);
    this.audit.log(actor.id, 'catalog.category.created', 'catalog_category', c.id, dto);
    return toCategoryDto({ ...c, items: [] });
  }

  @Patch('categories/:id')
  async updateCategory(
    @CurrentUser() actor: User,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateCategoryDto,
  ): Promise<CatalogCategoryDto> {
    const c = await this.catalog.updateCategory(id, dto);
    this.audit.log(actor.id, 'catalog.category.updated', 'catalog_category', id, dto);
    return toCategoryDto({ ...c, items: [] });
  }

  @Delete('categories/:id')
  @HttpCode(204)
  async deleteCategory(@CurrentUser() actor: User, @Param('id', ParseUUIDPipe) id: string): Promise<void> {
    await this.catalog.deleteCategory(id);
    this.audit.log(actor.id, 'catalog.category.deleted', 'catalog_category', id);
  }

  @Post('items')
  async createItem(@CurrentUser() actor: User, @Body() dto: CreateItemDto): Promise<CatalogItemDto> {
    const i = await this.catalog.createItem(dto);
    this.audit.log(actor.id, 'catalog.item.created', 'catalog_item', i.id, dto);
    return toItemDto(i);
  }

  @Patch('items/:id')
  async updateItem(
    @CurrentUser() actor: User,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateItemDto,
  ): Promise<CatalogItemDto> {
    const i = await this.catalog.updateItem(id, dto);
    this.audit.log(actor.id, 'catalog.item.updated', 'catalog_item', id, dto);
    return toItemDto(i);
  }

  /** Deletes the item, or deactivates it if past orders reference it. */
  @Delete('items/:id')
  async deleteItem(
    @CurrentUser() actor: User,
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<DeleteResultDto> {
    const result = await this.catalog.deleteItem(id);
    this.audit.log(actor.id, result.deleted ? 'catalog.item.deleted' : 'catalog.item.deactivated', 'catalog_item', id);
    return result;
  }
}
