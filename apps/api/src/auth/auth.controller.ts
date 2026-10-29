import { Body, Controller, HttpCode, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiProperty, ApiTags } from '@nestjs/swagger';
import { Throttle } from '@nestjs/throttler';
import { IsEmail, IsEnum, IsString, MaxLength, MinLength } from 'class-validator';
import { ClientApp } from '../generated/prisma/enums.js';
import { toUserDto, UserDto } from '../users/user.dto.js';
import { AuthService } from './auth.service.js';
import { AllowUnregistered, CurrentIdentity, Public } from './decorators.js';
import type { VerifiedIdentity } from './token-verifier.js';

export class StartSessionDto {
  @ApiProperty({ enum: ClientApp, enumName: 'ClientApp' })
  @IsEnum(ClientApp)
  app!: ClientApp;
}

export class AdminLoginDto {
  @ApiProperty({ example: 'admin@example.com' })
  @IsEmail()
  @MaxLength(254)
  email!: string;

  @ApiProperty()
  @IsString()
  @MinLength(1)
  @MaxLength(200)
  password!: string;
}

export class AdminLoginResultDto {
  /** Firebase custom token: pass it to `signInWithCustomToken`, then use the resulting ID token as the Bearer. */
  @ApiProperty() token!: string;
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

  /** Admin sign-in with email + password. Everyone else signs in with a phone code. */
  @Post('admin-login')
  @HttpCode(200)
  @Public()
  @Throttle({ default: { limit: 5, ttl: 60_000 } })
  async adminLogin(@Body() dto: AdminLoginDto): Promise<AdminLoginResultDto> {
    return { token: await this.auth.passwordLogin(dto.email, dto.password) };
  }
}
