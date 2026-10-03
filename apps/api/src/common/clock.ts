import { Injectable } from '@nestjs/common';

/** Injectable time source so scheduling rules can be tested at a fixed instant. */
@Injectable()
export class Clock {
  now(): Date {
    return new Date();
  }
}
