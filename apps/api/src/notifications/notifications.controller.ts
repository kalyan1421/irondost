import { Controller, Get, HttpCode, Param, ParseUUIDPipe, Post, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiProperty, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../auth/decorators.js';
import { pageArgs, PageQueryDto } from '../common/pagination.js';
import type { User } from '../generated/prisma/client.js';
import { PrismaService } from '../prisma/prisma.service.js';

export class NotificationDto {
  @ApiProperty() id!: string;
  @ApiProperty() type!: string;
  @ApiProperty() title!: string;
  @ApiProperty() body!: string;
  @ApiProperty({ type: Object, nullable: true }) data!: unknown;
  @ApiProperty({ nullable: true, type: Date }) readAt!: Date | null;
  @ApiProperty() createdAt!: Date;
}

export class NotificationPageDto {
  @ApiProperty({ type: [NotificationDto] }) items!: NotificationDto[];
  @ApiProperty() unread!: number;
  @ApiProperty() page!: number;
  @ApiProperty() pageSize!: number;
  @ApiProperty() total!: number;
}

@ApiTags('me')
@ApiBearerAuth()
@Controller('me/notifications')
export class NotificationsController {
  constructor(private readonly prisma: PrismaService) {}

  @Get()
  async list(@CurrentUser() user: User, @Query() q: PageQueryDto): Promise<NotificationPageDto> {
    const where = { userId: user.id };
    const [items, total, unread] = await Promise.all([
      this.prisma.notification.findMany({ where, orderBy: { createdAt: 'desc' }, ...pageArgs(q) }),
      this.prisma.notification.count({ where }),
      this.prisma.notification.count({ where: { userId: user.id, readAt: null } }),
    ]);
    return {
      items: items.map((n) => ({
        id: n.id,
        type: n.type,
        title: n.title,
        body: n.body,
        data: n.data,
        readAt: n.readAt,
        createdAt: n.createdAt,
      })),
      unread,
      page: q.page,
      pageSize: q.pageSize,
      total,
    };
  }

  @Post(':id/read')
  @HttpCode(204)
  async read(@CurrentUser() user: User, @Param('id', ParseUUIDPipe) id: string): Promise<void> {
    await this.prisma.notification.updateMany({ where: { id, userId: user.id, readAt: null }, data: { readAt: new Date() } });
  }

  @Post('read-all')
  @HttpCode(204)
  async readAll(@CurrentUser() user: User): Promise<void> {
    await this.prisma.notification.updateMany({ where: { userId: user.id, readAt: null }, data: { readAt: new Date() } });
  }
}
