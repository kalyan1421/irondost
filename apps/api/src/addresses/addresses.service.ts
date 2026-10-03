import { Injectable } from '@nestjs/common';
import { AppError } from '../common/errors.js';
import type { Address } from '../generated/prisma/client.js';
import { PrismaService } from '../prisma/prisma.service.js';
import type { CreateAddressDto, UpdateAddressDto } from './address.dto.js';

const MAX_ADDRESSES = 10;

/** Address book for a customer. Used by the customer app and by admins on a customer's behalf. */
@Injectable()
export class AddressesService {
  constructor(private readonly prisma: PrismaService) {}

  list(userId: string): Promise<Address[]> {
    return this.prisma.address.findMany({
      where: { userId, deletedAt: null },
      orderBy: [{ isPrimary: 'desc' }, { createdAt: 'asc' }],
    });
  }

  async get(userId: string, id: string): Promise<Address> {
    const address = await this.prisma.address.findFirst({ where: { id, userId, deletedAt: null } });
    if (!address) throw AppError.notFound('Address');
    return address;
  }

  async create(userId: string, dto: CreateAddressDto): Promise<Address> {
    return this.prisma.$transaction(async (tx) => {
      const count = await tx.address.count({ where: { userId, deletedAt: null } });
      if (count >= MAX_ADDRESSES) {
        throw AppError.badRequest('ADDRESS_LIMIT', `You can save up to ${MAX_ADDRESSES} addresses`);
      }
      // The first address is always primary.
      const isPrimary = count === 0 || dto.isPrimary === true;
      if (isPrimary) {
        await tx.address.updateMany({ where: { userId, isPrimary: true }, data: { isPrimary: false } });
      }
      return tx.address.create({ data: { ...dto, userId, isPrimary } });
    });
  }

  async update(userId: string, id: string, dto: UpdateAddressDto): Promise<Address> {
    await this.get(userId, id);
    return this.prisma.$transaction(async (tx) => {
      if (dto.isPrimary === true) {
        await tx.address.updateMany({ where: { userId, isPrimary: true }, data: { isPrimary: false } });
      }
      // Un-setting the primary flag directly is not allowed; pick another primary instead.
      const { isPrimary, ...rest } = dto;
      return tx.address.update({
        where: { id },
        data: { ...rest, ...(isPrimary === true ? { isPrimary: true } : {}) },
      });
    });
  }

  /** Soft delete: past orders keep a snapshot, and this row stays for reference. */
  async remove(userId: string, id: string): Promise<void> {
    const address = await this.get(userId, id);
    await this.prisma.$transaction(async (tx) => {
      await tx.address.update({ where: { id }, data: { deletedAt: new Date(), isPrimary: false } });
      if (address.isPrimary) {
        const next = await tx.address.findFirst({
          where: { userId, deletedAt: null },
          orderBy: { createdAt: 'asc' },
        });
        if (next) await tx.address.update({ where: { id: next.id }, data: { isPrimary: true } });
      }
    });
  }
}
