import { Injectable } from '@nestjs/common';
import { AddressesService } from '../addresses/addresses.service.js';
import { AppError } from '../common/errors.js';
import { pageArgs } from '../common/pagination.js';
import { customerPhone } from '../common/phone.js';
import { Prisma, type AreaInterest, type User } from '../generated/prisma/client.js';
import { PrismaService } from '../prisma/prisma.service.js';
import { checkServiceArea, distanceBand, distanceFromCentre, DISTANCE_BANDS, type DistanceBand } from '../settings/service-area.js';
import { SettingsService } from '../settings/settings.service.js';
import type {
  AreaInterestBandTotalDto,
  AreaInterestDto,
  AreaInterestGroupDto,
  AreaInterestItemDto,
  AreaInterestOverviewDto,
  AreaInterestQuery,
} from './area-interest.dto.js';

type WithUser = AreaInterest & { user: Pick<User, 'id' | 'name' | 'phone' | 'contactPhone'> };

const BAND_ORDER = new Map<DistanceBand, number>(DISTANCE_BANDS.map((band, i) => [band, i]));

/** The waiting list: customers outside the service area who asked to be told when IronDost starts serving them. */
@Injectable()
export class AreaInterestService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly addresses: AddressesService,
    private readonly settings: SettingsService,
  ) {}

  /**
   * Records that the signed-in customer wants to hear when we serve one of their saved addresses. The place comes from the
   * saved address, never from the request, and the contact is their own signed-in number. Asking again for the same PIN
   * code returns the open request instead of adding another.
   */
  async register(user: User, addressId: string): Promise<AreaInterestDto> {
    // The number is the one thing staff use to reach them, so there must be one on the account.
    if (!customerPhone(user)) {
      throw AppError.badRequest('PHONE_REQUIRED', 'Add your mobile number first, so we know where to reach you');
    }
    const address = await this.addresses.get(user.id, addressId);
    const settings = await this.settings.get();
    if (checkServiceArea(address, settings).serviceable) {
      throw AppError.badRequest('ADDRESS_SERVICEABLE', 'We already pick up from this address. You can book a pickup now');
    }

    const open = () => this.prisma.areaInterest.findFirst({ where: { userId: user.id, pincode: address.pincode, notifiedAt: null } });
    let row = await open();
    if (!row) {
      try {
        row = await this.prisma.areaInterest.create({
          data: {
            userId: user.id,
            addressId: address.id,
            latitude: address.latitude,
            longitude: address.longitude,
            pincode: address.pincode,
            locality: address.area?.trim() || address.city,
            distanceKm: distanceFromCentre(address, settings),
          },
        });
      } catch (err) {
        // A second tap landed at the same moment: the first one's row is the request.
        if (!(err instanceof Prisma.PrismaClientKnownRequestError) || err.code !== 'P2002') throw err;
        row = await open();
        if (!row) throw err;
      }
    }
    return { id: row.id, pincode: row.pincode, locality: row.locality, createdAt: row.createdAt };
  }

  async overview(q: AreaInterestQuery): Promise<AreaInterestOverviewDto> {
    const where: Prisma.AreaInterestWhereInput = q.status === 'OPEN' ? { notifiedAt: null } : q.status === 'TOLD' ? { notifiedAt: { not: null } } : {};
    const [groups, rows, total] = await Promise.all([
      this.openGroups(),
      this.prisma.areaInterest.findMany({
        where,
        orderBy: [{ createdAt: 'desc' }, { id: 'asc' }],
        include: { user: { select: { id: true, name: true, phone: true, contactPhone: true } } },
        ...pageArgs(q),
      }),
      this.prisma.areaInterest.count({ where }),
    ]);

    const perBand = new Map<DistanceBand, number>();
    for (const g of groups) perBand.set(g.band, (perBand.get(g.band) ?? 0) + g.count);
    const bands: AreaInterestBandTotalDto[] = [...perBand]
      .map(([band, count]) => ({ band, count }))
      .sort((a, b) => BAND_ORDER.get(a.band)! - BAND_ORDER.get(b.band)!);

    return {
      openTotal: groups.reduce((sum, g) => sum + g.count, 0),
      bands,
      areas: groups,
      items: rows.map(toItem),
      page: q.page,
      pageSize: q.pageSize,
      total,
    };
  }

  /** Open requests by PIN code, locality and band. One query: the band is worked out in SQL so a long list is never loaded. */
  private async openGroups(): Promise<AreaInterestGroupDto[]> {
    const rows = await this.prisma.$queryRaw<
      { pincode: string; locality: string; band: DistanceBand; count: number; nearest_km: number | null; newest_at: Date }[]
    >`
      SELECT pincode, locality,
        CASE
          WHEN distance_km IS NULL THEN 'UNKNOWN'
          WHEN distance_km < 6 THEN 'UNDER_6'
          WHEN distance_km < 8 THEN 'KM_6_8'
          WHEN distance_km < 10 THEN 'KM_8_10'
          ELSE 'KM_10_PLUS'
        END AS band,
        COUNT(*)::int AS count,
        MIN(distance_km) AS nearest_km,
        MAX(created_at) AS newest_at
      FROM area_interest
      WHERE notified_at IS NULL
      GROUP BY pincode, locality, band
      ORDER BY count DESC, newest_at DESC, pincode, locality`;
    return rows.map((r) => ({ pincode: r.pincode, locality: r.locality, band: r.band, count: r.count, nearestKm: r.nearest_km, newestAt: r.newest_at }));
  }

  /** Staff told the customer we now serve them. Telling again changes nothing. */
  async markTold(id: string): Promise<AreaInterestItemDto & { alreadyTold: boolean }> {
    const { count } = await this.prisma.areaInterest.updateMany({ where: { id, notifiedAt: null }, data: { notifiedAt: new Date() } });
    const row = await this.prisma.areaInterest.findUnique({
      where: { id },
      include: { user: { select: { id: true, name: true, phone: true, contactPhone: true } } },
    });
    if (!row) throw AppError.notFound('Request');
    return { ...toItem(row), alreadyTold: count === 0 };
  }
}

function toItem(r: WithUser): AreaInterestItemDto {
  return {
    id: r.id,
    customerId: r.user.id,
    customerName: r.user.name,
    customerPhone: customerPhone(r.user),
    pincode: r.pincode,
    locality: r.locality,
    distanceKm: r.distanceKm,
    band: distanceBand(r.distanceKm),
    createdAt: r.createdAt,
    notifiedAt: r.notifiedAt,
  };
}
