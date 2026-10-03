import { Body, Controller, Delete, Get, HttpCode, Param, ParseUUIDPipe, Patch, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser, Roles } from '../auth/decorators.js';
import type { User } from '../generated/prisma/client.js';
import { Role } from '../generated/prisma/enums.js';
import { AddressDto, CreateAddressDto, toAddressDto, UpdateAddressDto } from './address.dto.js';
import { SettingsService } from '../settings/settings.service.js';
import { AddressesService } from './addresses.service.js';

@ApiTags('addresses')
@ApiBearerAuth()
@Roles(Role.CUSTOMER)
@Controller('me/addresses')
export class AddressesController {
  constructor(
    private readonly addresses: AddressesService,
    private readonly settings: SettingsService,
  ) {}

  @Get()
  async list(@CurrentUser() user: User): Promise<AddressDto[]> {
    const [addresses, area] = await Promise.all([this.addresses.list(user.id), this.settings.get()]);
    return addresses.map((a) => toAddressDto(a, area));
  }

  /** Saving is allowed outside the service area; `serviceable` tells the app to show the "not in your area yet" state. */
  @Post()
  async create(@CurrentUser() user: User, @Body() dto: CreateAddressDto): Promise<AddressDto> {
    return toAddressDto(await this.addresses.create(user.id, dto), await this.settings.get());
  }

  @Patch(':id')
  async update(
    @CurrentUser() user: User,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateAddressDto,
  ): Promise<AddressDto> {
    return toAddressDto(await this.addresses.update(user.id, id, dto), await this.settings.get());
  }

  @Delete(':id')
  @HttpCode(204)
  remove(@CurrentUser() user: User, @Param('id', ParseUUIDPipe) id: string): Promise<void> {
    return this.addresses.remove(user.id, id);
  }
}
