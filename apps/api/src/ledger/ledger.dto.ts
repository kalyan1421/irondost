import { ApiProperty, ApiPropertyOptional, IntersectionType } from '@nestjs/swagger';
import { IsIn, IsOptional, IsString, Matches, MaxLength } from 'class-validator';
import { PageQueryDto } from '../common/pagination.js';

export const LEDGER_KINDS = ['PAYMENT', 'REFUND'] as const;
export type LedgerKind = (typeof LEDGER_KINDS)[number];

/** A payment's status (CREATED, CAPTURED, FAILED, REFUNDED) or a refund's (PENDING, PROCESSED, FAILED), as stored. */
export const LEDGER_STATUSES = ['CREATED', 'CAPTURED', 'FAILED', 'REFUNDED', 'PENDING', 'PROCESSED'] as const;
export type LedgerStatus = (typeof LEDGER_STATUSES)[number];

/** The status filter: any status above, or `problem` for everything that is PENDING or FAILED. */
export const LEDGER_STATUS_FILTERS = [...LEDGER_STATUSES, 'problem'] as const;
export type LedgerStatusFilter = (typeof LEDGER_STATUS_FILTERS)[number];

/** The gateway or channel: a payment's provider (RAZORPAY, CASH) or a refund's method (RAZORPAY, CASH, BANK_TRANSFER). */
export const LEDGER_METHODS = ['RAZORPAY', 'CASH', 'BANK_TRANSFER'] as const;
export type LedgerMethod = (typeof LEDGER_METHODS)[number];

const IST_DATE = /^\d{4}-\d{2}-\d{2}$/;

/** What both the list and the CSV export can be narrowed by. */
export class LedgerFilterQuery {
  @ApiPropertyOptional({ enum: LEDGER_KINDS, enumName: 'LedgerKind' })
  @IsOptional()
  @IsIn(LEDGER_KINDS)
  kind?: LedgerKind;

  @ApiPropertyOptional({
    enum: LEDGER_STATUS_FILTERS,
    enumName: 'LedgerStatusFilter',
    description:
      'One status, or `problem` for PENDING or FAILED entries. CREATED (an online checkout that was started and not ' +
      'finished) is not a problem on its own.',
  })
  @IsOptional()
  @IsIn(LEDGER_STATUS_FILTERS)
  status?: LedgerStatusFilter;

  @ApiPropertyOptional({
    enum: LEDGER_METHODS,
    enumName: 'LedgerMethod',
    description: 'Payment provider or refund method',
  })
  @IsOptional()
  @IsIn(LEDGER_METHODS)
  method?: LedgerMethod;

  @ApiPropertyOptional({ example: '2026-10-01', description: 'First day to include (IST)' })
  @IsOptional()
  @Matches(IST_DATE)
  from?: string;

  @ApiPropertyOptional({ example: '2026-10-31', description: 'Last day to include (IST, inclusive)' })
  @IsOptional()
  @Matches(IST_DATE)
  to?: string;

  @ApiPropertyOptional({ description: 'Order number, or the customer\'s phone (sign-in or contact number)' })
  @IsOptional()
  @IsString()
  @MaxLength(60)
  search?: string;
}

export class LedgerQuery extends IntersectionType(LedgerFilterQuery, PageQueryDto) {}

export class LedgerEntryDto {
  @ApiProperty({ description: 'Id of the payment or refund record' }) id!: string;
  @ApiProperty({ enum: LEDGER_KINDS, enumName: 'LedgerKind' }) kind!: LedgerKind;
  @ApiProperty({ enum: LEDGER_STATUSES, enumName: 'LedgerStatus' }) status!: LedgerStatus;
  @ApiProperty({ enum: LEDGER_METHODS, enumName: 'LedgerMethod', description: 'Payment provider or refund method' })
  method!: LedgerMethod;
  @ApiProperty({ description: 'Always positive, in paise. `kind` says which way the money moved.' }) amountPaise!: number;
  @ApiProperty() orderId!: string;
  @ApiProperty() orderNumber!: string;
  @ApiProperty() customerId!: string;
  @ApiProperty({ nullable: true, type: String, description: 'Null once the customer has deleted their account' })
  customerName!: string | null;
  @ApiProperty({ nullable: true, type: String, description: 'Sign-in number, else the contact number typed at checkout' })
  customerPhone!: string | null;
  @ApiProperty({
    nullable: true,
    type: String,
    description: 'Razorpay payment, order or refund id. Empty for cash and bank transfers.',
  })
  reference!: string | null;
  @ApiProperty({
    nullable: true,
    type: String,
    description: 'The note shown to the customer on a refund; who collected the cash on a cash payment',
  })
  note!: string | null;
  @ApiProperty({ nullable: true, type: String, description: 'Why a refund failed, when known' }) failureReason!: string | null;
  @ApiProperty({
    description:
      'When the money moved: confirmed for a captured payment, processed for a refund that went through, ' +
      'otherwise when the record was created',
  })
  occurredAt!: Date;
}

export class LedgerAmountDto {
  @ApiProperty() count!: number;
  @ApiProperty({ description: 'Sum in paise' }) amountPaise!: number;
}

/** Counts and sums over every entry the filters match, not just the page. */
export class LedgerTotalsDto {
  @ApiProperty({ type: LedgerAmountDto, description: 'Payments with status CAPTURED' }) captured!: LedgerAmountDto;
  @ApiProperty({ type: LedgerAmountDto, description: 'Refunds with status PROCESSED' }) refunded!: LedgerAmountDto;
  @ApiProperty({ type: LedgerAmountDto, description: 'Refunds with status PENDING' }) refundPending!: LedgerAmountDto;
  @ApiProperty({ type: LedgerAmountDto, description: 'Payments and refunds with status FAILED' }) failed!: LedgerAmountDto;
}

export class LedgerPageDto {
  @ApiProperty({ type: [LedgerEntryDto] }) items!: LedgerEntryDto[];
  @ApiProperty() page!: number;
  @ApiProperty() pageSize!: number;
  @ApiProperty({ description: 'Entries the filters match' }) total!: number;
  @ApiProperty({ type: LedgerTotalsDto }) totals!: LedgerTotalsDto;
}
