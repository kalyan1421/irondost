import { Body, Controller, HttpCode, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiProperty, ApiTags } from '@nestjs/swagger';
import { Throttle } from '@nestjs/throttler';
import { IsEnum } from 'class-validator';
import { ClientApp } from '../generated/prisma/enums.js';
import { toUserDto, UserDto } from '../users/user.dto.js';
import { AuthService } from './auth.service.js';
import { AllowUnregistered, CurrentIdentity } from './decorators.js';
import type { VerifiedIdentity } from './token-verifier.js';

export class StartSessionDto {
  @ApiProperty({ enum: ClientApp, enumName: 'ClientApp' })
  @IsEnum(ClientApp)
  app!: ClientApp;
}

@ApiTags('auth')
@ApiBearerAuth()
@Controller('auth')
export class AuthController {
  constructor(private readonly auth: AuthService) {}

  /** Exchange a verified Firebase phone-OTP token for a user record. */
  @Post('session')
  @HttpCode(200)
  @AllowUnregistered()
  @Throttle({ default: { limit: 10, ttl: 60_000 } })
  async session(
    @CurrentIdentity() identity: VerifiedIdentity,
    @Body() dto: StartSessionDto,
  ): Promise<UserDto> {
    return toUserDto(await this.auth.startSession(identity, dto.app));
  }
}
