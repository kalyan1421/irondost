import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Transform } from 'class-transformer';
import {
  ArrayMaxSize,
  IsArray,
  IsBoolean,
  IsEnum,
  IsInt,
  IsOptional,
  IsString,
  IsUUID,
  Max,
  MaxLength,
  Min,
  MinLength,
} from 'class-validator';
import { PageQueryDto } from '../common/pagination.js';
import { IssueCategory, IssueStatus } from '../generated/prisma/enums.js';

export class CreateIssueDto {
  @ApiProperty({ enum: IssueCategory, enumName: 'IssueCategory' }) @IsEnum(IssueCategory) category!: IssueCategory;
  @ApiProperty()
  @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value))
  @IsString()
  @MinLength(1)
  @MaxLength(2000)
  description!: string;
  @ApiPropertyOptional({ type: [String], maxItems: 5 })
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(5)
  @IsString({ each: true })
  @MaxLength(2048, { each: true })
  photoUrls?: string[];
}
export class IssueMessageBodyDto {
  @ApiProperty()
  @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value))
  @IsString()
  @MinLength(1)
  @MaxLength(2000)
  body!: string;
}
export class UpdateIssueDto {
  @ApiPropertyOptional({ enum: IssueStatus, enumName: 'IssueStatus' })
  @IsOptional()
  @IsEnum(IssueStatus)
  status?: IssueStatus;
  @ApiPropertyOptional({ nullable: true, type: String }) @IsOptional() @IsUUID() handledById?: string | null;
  @ApiPropertyOptional() @IsOptional() @IsString() @MaxLength(2000) resolutionNote?: string;
  @ApiPropertyOptional({
    nullable: true,
    type: Number,
    description: 'Agreed remedy in paise, with a RESOLVED or REJECTED status. 0 means no money. null clears it.',
  })
  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(10_000_000)
  compensationPaise?: number | null;
  @ApiPropertyOptional({
    nullable: true,
    type: String,
    description: 'A refund made on this order that pays the remedy. null unlinks it.',
  })
  @IsOptional()
  @IsUUID()
  refundId?: string | null;
}
export class IssuesQuery extends PageQueryDto {
  @ApiPropertyOptional({ enum: IssueStatus, enumName: 'IssueStatus' })
  @IsOptional()
  @IsEnum(IssueStatus)
  status?: IssueStatus;
  @ApiPropertyOptional() @IsOptional() @IsUUID() orderId?: string;
  @ApiPropertyOptional() @IsOptional() @IsUUID() handledById?: string;
  @ApiPropertyOptional() @IsOptional() @IsString() @MaxLength(60) search?: string;
  @ApiPropertyOptional()
  @IsOptional()
  @Transform(({ value }) => value === true || value === 'true')
  @IsBoolean()
  overdue?: boolean;
}
export class IssueMessageDto {
  @ApiProperty() id!: string;
  @ApiProperty() fromStaff!: boolean;
  @ApiProperty() body!: string;
  @ApiProperty() createdAt!: Date;
}
export class IssueDto {
  @ApiProperty() id!: string;
  @ApiProperty() orderId!: string;
  @ApiProperty() orderNumber!: string;
  @ApiProperty({ enum: IssueCategory, enumName: 'IssueCategory' }) category!: IssueCategory;
  @ApiProperty({ enum: IssueStatus, enumName: 'IssueStatus' }) status!: IssueStatus;
  @ApiProperty() description!: string;
  @ApiProperty({ type: [String] }) photoUrls!: string[];
  @ApiProperty({ nullable: true, type: Date }) firstResponseDueAt!: Date | null;
  @ApiProperty({ nullable: true, type: Date }) acknowledgedAt!: Date | null;
  @ApiProperty({ nullable: true, type: Date }) resolvedAt!: Date | null;
  @ApiProperty({ nullable: true, type: String }) resolutionNote!: string | null;
  @ApiProperty({ nullable: true, type: Number, description: 'Agreed remedy in paise; null until one is recorded.' })
  compensationPaise!: number | null;
  @ApiPropertyOptional({ nullable: true, type: String }) handledById?: string | null;
  @ApiPropertyOptional({ nullable: true, type: String, description: 'Staff only.' }) refundId?: string | null;
  @ApiProperty() createdAt!: Date;
  @ApiProperty() updatedAt!: Date;
  @ApiProperty({ type: [IssueMessageDto] }) messages!: IssueMessageDto[];
}
export class IssuePageDto {
  @ApiProperty({ type: [IssueDto] }) items!: IssueDto[];
  @ApiProperty() page!: number;
  @ApiProperty() pageSize!: number;
  @ApiProperty() total!: number;
}
