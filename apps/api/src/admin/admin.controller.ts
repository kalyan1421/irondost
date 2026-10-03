import { Body, Controller, Delete, Get, HttpCode, Param, ParseUUIDPipe, Patch, Post, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { AddressDto, CreateAddressDto, toAddressDto, UpdateAddressDto } from '../addresses/address.dto.js';
import { AddressesService } from '../addresses/addresses.service.js';
import { AuditService } from '../audit/audit.service.js';
import { CurrentUser, Roles } from '../auth/decorators.js';
import type { User } from '../generated/prisma/client.js';
import { Role } from '../generated/prisma/enums.js';
import { AppError } from '../common/errors.js';
import { SettingsService } from '../settings/settings.service.js';
import { toUserDto, UserDto } from '../users/user.dto.js';
import {
  BusinessSettingsDto,
  CreateCustomerDto,
  CreateStaffDto,
  CustomerPageDto,
  CustomersQuery,
  DashboardDto,
  UpdateCustomerDto,
  UpdateSettingsDto,
  UpdateStaffDto,
  toSettingsDto,
} from './admin.dto.js';
import { AdminService } from './admin.service.js';

@ApiTags('admin · customers')
@ApiBearerAuth()
@Roles(Role.ADMIN, Role.SUPER_ADMIN)
@Controller('admin')
export class AdminController {
  constructor(
    private readonly admin: AdminService,
    private readonly addresses: AddressesService,
    private readonly settings: SettingsService,
    private readonly audit: AuditService,
  ) {}

  @Get('dashboard')
  dashboard(): Promise<DashboardDto> {
    return this.admin.dashboard();
  }

  // ── Customers ──

  @Get('customers')
  customers(@Query() q: CustomersQuery): Promise<CustomerPageDto> {
    return this.admin.customers(q);
  }

  @Get('customers/:id')
  async customer(@Param('id', ParseUUIDPipe) id: string): Promise<UserDto> {
    return toUserDto(await this.admin.customer(id));
  }

  @Post('customers')
  async createCustomer(@CurrentUser() actor: User, @Body() dto: CreateCustomerDto): Promise<UserDto> {
    const user = await this.admin.createCustomer(dto);
    this.audit.log(actor.id, 'customer.created', 'user', user.id, { phone: user.phone });
    return toUserDto(user);
  }

  @Patch('customers/:id')
  async updateCustomer(
    @CurrentUser() actor: User,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateCustomerDto,
  ): Promise<UserDto> {
    const user = await this.admin.updateCustomer(id, dto);
    this.audit.log(actor.id, 'customer.updated', 'user', id, dto);
    return toUserDto(user);
  }

  @Get('customers/:id/addresses')
  async addressesOf(@Param('id', ParseUUIDPipe) id: string): Promise<AddressDto[]> {
    await this.admin.customer(id);
    const [addresses, area] = await Promise.all([this.addresses.list(id), this.settings.get()]);
    return addresses.map((a) => toAddressDto(a, area));
  }

  @Post('customers/:id/addresses')
  async addAddress(
    @CurrentUser() actor: User,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: CreateAddressDto,
  ): Promise<AddressDto> {
    await this.admin.customer(id);
    const address = await this.addresses.create(id, dto);
    this.audit.log(actor.id, 'customer.address_added', 'address', address.id, { customerId: id });
    return toAddressDto(address, await this.settings.get());
  }

  @Patch('customers/:id/addresses/:addressId')
  async updateAddress(
    @CurrentUser() actor: User,
    @Param('id', ParseUUIDPipe) id: string,
    @Param('addressId', ParseUUIDPipe) addressId: string,
    @Body() dto: UpdateAddressDto,
  ): Promise<AddressDto> {
    const address = await this.addresses.update(id, addressId, dto);
    this.audit.log(actor.id, 'customer.address_updated', 'address', addressId, dto);
    return toAddressDto(address, await this.settings.get());
  }

  @Delete('customers/:id/addresses/:addressId')
  @HttpCode(204)
  async removeAddress(
    @CurrentUser() actor: User,
    @Param('id', ParseUUIDPipe) id: string,
    @Param('addressId', ParseUUIDPipe) addressId: string,
  ): Promise<void> {
    await this.addresses.remove(id, addressId);
    this.audit.log(actor.id, 'customer.address_removed', 'address', addressId);
  }

  // ── Settings ──

  @Get('settings')
  async getSettings(): Promise<BusinessSettingsDto> {
    return toSettingsDto(await this.settings.get());
  }

  @Roles(Role.SUPER_ADMIN)
  @Patch('settings')
  async updateSettings(@CurrentUser() actor: User, @Body() dto: UpdateSettingsDto): Promise<BusinessSettingsDto> {
    const current = await this.settings.get();
    const radius = [
      dto.serviceCenterLatitude === undefined ? current.serviceCenterLatitude : dto.serviceCenterLatitude,
      dto.serviceCenterLongitude === undefined ? current.serviceCenterLongitude : dto.serviceCenterLongitude,
      dto.serviceRadiusKm === undefined ? current.serviceRadiusKm : dto.serviceRadiusKm,
    ];
    if (radius.some((v) => v === null) && radius.some((v) => v !== null)) {
      throw AppError.badRequest('SERVICE_AREA_INCOMPLETE', 'Set the hub location and the radius together, or clear all three');
    }
    if (dto.servicePincodes) dto.servicePincodes = [...new Set(dto.servicePincodes)].sort();
    const s = await this.settings.update(dto);
    this.audit.log(actor.id, 'settings.updated', 'business_settings', '1', dto);
    return toSettingsDto(s);
  }
}

@ApiTags('admin · staff')
@ApiBearerAuth()
@Roles(Role.SUPER_ADMIN)
@Controller('admin/staff')
export class AdminStaffController {
  constructor(
    private readonly admin: AdminService,
    private readonly audit: AuditService,
  ) {}

  @Get()
  async list(): Promise<UserDto[]> {
    return (await this.admin.staff()).map(toUserDto);
  }

  @Post()
  async create(@CurrentUser() actor: User, @Body() dto: CreateStaffDto): Promise<UserDto> {
    const user = await this.admin.createStaff(dto);
    this.audit.log(actor.id, 'staff.created', 'user', user.id, { phone: user.phone, role: user.role });
    return toUserDto(user);
  }

  @Patch(':id')
  async update(
    @CurrentUser() actor: User,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateStaffDto,
  ): Promise<UserDto> {
    const user = await this.admin.updateStaff(actor, id, dto);
    this.audit.log(actor.id, 'staff.updated', 'user', id, dto);
    return toUserDto(user);
  }
}
