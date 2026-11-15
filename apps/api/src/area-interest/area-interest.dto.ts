import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsIn, IsOptional, IsUUID } from 'class-validator';
import { PageQueryDto } from '../common/pagination.js';
import { DISTANCE_BANDS, type DistanceBand } from '../settings/service-area.js';

export class RegisterAreaInterestDto {
  @ApiProperty({ description: 'One of the signed-in customer\'s saved addresses. The place is read from the saved address, never from the request.' })
  @IsUUID()
  addressId!: string;
}

/** What the customer gets back: the request is recorded (an earlier one for the same PIN code counts as this one). */
export class AreaInterestDto {
  @ApiProperty() id!: string;
  @ApiProperty() pincode!: string;
  @ApiProperty({ example: 'Gachibowli' }) locality!: string;
  @ApiProperty() createdAt!: Date;
}

export const AREA_INTEREST_STATUSES = ['OPEN', 'TOLD', 'ALL'] as const;
export type AreaInterestStatus = (typeof AREA_INTEREST_STATUSES)[number];

export class AreaInterestQuery extends PageQueryDto {
  @ApiPropertyOptional({
    enum: AREA_INTEREST_STATUSES,
    enumName: 'AreaInterestStatus',
    default: 'OPEN',
    description: 'OPEN: not told yet. TOLD: staff told the customer. ALL: both.',
  })
  @IsOptional()
  @IsIn(AREA_INTEREST_STATUSES)
  status: AreaInterestStatus = 'OPEN';
}

/** Open requests for one PIN code and locality in one distance band. */
export class AreaInterestGroupDto {
  @ApiProperty() pincode!: string;
  @ApiProperty() locality!: string;
  @ApiProperty({ enum: DISTANCE_BANDS, enumName: 'DistanceBand' }) band!: DistanceBand;
  @ApiProperty() count!: number;
  @ApiProperty({ nullable: true, type: Number, description: 'Nearest request to the centre, in km' }) nearestKm!: number | null;
  @ApiProperty() newestAt!: Date;
}

export class AreaInterestBandTotalDto {
  @ApiProperty({ enum: DISTANCE_BANDS, enumName: 'DistanceBand' }) band!: DistanceBand;
  @ApiProperty() count!: number;
}

/** One request, for staff. The customer's name and number are shown only here. */
export class AreaInterestItemDto {
  @ApiProperty() id!: string;
  @ApiProperty() customerId!: string;
  @ApiProperty({ nullable: true, type: String }) customerName!: string | null;
  @ApiProperty({ nullable: true, type: String, description: 'The number the customer signed in with (or typed at checkout)' }) customerPhone!: string | null;
  @ApiProperty() pincode!: string;
  @ApiProperty() locality!: string;
  @ApiProperty({ nullable: true, type: Number }) distanceKm!: number | null;
  @ApiProperty({ enum: DISTANCE_BANDS, enumName: 'DistanceBand' }) band!: DistanceBand;
  @ApiProperty() createdAt!: Date;
  @ApiProperty({ nullable: true, type: Date }) notifiedAt!: Date | null;
}

export class AreaInterestOverviewDto {
  @ApiProperty({ description: 'Requests staff have not told yet' }) openTotal!: number;
  @ApiProperty({ type: [AreaInterestBandTotalDto], description: 'Open requests per distance band, nearest first. Bands with none are left out.' })
  bands!: AreaInterestBandTotalDto[];
  @ApiProperty({ type: [AreaInterestGroupDto], description: 'Open requests per PIN code, locality and band, most first' })
  areas!: AreaInterestGroupDto[];
  @ApiProperty({ type: [AreaInterestItemDto], description: 'The requests matching `status`, newest first' }) items!: AreaInterestItemDto[];
  @ApiProperty() page!: number;
  @ApiProperty() pageSize!: number;
  @ApiProperty({ description: 'Requests matching `status`' }) total!: number;
}
