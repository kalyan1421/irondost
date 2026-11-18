import { Controller, Get, Query, Res } from '@nestjs/common';
import { ApiBearerAuth, ApiOkResponse, ApiOperation, ApiProduces, ApiTags } from '@nestjs/swagger';
import type { Response } from 'express';
import { Roles } from '../auth/decorators.js';
import { Role } from '../generated/prisma/enums.js';
import { LedgerFilterQuery, LedgerPageDto, LedgerQuery } from './ledger.dto.js';
import { EXPORT_ROW_LIMIT, LedgerService } from './ledger.service.js';

@ApiTags('admin · payments')
@ApiBearerAuth()
@Roles(Role.ADMIN, Role.SUPER_ADMIN)
@Controller('admin/ledger')
export class LedgerController {
  constructor(private readonly ledger: LedgerService) {}

  @ApiOperation({
    summary: 'Payments and refunds as one list, newest first, with totals for everything the filters match',
    description:
      'Each entry is one payment or one refund, with its order and customer. `status=problem` finds what needs ' +
      'attention: PENDING and FAILED entries. Dates are IST. Never includes gateway payloads.',
  })
  @Get()
  list(@Query() q: LedgerQuery): Promise<LedgerPageDto> {
    return this.ledger.list(q);
  }

  @ApiOperation({
    summary: 'The same list as a CSV download',
    description:
      `Takes the list's filters. At most ${EXPORT_ROW_LIMIT.toLocaleString('en-US')} newest entries; when more matched, ` +
      'the X-Export-Truncated header is "true". Cells that start with =, +, - or @ are prefixed with an apostrophe.',
  })
  @ApiProduces('text/csv')
  @ApiOkResponse({ description: 'CSV file', schema: { type: 'string', format: 'binary' } })
  @Get('export')
  async download(@Query() q: LedgerFilterQuery, @Res({ passthrough: true }) res: Response): Promise<string> {
    const file = await this.ledger.exportCsv(q);
    res.setHeader('Content-Type', 'text/csv; charset=utf-8');
    res.setHeader('Content-Disposition', `attachment; filename="${file.filename}"`);
    // Customer names and phone numbers: never kept by a shared cache.
    res.setHeader('Cache-Control', 'no-store');
    res.setHeader('X-Export-Rows', String(file.rows));
    res.setHeader('X-Export-Truncated', String(file.truncated));
    return file.csv;
  }
}
