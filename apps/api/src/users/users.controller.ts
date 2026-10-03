import { Body, Controller, Delete, Get, HttpCode, Patch, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../auth/decorators.js';
import type { User } from '../generated/prisma/client.js';
import { MeDto, RegisterDeviceDto, RemoveDeviceDto, UpdateMeDto } from './user.dto.js';
import { UsersService } from './users.service.js';

@ApiTags('me')
@ApiBearerAuth()
@Controller('me')
export class UsersController {
  constructor(private readonly users: UsersService) {}

  @Get()
  me(@CurrentUser() user: User): Promise<MeDto> {
    return this.users.me(user);
  }

  @Patch()
  update(@CurrentUser() user: User, @Body() dto: UpdateMeDto): Promise<MeDto> {
    return this.users.update(user, dto);
  }

  @Post('devices')
  @HttpCode(204)
  registerDevice(@CurrentUser() user: User, @Body() dto: RegisterDeviceDto): Promise<void> {
    return this.users.registerDevice(user, dto);
  }

  /** Call on sign-out so the device stops receiving this user's pushes. */
  @Post('devices/remove')
  @HttpCode(204)
  removeDevice(@CurrentUser() user: User, @Body() dto: RemoveDeviceDto): Promise<void> {
    return this.users.removeDevice(user, dto.fcmToken);
  }

  @Delete()
  @HttpCode(204)
  deleteAccount(@CurrentUser() user: User): Promise<void> {
    return this.users.deleteAccount(user);
  }
}
