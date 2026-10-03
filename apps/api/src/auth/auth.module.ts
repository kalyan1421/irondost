import { Global, Module } from '@nestjs/common';
import { AuthController } from './auth.controller.js';
import { AuthService } from './auth.service.js';
import { FirebaseService } from './firebase.service.js';
import { TokenVerifier } from './token-verifier.js';

@Global()
@Module({
  controllers: [AuthController],
  providers: [AuthService, FirebaseService, TokenVerifier],
  exports: [FirebaseService, TokenVerifier],
})
export class AuthModule {}
